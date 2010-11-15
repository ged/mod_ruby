#!/usr/bin/env ruby
# encoding: utf-8

BEGIN {
	require 'rbconfig'
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"
	extdir = libdir + Config::CONFIG['sitearch']

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
	$LOAD_PATH.unshift( extdir ) unless $LOAD_PATH.include?( extdir )
}

require 'rspec'

require 'spec/lib/constants'
require 'spec/lib/helpers'
require 'spec/lib/matchers'


include Apache::TestConstants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Apache::Request do

	before( :all ) do
		@apache_version = get_apache_version()
		setup_logging( :debug )
		@server_info = setup_testing_apache( "Apache::Request class" )
	end

	around( :each ) {|example| capture_log(&example) }

	after( :all ) do
		teardown_testing_apache()
	end


	it "allows appending to the response body via the append operator" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req << "I'll be in my bunk."
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).and_body( /I'll be in my bunk\./ )
	end

	it "provides a method for adding the CGI variables to the environment of subprocesses" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.add_cgi_vars
				vars = req.subprocess_env.collect {|k,v| "%s = %s" % [k,v] }
				req.content_type = 'text/plain'
				req.puts( vars.inspect )
				return Apache::OK
			END_CODE
		end

		# GATEWAY_INTERFACE = 'CGI/1.1'
		# SERVER_PROTOCOL   = 'HTTP/1.1'
		# REQUEST_METHOD    = 'GET'
		# QUERY_STRING      = ''
		# REQUEST_URI       = '/'
		# SCRIPT_NAME       = ''
		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( %r{GATEWAY_INTERFACE = CGI/1\.1} ).
			and_body( %r{SERVER_PROTOCOL = HTTP/1\.1} ).
			and_body( %r{REQUEST_METHOD = GET} )
	end

	it "can add other common CGI environment variables to its subprocesses" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.add_common_vars
				vars = req.subprocess_env.each {|k,v| req << k << ' = ' << v.dump << "\n" }
				req.content_type = 'text/plain'
				return Apache::OK
			END_CODE
		end

		# HTTP_ACCEPT = "*/*"
		# HTTP_HOST = "localhost:63093"
		# PATH = "[...]"
		# SERVER_SIGNATURE = ""
		# SERVER_SOFTWARE = "Apache/2.2.15 (Unix) mod_ruby/1.3.0"
		# SERVER_NAME = "localhost"
		# SERVER_ADDR = "127.0.0.1"
		# SERVER_PORT = "63093"
		# REMOTE_ADDR = "127.0.0.1"
		# DOCUMENT_ROOT = "/tmp"
		# SERVER_ADMIN = "[no address given]"
		# SCRIPT_FILENAME = "/tmp/"
		# REMOTE_PORT = "56835"
		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( %r{SERVER_SOFTWARE = "Apache} ).
			and_body( %r{SERVER_NAME = "localhost"} ).
			and_body( %r{HTTP_ACCEPT = "\*/\*"} )
	end


	it "can return all request parameters as a Hash" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				params = req.all_params
				req.puts "Type: \#{params.class.name}" 
				req.puts( params.inspect )
				req.content_type = 'text/plain'
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).with_form_parameters( :time => '20:15', :bar => "High Five Bar" ).
			should respond_with( HTTP_OK ).
				and_body( /Type: Hash/ ).
				and_body( /"bar"=>\["High Five Bar"\]/ ).
				and_body( /"time"=>\["20:15"\]/ )
	end

	it "returns an empty Hash from #all_params if there are no request parameters" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				params = req.all_params
				req.puts "Type: \#{params.class.name}" 
				req.puts( params.inspect )
				req.content_type = 'text/plain'
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).with_form_parameters( :time => '20:15', :bar => "High Five Bar" ).
			should respond_with( HTTP_OK ).
				and_body( /Type: Hash/ ).
				and_body( /"bar"=>\["High Five Bar"\]/ ).
				and_body( /"time"=>\["20:15"\]/ )
	end


	it "knows which directory options have been enabled for the requested URI" do
		handler = <<-END_CODE
			unless (req.allow_options & (Apache::OPT_EXECCGI|Apache::OPT_INDEXES)).nonzero?
			    req.log_reason( "ExecCGI and/or Indexes are off in this directory",
			           req.filename )
			    return Apache::FORBIDDEN
			end
			req.server.log_debug "Opts are: %d" % [ req.allow_options ]
			req.content_type = 'text/plain'
			req.puts "Allowed?"
			return Apache::OK
		END_CODE

		config = <<-END_CONFIG
			Options None
		END_CONFIG

		install_handlers do
			rubyhandler( '/secret_subdir', handler, config )
		end

		requesting( '/secret_subdir' ).should respond_with( FORBIDDEN )
	end


	it "knows which HTTP methods are allowed for the requested URI" do
		pending "figuring out why .allowed isn't working" do
			handler = <<-END_CODE
				unless req.method_number == Apache::M_POST
					req.allowed = req.allowed | (1<<Apache::M_POST)
					req.server.log_debug "allowed bitmask is: %08b" % [ req.allowed ]
					return Apache::DECLINED
				end
				return Apache::DECLINED
			END_CODE

			install_handlers do
				rubyhandler( '/', handler )
			end

			requesting( '/' ).should respond_with( HTTP_METHOD_NOT_ALLOWED ).
				and_header( 'Allow', /POST/ ).
				and_header( 'Allow', /TRACE/ )
		end
	end


	it "knows what the query string is" do
		handler = <<-END_CODE
			req.puts( req.args )
			req.content_type = 'text/plain'
			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/?purple=monkey&finger' ).should respond_with( HTTP_OK ).
			and_body( 'purple=monkey&finger' )
	end


	it "can respond to an 0.9 \"simple\" request" do
		handler = <<-END_CODE
			req.assbackwards = true
			req.puts "HTTP/1.0 200 Yep",
				"Content-type: text/plain",
				"Connection: close",
				"X-Funky-Stuff: yes",
				'',
				"Oh my god that's the funky s**t!"
			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( %{Oh my god that's the funky s**t!} ).
			and_header( 'X-Funky-Stuff', 'yes' ).
			not_header( 'Content-length' )
	end


	it "can store arbitrary attributes in the request" do
		fixup_handler = <<-END_CODE
			req.attributes[:monkeyfinger] = :yes
			return Apache::OK
		END_CODE
		content_handler = <<-END_CODE
			req.puts( req.attributes.inspect )
			req.content_type = 'text/plain'
			return Apache::OK
		END_CODE

		install_handlers do
			fixuphandler( '/', fixup_handler )
			rubyhandler( '/', content_handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( /\{:monkeyfinger=>:yes\}/ )
	end


	it "can get and set the request's authname" do
		handler = <<-END_CODE
			req.auth_name += " Employees"
			req.note_auth_failure
			return Apache::HTTP_UNAUTHORIZED
		END_CODE

		config = <<-END_CONFIG
			AuthType basic
			AuthName "Sekrit Pickle Factory"
		END_CONFIG

		install_handlers do
			rubyhandler( '/pickle_info', handler, config )
		end

		requesting( '/pickle_info' ).should respond_with( HTTP_UNAUTHORIZED ).
			and_header( 'WWW-Authenticate', /Basic.*pickle factory employees/i )
	end


	it "can get the request's authtype" do
		handler = <<-END_CODE
			req.content_type = 'text/plain'
			req.puts( req.auth_type )

			return Apache::OK
		END_CODE

		config = <<-END_CONFIG
			AuthType basic
			AuthName "Sekrit Pickle Factory"
		END_CONFIG

		install_handlers do
			rubyhandler( '/pickle_info', handler, config )
		end

		requesting( '/pickle_info' ).should respond_with( HTTP_OK ).
			and_body( /basic/ )
	end


	it "can set the request's authtype" do
		handler = <<-END_CODE
			# Switch to basic auth from localhost so we can see the credentials. Contrived,
			# I know. :)
			if req.connection.remote_ip == '127.0.0.1'
				req.auth_type = 'Basic'
			end
			req.note_auth_failure
			return Apache::HTTP_UNAUTHORIZED
		END_CODE

		config = <<-END_CONFIG
			AuthType digest
			AuthName "Sekrit Pickle Factory"
		END_CONFIG

		install_handlers do
			rubyhandler( '/pickle_info', handler, config )
		end

		requesting( '/pickle_info' ).should respond_with( HTTP_UNAUTHORIZED ).
			and_header( 'WWW-Authenticate', /Basic realm="Sekrit Pickle Factory"/ )
	end


	it "knows how many bytes have already been sent to the client" do
		initial_body = "the initial body: "

		handler = <<-END_CODE
			req.sync = true
			req.content_type = 'text/plain'
			req.print "#{initial_body}"
			req.puts "%d bytes" % [ req.bytes_sent ]
			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( "#{initial_body}%d bytes" % [initial_body.length] )
	end


	it "knows that cache-control headers are in effect if the response has a Pragma header" do
		handler = <<-END_CODE
			req.headers_out['Pragma'] = 'cow witches'
			req.content_type = 'text/plain'

			if req.cache_resp
				req.puts "Yeah, I said cow witches!"
			else
				req.puts "Awww... I guess I'll be a werewolf."
			end

			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Pragma', 'cow witches' ).
			and_body( /cow witch/ )
	end


	it "knows that cache-control headers are in effect if the response has a Cache-control header" do
		handler = <<-END_CODE
			req.headers_out['Cache-control'] = 'no-transform'
			req.content_type = 'text/plain'

			if req.cache_resp
				req.puts "I have fancy cache directives!"
			else
				req.puts "Oops, no cache directives?"
			end

			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Cache-control', 'no-transform' ).
			and_body( /fancy/ )
	end


	it "provides a convenience function for advising caches not to cache the response" do
		handler = <<-END_CODE
			req.content_type = 'text/plain'
			req.cache_resp = true

			req.puts "Something un-cacheable."

			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Cache-control', 'no-cache' ).
			and_header( 'Pragma', 'no-cache' )
	end


	it "can also reset the cacheability of a response with the same convenience function" do
		handler = <<-END_CODE
			req.headers_out['Cache-control'] = 'no-tranform'
			req.headers_out['Pragma'] = 'no-cache'
			req.content_type = 'text/plain'
			req.cache_resp = false

			req.puts "Something that's cacheable after all."

			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			without_header( 'Cache-control', 'no-cache' ).
			without_header( 'Pragma', 'no-cache' )
	end


	it "can clear the output buffer" do
		handler = <<-END_CODE
			req.sync = false
			req.content_type = 'text/plain'

			req.puts "Something I'll probably regret later."
			req.cancel
			req.puts %{I mean: "You look beautiful in everything you wear."}

			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( /beautiful/ ).
			without_body( /regret/ )
	end


	it "can access the request's connection object" do
		handler = <<-END_CODE
			req.content_type = 'text/plain'
			req.puts( req.connection.inspect )
			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( /Apache::Connection/ )
	end


	it "can build URLs relative to the server and port it's running on" do
		handler = <<-END_CODE
			url = '/a/path/to/redirect/to'
			req.puts( req.construct_url(url) )
			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( "http://localhost:#{LISTEN_PORT}/a/path/to/redirect/to" )
	end


	it "can set the encoding of the response body to a MIME encoding string" do
		handler = <<-END_CODE
			req.content_encoding = 'Shift_JIS'
			body = [82, 117, 98, 121, 130, 205, 138, 121, 130, 181, 130, 
				162, 130, 197, 130, 183, 129, 73].pack( "C*" )
			req.puts( body )
			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		expected_body = [82, 117, 98, 121, 130, 205, 138, 121, 130, 181, 130, 
			162, 130, 197, 130, 183, 129, 73].pack( "C*" )
		expected_body.force_encoding( 'sjis' )

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Content-encoding', 'Shift_JIS' ).
			and_body( expected_body + "\n" )
	end


	it "can set the encoding of the response body to an Encoding", :if => defined?(Encoding) do
		handler = <<-END_CODE
			# These don't get loaded by embedded Ruby? This works in the meantime...
			require 'enc/encdb.so'
			require 'enc/trans/transdb.so'
			
			req.content_encoding = Encoding::UTF_8
			req.puts 'Rubyは楽しいです！'.encode('utf-8')

			return Apache::OK
		END_CODE

		install_handlers do
			rubyhandler( '/', handler )
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Content-encoding', 'UTF-8' ).
			and_body( "Rubyは楽しいです！\n" )
	end

end

# vim: set nosta noet ts=4 sw=4:
