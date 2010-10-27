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

	around( :each ) {|example| capture_log(&example) }

	after( :all ) do
		teardown_testing_apache()
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
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				cookie = Apache::Cookie.new( req, :name => 'session_id' )

				cookie.bake
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( '' )

				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', %r{session_id=(; path=/)?} )
	end


	it "allows a cookie's value to be set to a single String" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				require 'digest/md5'
				data = Time.at(1234567890).strftime('%Y/%m/%d %H:%M:%S') + ':127.0.0.1'
				sess_id = Digest::MD5.hexdigest( data )
				cookie = Apache::Cookie.new( req, :name => 'session_id', :value => sess_id )

				cookie.bake
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( '' )

				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /session_id=ee97f0a63ff684b05856f159549ea3e7/ )
	end

	it "allows a cookie's value to be set to an Array of Strings" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				values = %w{ruby ldap digest authentication dn filter}
				cookie = Apache::Cookie.new( req, :name => 'search_tags', :value => values )

				cookie.bake
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( '' )

				return Apache::OK
			END_CODE
		end

		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /search_tags=ruby&ldap&digest&authentication&dn&filter/ )
	end


	it "can fetch the first value from an Array of cookie values" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				req.server.log_info "In spec."
				
				cookie = req.cookies['search_tags'] or
					raise "No 'search_tags' cookie in the request!"
				req.server.log_debug "  got cookie: %p" % [ cookie ]
				req.puts( cookie.value )
				req.server.log_debug "  wrote the cookie value."

				req.server.log_debug "  done with spec handler. About to return OK."
				return Apache::OK
			END_CODE
		end

		cookie = 'search_tags=' + ARRAY_COOKIE_VALUES.sort.join( '&' )
		requesting( '/', 'Cookie' => cookie ).should respond_with( HTTP_OK ).
			and_body( ARRAY_COOKIE_VALUES.sort.first )
	end

	it "can fetch all of the values from an Array of cookie values" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				cookie = req.cookies['search_tags'] or
					raise "No 'search_tags' cookie in the request!"
				req.puts( cookie.values.join(';') )

				return Apache::OK
			END_CODE
		end

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
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				expires = Time.at( 1234567890 )
				cookie = Apache::Cookie.new( req,
					:name => 'session', :value => "expire me!", :expires => expires )

				cookie.bake
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( '' )

				return Apache::OK
			END_CODE
		end

		expected_timestring = EXPIRES_TIME.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	context "with a handler that accepts a time delta" do

		before( :all ) do
			install_handlers do
				rubyhandler( '/delta_expiration', <<-END_CODE )
					deltastring = req.path_info[ 1..-1 ]
					req.server.log_info( "delta string is: %p" % [deltastring] )
					cookie = Apache::Cookie.new( req,
						:name => 'session', :value => "expire me!", :expires => deltastring )

					cookie.bake
					req.headers_out['Content-type'] = 'text/plain'
					req.puts( '' )

					return Apache::OK
				END_CODE
			end

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

	end


	it "allows a cookie's expiration to be set to an absolute time via a HTTP date string" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				expires = Time.at( 1234567890 )
				cookie = Apache::Cookie.new( req,
					:name => 'session', :value => "expire me!", :expires => expires )

				cookie.bake
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( '' )

				return Apache::OK
			END_CODE
		end

		expected_time = Time.at( 1234567890 )
		expected_timestring = expected_time.gmtime.strftime( HTTP_DATE_FORMAT ).sub( /UTC/, 'GMT' )
		requesting( '/timestring_expiration' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /expires=#{expected_timestring}/ )
	end


	it "supports long cookie values" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				expires = Time.at( 1234567890 )
				cookie = Apache::Cookie.new( req, :name => 'longvalue', :value => 'x' * 4000 )

				cookie.bake
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( '' )

				return Apache::OK
			END_CODE
		end

		requesting( '/long_cookie_value' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /x{4000}/ )
	end


	it "can set and get a cookie object's domain attribute" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				cookie = req.cookies['session'] or
					raise "No 'session' cookie in the request!"
				cookie.domain = 'example.com'
				req.puts( cookie.domain )

				return Apache::OK
			END_CODE
		end

		cookie = 'session=foo;$Path=/fetch_cookie'
		requesting( '/getset_domain', 'Cookie' => cookie ).should respond_with( HTTP_OK ).
			and_body( 'example.com' )
	end


	it "can set the outgoing cookie's domain" do
		install_handlers do
			rubyhandler( '/', <<-END_CODE )
				expires = Time.at( 1234567890 )
				cookie = Apache::Cookie.new( req, :name => 'session', :domain => 'example.com' )

				cookie.bake
				req.headers_out['Content-type'] = 'text/plain'
				req.puts( '' )

				return Apache::OK
			END_CODE
		end

		requesting( '/domain_cookie' ).should respond_with( HTTP_OK ).
			and_header( 'Set-Cookie', /domain=example\.com/ )
	end

end

# vim: set nosta noet ts=4 sw=4:
