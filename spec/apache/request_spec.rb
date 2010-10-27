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
				and_body( /Type: Apache::Table/ ).
				and_body( /"bar"=>\["High Five Bar"\]/ ).
				and_body( /"time"=>\["20:15"\]/ )
	end


end

# vim: set nosta noet ts=4 sw=4:
