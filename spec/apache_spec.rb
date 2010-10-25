#!/usr/bin/env ruby
# encoding: utf-8

BEGIN {
	require 'rbconfig'
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

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

describe Apache do
	include Apache::SpecHelpers,
	        Apache::SpecMatchers


	before( :all ) do
		@apache_version = get_apache_version()
		setup_logging( :debug )
		setup_testing_apache( "Apache module functions" )
	end

	after( :all ) do
		teardown_testing_apache()
	end


	# exit
	it "overrides Kernel::exit to allow fast status return from handlers" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.server.log_error "In spec."
				exit Apache::BAD_REQUEST
			END_CODE
		end

		requesting( '/' ).should respond_with( BAD_REQUEST )
	end


	# Apache::server_version
	it "knows what the server version it's running under is" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( Apache.server_version )
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( %r{Apache/\d+\.\d+\.\d+} )
	end

	# Apache::add_version_component
	it "allows the addition of new components to the version string" do
		pending "not implemented in Apache 2" if @apache_version >= vvec( '2.0.0' )
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.headers_out['Content-type'] = 'text/plain'
				Apache.add_version_component( 'sillycomponent' )
				req.puts( Apache.server_version )
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( /sillycomponent/ )
	end

	# Apache::server_built
	it "knows the build details of the server it's running under" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( Apache.server_built )
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( /\w{3} \d{1,2} \d{4} \d+:\d\d:\d\d/ )
	end

	# Apache::request
	it "knows what the current request object is for the server it's running under" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( Apache.request.inspect )
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( /#<Apache::Request:0x[[:xdigit:]]+>/ )
	end

	# Apache::unescape_url
	it "can unescape URLs" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( Apache.unescape_url("make%20'em%20pay") )
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( "make 'em pay" )
	end

	# Apache::chdir_file
	it "can change the working directory of the current server to the directory a file lives in" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				Apache.chdir_file( __FILE__ )
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( Dir.pwd )
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( Apache::SpecHelpers::TEST_DATADIR.to_s )
	end

	# Apache::server_root
	it "knows what the server root of the server it's running under is" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( Apache.server_root )
				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_body( Apache::SpecHelpers::BASEDIR.to_s )
	end

end

# vim: set nosta noet ts=4 sw=4:
