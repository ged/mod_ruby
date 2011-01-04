#!/usr/bin/env ruby
# encoding: utf-8

require 'uri'
require 'net/http'

require 'spec/lib/constants'
require 'spec/lib/helpers'
require 'spec/lib/matchers'

# Matcher for various aspects of an HTTP response
class Apache::SpecMatchers::ResponseMatcher

	### Create a new matcher that expects a +status_code+ response (e.g., 200, 404, etc.)
	def initialize( status_code )
		@expected_code       = status_code
		@expected_headers    = []
		@negated_headers	 = []
		@expected_bodies     = []
		@negated_bodies      = []
		@failure_description = nil
		@agent               = nil
	end


	attr_accessor :agent, :failure_description


	### Returns true if the status of the response negotiated by the +agent+ matches 
	### the expected one.
	def matches?( agent )
		self.agent = agent

		return true if self.check_status_match( agent.response ) &&
			self.check_header_matches( agent.response ) &&
			self.check_header_negations( agent.response ) &&
			self.check_body_matches( agent.response ) &&
			self.check_body_negations( agent.response )
		return false
	end


	### Chainable response header matcher.
	def and_header( header, value )
		@expected_headers << [ header, value ]
		return self
	end
	alias_method :with_header, :and_header


	### Chainable negated header matcher.
	def not_header( header, value=nil )
		@negated_headers << [ header, value ]
		return self
	end
	alias_method :without_header, :not_header


	### Chainable response body matcher.
	def and_body( content )
		@expected_bodies << content
		return self
	end
	alias_method :with_body, :and_body


	### Chainable negated response body matcher.
	def not_body( content )
		@negated_bodies << content
		return self
	end
	alias_method :without_body, :not_body


	### Returns +true+ if the status of the specified +response+ is the same as
	### the expected +status_code+.
	def check_status_match( response )
		unless response.code.to_i == @expected_code.to_i
			self.failure_description = "be a %s response" %
				[ STATUS_NAMES[@expected_code.to_i] ]
			return false
		end

		return true
	end


	### Check the headers of the +response+ against any expected header values.
	def check_header_matches( response )
		@expected_headers.each do |name, expected_value|
			unless response.header.key?( name )
				self.failure_description = "have a %p header" % [ name ]
				break false
			end

			if expected_value.is_a?( Regexp )
				unless response.header[ name ] =~ expected_value
					self.failure_description = "have a %p header matching %p" %
						[ name, expected_value ]
					break false
				end

			else
				unless response.header[ name ] == expected_value.to_s
					self.failure_description = "have a %p header equal to %p" %
						[ name, expected_value ]
						break false
				end

			end
		end
	end


	### Check the headers of the +response+ for the presense of unwanted headers.
	def check_header_negations( response )
		@negated_headers.each do |name, unwanted_value|
			if unwanted_value.nil? && response.header.key?( name )
				self.failure_description = "not have a %p header" % [ name ]
				break false
			end

			if unwanted_value.is_a?( Regexp )
				if response.header[ name ] =~ unwanted_value
					self.failure_description = "not have a %p header matching %p" %
						[ name, unwanted_value ]
					break false
				end

			else
				if response.header[ name ] == unwanted_value.to_s
					self.failure_description = "not have a %p header equal to %p" %
						[ name, unwanted_value ]
					break false
				end
			end
		end
	end


	### Check the body of the specified +response+ against the expected body matches.
	def check_body_matches( response )
		@expected_bodies.each do |pattern|
			unless pattern_matches_response_body?( pattern, response )
				self.failure_description = describe_body_match_failure( pattern, response )
				return false
			end
		end

		return true
	end


	### Check the body of the specified +response+ against the expected body matches.
	def check_body_negations( response )
		@negated_bodies.each do |pattern|
			if pattern_matches_response_body?( pattern, response )
				self.failure_description = describe_body_match_failure( pattern, response, true )
				return false
			end
		end

		return true
	end


	### Look for the given +pattern+ in +response_body+, returning +true+ if the
	### +pattern+ is found. The +pattern+ can be either a Regexp (pattern match), 
	### or a String (exact match).
	def pattern_matches_response_body?( pattern, response )
		return case pattern
		when ''
			response.body.nil? || response.body == ''
		when Regexp
			response.body =~ pattern
		when String
			response.body.strip == pattern.strip
		else
			raise "don't know how to match the response body to %p" % [ pattern ]
		end
	end


	### Build a failure description for the specified body-match +pattern+ and return
	### it. If +negated+ is true, return the inverse of the message.
	def describe_body_match_failure( pattern, response, negated=false )
		desc = negated ? 'not ' : ''
		case pattern
		when ''
			desc << "have an empty body"
		when Regexp
			desc << "have a body that matches:\n\n  %p\n\n" % [ pattern ]
			desc << "but it was:\n\n  %s\n\n" % [ response.body.dump ]
		when String
			desc << "have a body that equals:\n\n  %s" % [ pattern.dump ]
			desc << " (%s)" % [ pattern.encoding ] if pattern.respond_to?( :encoding )
			desc << "\n\n"
			desc << "but it was:\n\n  %s" % [ response.body.dump ]
			desc << " (%s)" % [ response.body.encoding ] if response.body.respond_to?( :encoding )
			desc << "\n\n"
		else
			raise "don't know how to describe " % [ pattern ]
		end

		return desc.encode( 'utf-8' )
	end


	### Build a failure message for the matching case.
	def failure_message_for_should
		return "expected the response to %s. Request/response:\n\n%s\n%s" % [
			self.failure_description,
			self.dump_request_object( self.agent.request ),
			self.dump_response_object( self.agent.response )
		]
	end


	### Build a failure message for the negative matching case.
	def failure_message_for_should_not
		return "Expected the response not to %s, but it did." % [
			STATUS_NAMES[ @expected_code.to_i ]
		]
	end


	#########
	protected
	#########

	### Return the request object as a string suitable for debugging
	def dump_request_object( request )
		buf = "-- Request -----\n"
		buf << "#{request.method} #{request.path} HTTP/#{Net::HTTP::HTTPVersion}\n"
		request.each_capitalized do |k,v|
			buf << "#{k}: #{v}\n"
		end
		buf << "\n"
		buf << request.body.encode( 'utf-8' ) if
			request.request_body_permitted?

		return buf
	end


	### Return the response object as a string suitable for debugging
	def dump_response_object( response )
		buf = "-- Response -----\n"
		buf << "#{response.code} #{response.message}\n"
		response.each_capitalized do |k,v|
			buf << "#{k}: #{v}\n"
		end
		buf << "\n"

		return buf
	end

end # class ResponseMatcher


