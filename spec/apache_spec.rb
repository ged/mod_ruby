#!/usr/bin/env ruby
# encoding: utf-8

BEGIN {
	require 'rbconfig'
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"
	extdir = libdir + Config::CONFIG['sitearch']

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
	$LOAD_PATH.unshift( extdir ) unless $LOAD_PATH.include?( extdir )
}

require 'spec'
require 'spec/lib/constants'
require 'spec/lib/helpers'


include Apache::TestConstants
include Apache::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Apache do
	include Apache::SpecHelpers

	# Set up the handler
	@handler = Class.new( Apache::SpecHandler ) do

		on '/exit' do |req|
			exit Apache::NOTFOUND
		end

	end


	before( :all ) do
		setup_logging( :debug )
		@server_info = setup_testing_apache( "Apache module tests", @handler )
	end

	after( :all ) do
		reset_logging()
	end


	# exit
	it "overrides Kernel::exit to allow fast status return from handlers" do
		requesting( '/exit' ).should respond_with_status( Apache::NOTFOUND )
	end


	# Apache::server_version
	it "knows what the server version it's running under is"

	# Apache::add_version_component
	it "allows the addition of new components to the version string"

	# Apache::server_built
	it "knows the build details of the server it's running under"

	# Apache::request
	it "knows what the current request object is for the server it's running under"

	# Apache::unescape_url
	it "can unescape URLs"

	# Apache::chdir_file
	it "can change the working directory of the current server to the directory a file lives in"

	# Apache::server_root
	it "knows what the server root of the server it's running under is"

end

# vim: set nosta noet ts=4 sw=4:
