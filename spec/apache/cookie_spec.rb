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

	# The HTTP cookie date format
	HTTP_DATE_FORMAT = '%a, %d-%b-%Y %H:%M:%S %Z'

	# The time to use for all non-delta expires headers
	EXPIRES_TIME = Time.at( 1234567890 )

	# Array cookie values (using tags as an example)
	ARRAY_COOKIE_VALUES = %w{ruby ldap digest authentication dn filter}


	before( :all ) do
		@apache_version = get_apache_version()
		setup_logging( :debug )
		@server_info = setup_testing_apache( "Apache::Cookie class" )
	end

	after( :all ) do
		teardown_testing_apache()
		reset_logging()
	end


	# Default (empty) cookie
	it "sends an empty 'Set-Cookie' header if an empty cookie is added" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				cookie = Apache::Cookie.new( req )
				cookie.bake
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( '' )

				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', '' )
	end

	# Name-only cookie
	it "sends a cookie with an empty value if a value-less cookie is added" do
		install_rubyhandler( '/', <<-END_CODE )
			cookie = Apache::Cookie.new( req, :name => 'session_id' )
			cookie.bake
			req.headers_out['Content-type'] = 'text/plain'
			req.puts( '' )

			return Apache::OK
		END_CODE

		requesting( '/nameonly_cookie' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', %r{session_id=(; path=/)?} )
	end

	it "allows a cookie's value to be set to a single String" do
		requesting( '/plain_value_cookie' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /session_id=bc08d2698ccd8087101ffd24535992cf/ )
	end

	it "allows a cookie's value to be set to an Array of Strings" do
		requesting( '/array_cookie' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /search_tags=ruby&ldap&digest&authentication&dn&filter/ )
	end


	it "can fetch the first value from an Array of cookie values" do
		cookie = 'search_tags=' + ARRAY_COOKIE_VALUES.sort.join( '&' )
		requesting( '/fetch_first_value', 'Cookie' => cookie ).should respond_with( HTTP_OK ).
			and_body( ARRAY_COOKIE_VALUES.sort.first )
	end

	it "can fetch all of the values from an Array of cookie values" do
		cookie = 'search_tags=' + ARRAY_COOKIE_VALUES.sort.join( '&' )
		requesting( '/fetch_all_values', 'Cookie' => cookie ).should respond_with( HTTP_OK ).
			and_body( ARRAY_COOKIE_VALUES.sort.join(';') )
	end


	# +30s::                                30 seconds from now 
	# +10m::                                ten minutes from now 
	# +1h::                                 one hour from now 
	# -1d::                                 yesterday (i.e. "ASAP!") 
	# now::                                 immediately 
	# +3M::                                 in three months 
	# +10y::                                in ten years time 
	# Thursday, 25-Apr-1999 00:40:33 GMT::  at the indicated time & date

	it "allows a cookie's expiration to be set to a Time object" do
		expected_timestring = EXPIRES_TIME.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/time_expiration' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	it "allows a cookie's expiration to be set via a time-delta string in seconds" do
		expected_time = Time.now + 30
		expected_timestring = expected_time.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/delta_expiration/+30' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	it "allows a cookie's expiration to be set via a time-delta string in minutes" do
		expected_time = Time.now + 10.minutes
		expected_timestring = expected_time.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/delta_expiration/+10m' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	it "allows a cookie's expiration to be set via a time-delta string in hours" do
		expected_time = Time.now + 1.hour
		expected_timestring = expected_time.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/delta_expiration/+1h' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	it "allows a cookie's expiration to be set via a time-delta string in days" do
		expected_time = Time.now - 1.day
		expected_timestring = expected_time.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/delta_expiration/-1d' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	it "allows a cookie's expiration to be set via a time-delta string in months" do
		expected_time = Time.now + 3.months
		expected_timestring = expected_time.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/delta_expiration/+3M' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	it "allows a cookie's expiration to be set via a time-delta string in years" do
		pending "Expires time is different by a few days; not sure why" do
			expected_time = Time.now + 10.years
			expected_timestring = expected_time.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
			requesting( '/delta_expiration/+10y' ).should respond_with( HTTP_OK ).
				and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
		end
	end


	it "allows a cookie's expiration to be set to the current time via the string 'now'" do
		expected_time = Time.now
		expected_timestring = expected_time.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/delta_expiration/now' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	it "allows a cookie's expiration to be set to an absolute time via a HTTP date string" do
		expected_time = Time.at( 1234567890 )
		expected_timestring = expected_time.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/timestring_expiration' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	it "supports long cookie values" do
		requesting( '/long_cookie_value' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /x{4000}/ )
	end


	it "can set and get a cookie object's domain attribute" do
		cookie = 'session=foo;$Path=/fetch_cookie'
		requesting( '/getset_domain', 'Cookie' => cookie ).should respond_with( HTTP_OK ).
			and_body( 'example.com' )
	end


	it "can set the outgoing cookie's domain" do
		requesting( '/domain_cookie' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /domain=example\.com/ )
	end

end

# vim: set nosta noet ts=4 sw=4:
