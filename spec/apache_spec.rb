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

require 'spec'
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

		# Set up the handler
		@handler = RubyHandler( '/', <<-"END_CODE" )
			def handler( req )
				case req.uri
				when '/exit'
					req.server.log_error "In spec."
					exit Apache::BAD_REQUEST

				when '/server_version'
					req.headers_out['Content-type'] = 'text/plain'
					req.puts( Apache.server_version )

				when '/add_version_component'
					req.headers_out['Content-type'] = 'text/plain'
					Apache.add_version_component( 'sillycomponent' )
					req.puts( Apache.server_version )

				when '/server_built'
					req.headers_out['Content-type'] = 'text/plain'
					req.puts( Apache.server_built )

				when '/request'
					req.headers_out['Content-type'] = 'text/plain'
					req.puts( Apache.request.inspect )

				when '/unescape_url'
					req.headers_out['Content-type'] = 'text/plain'
					req.puts( Apache.unescape_url("make%20'em%20pay") )

				when '/chdir_file'
					Apache.chdir_file( __FILE__ )
					req.headers_out['Content-type'] = 'text/plain'
					req.puts( Dir.pwd )

				when '/server_root'
					req.headers_out['Content-type'] = 'text/plain'
					req.puts( Apache.server_root )

				else
					req.server.log_error "Unexpected uri %p" % [ req.path_info ]
					exit Apache::SERVER_ERROR
				end

				return Apache::OK
			end
		END_CODE

		setup_logging( :debug )
		@server_info = setup_testing_apache( "Apache module", @handler )
	end

	after( :all ) do
		teardown_testing_apache()
		reset_logging()
	end


	# exit
	it "overrides Kernel::exit to allow fast status return from handlers" do
		requesting( '/exit' ).should respond_with_status( BAD_REQUEST )
	end


	# Apache::server_version
	it "knows what the server version it's running under is" do
		requesting( '/server_version' ).should respond_with( HTTP_OK, %r{Apache/\d+\.\d+\.\d+} )
	end

	# Apache::add_version_component
	it "allows the addition of new components to the version string" do
		pending "not implemented in Apache 2" if @apache_version >= vvec( '2.0.0' )
		requesting( '/add_version_component' ).should respond_with( HTTP_OK, /sillycomponent/ )
	end

	# Apache::server_built
	it "knows the build details of the server it's running under" do
		requesting( '/server_built' ).should respond_with( HTTP_OK, /\w{3} \d{1,2} \d{4} \d+:\d\d:\d\d/ )
	end

	# Apache::request
	it "knows what the current request object is for the server it's running under" do
		requesting( '/request' ).should respond_with( HTTP_OK, /#<Apache::Request:0x[[:xdigit:]]+>/ )
	end

	# Apache::unescape_url
	it "can unescape URLs" do
		requesting( '/unescape_url' ).should respond_with( HTTP_OK, "make 'em pay" )
	end

	# Apache::chdir_file
	it "can change the working directory of the current server to the directory a file lives in" do
		requesting( '/chdir_file' ).should respond_with( HTTP_OK, Apache::SpecHelpers::TEST_DATADIR.to_s )
	end

	# Apache::server_root
	it "knows what the server root of the server it's running under is" do
		requesting( '/server_root' ).should respond_with( HTTP_OK, Apache::SpecHelpers::BASEDIR.to_s )
	end

end

# vim: set nosta noet ts=4 sw=4:
