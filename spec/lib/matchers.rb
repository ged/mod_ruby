#!/usr/bin/env ruby

require 'uri'
require 'net/http'

require 'spec/lib/constants'
require 'spec/lib/helpers'


module Apache
	module SpecMatchers
		include Apache::TestConstants

		require 'spec/lib/matcheragent'
		require 'spec/lib/responsematcher'

		#
		# DSL methods
		#

		### Make a MatcherAgent that will send a GET request for the given +path+ to the current
		### testing instance of Apache. 
		def requesting( path, headers={} )
			return Apache::SpecMatchers::MatcherAgent.new( 'localhost', LISTEN_PORT, path, :get, headers )
		end


		### Make a MatcherAgent that will send a POST request for the given +path+ to the current
		### testing instance of Apache.
		def posting_to( path, headers={} )
			return Apache::SpecMatchers::MatcherAgent.new( 'localhost', LISTEN_PORT, path, :post, headers )
		end


		### Make a MatcherAgent that will send an OPTIONS request for the given +path+ to the current
		### testing instance of Apache.
		def options_for( path, headers={} )
			return Apache::SpecMatchers::MatcherAgent.new( 'localhost', LISTEN_PORT, path, :options, headers )
		end


		### Create a ContentMatcher that expects a response with the specified +status_code+.
		def respond_with( status_code )
			return Apache::SpecMatchers::ResponseMatcher.new( status_code )
		end

	end # module SpecMatchers
end # module Apache


