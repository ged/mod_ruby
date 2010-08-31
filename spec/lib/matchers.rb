#!/usr/bin/env ruby

require 'net/http'

require 'spec/lib/constants'
require 'spec/lib/helpers'


module Apache
	module SpecMatchers
		include Apache::SpecHelpers,
		        Apache::TestConstants

		# An object for building up HTTP requests.
		class HTTPAgent

			### Create a new Request wrapper around an HTTP request object.
			def initialize( host, port, path, verb=:get, headers={} )
				@host     = host
				@port     = port
				@path     = path

				@verb     = verb
				@headers  = headers || {}
				@body     = nil
				@request  = nil
				@response = nil

				@debug_output = ''
			end

			attr_accessor :host, :port, :path, :verb, :headers, :body, :request
			attr_reader :debug_output


			### Fetch the response and delegate the expection to it.
			def response
				unless @response
					req_class = Net::HTTP.const_get( self.verb.to_s.capitalize ) or
						raise NameError, "Unknown request verb %p" % [ self.verb ]
					trace "Sending a %p to the server..." % [ req_class ]

					self.request = req_class.new( self.path )
					trace "  request is: %p" % [ self.request ]

					http = Net::HTTP.new( self.host, self.port )
					http.set_debug_output( @debug_output )
					http.start do |http|
						trace "  connected; sending request..."
						@response = http.request( self.request, self.body )
						trace "  got response: %p" % [ @response ]
					end
				end

				return @response
			end

			#######
			private
			#######

			### Output a trace message.
			def trace( *mgs )
				$stderr.puts( msgs.join ) if $VERBOSE
			end

		end # class HTTPAgent


		#
		# HTTP matchers
		#

		# Match response status
		class StatusMatcher

			### Create a new matcher for the given +regexp+
			def initialize( status_code )
				@expected_code       = status_code
				@failure_description = nil
				@agent               = nil
			end


			attr_accessor :agent, :failure_description


			### Returns true if the status of the response negotiated by the +agent+ matches 
			### the expected one.
			def matches?( agent )
				self.agent = agent

				return true if self.check_status_match( agent.response )
				return false
			end


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


			### Build a failure message for the matching case.
			def failure_message_for_should
				return "expected the response to %s but this happened instead:\n\n%s\n%s" % [
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
				buf << request.body if request.request_body_permitted?

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
				buf << response.body if response.class.body_permitted?

				return buf
			end

		end # class StatusMatcher


		### A matcher that matches a status *and* body content.
		class ContentMatcher < StatusMatcher

			#################################################################
			###	I N S T A N C E   M E T H O D S
			#################################################################

			### Create a new ContentMatcher
			def initialize( status_code, content )
				super( status_code )
				@expected_content = content
			end

			### Returns true if the status and content of the response negotiated by the given 
			### +agent+ matches the expected one.
			def matches?( agent )
				return true if super && self.check_body_match( agent.response )
				return false
			end


			### Check the body of the specified +response+ against the @expected_content.
			def check_body_match( response )
				return case @expected_content
				when NilClass
					self.failure_description = "have an empty body"
					response.body.nil?
				when Regexp
					self.failure_description =
						"have a body that matches:\n\n  %p\n\n" % [ @expected_content ]
					response.body =~ @expected_content
				when String
					self.failure_description =
						"have a body that equals:\n\n  %p\n\n" % [ @expected_content ]
					response.body.strip == @expected_content
				else
					raise "don't know how to match the response body to %p" % [ @expected_content ]
				end
			end

		end # class ContentMatcher


		#
		# DSL methods
		#

		### Make a HTTPAgent that will send a GET request for the given +path+ to the current
		### testing instance of Apache. 
		def requesting( path )
			return HTTPAgent.new( 'localhost', LISTEN_PORT, path )
		end


		### Make a HTTPAgent that will send a POST request for the given +path+ to the current
		### testing instance of Apache.
		def posting_to( path )
			return HTTPAgent.new( 'localhost', LISTEN_PORT, path, :post )
		end


		### Create a StatusMatcher that expects a response with the specified +status_code+.
		def respond_with_status( status_code )
			return StatusMatcher.new( status_code )
		end


		### Create a ContentMatcher that expects a response with the specified +status_code+ 
		### and body.
		def respond_with( status_code, body )
			return ContentMatcher.new( status_code, body )
		end

	end # module SpecMatchers
end # module Apache


