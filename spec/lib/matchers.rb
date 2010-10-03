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

					self.request = req_class.new( self.path, self.headers )
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
		class ResponseMatcher

			### Create a new matcher for the given +regexp+
			def initialize( status_code )
				@expected_code       = status_code
				@expected_headers    = []
				@expected_body       = nil
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
					self.check_body_match( agent.response )
				return false
			end


			### Chainable response header matcher.
			def and_header( header, value )
				@expected_headers << [ header, value ]
				return self
			end


			### Chainable response body matcher.
			def and_body( content )
				@expected_body = content
				return self
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


			### Check the body of the specified +response+ against the @expected_body.
			def check_body_match( response )
				return case @expected_body
				when NilClass
					# Don't care what the body is
					return true
				when ''
					self.failure_description = "have an empty body"
					response.body.nil?
				when Regexp
					self.failure_description =
						"have a body that matches:\n\n  %p\n\n" % [ @expected_body ]
					response.body =~ @expected_body
				when String
					self.failure_description =
						"have a body that equals:\n\n  %p\n\n" % [ @expected_body ]
					response.body.strip == @expected_body
				else
					raise "don't know how to match the response body to %p" % [ @expected_body ]
				end
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

		end # class ResponseMatcher


		#
		# DSL methods
		#

		### Make a HTTPAgent that will send a GET request for the given +path+ to the current
		### testing instance of Apache. 
		def requesting( path, headers={} )
			return HTTPAgent.new( 'localhost', LISTEN_PORT, path, :get, headers )
		end


		### Make a HTTPAgent that will send a POST request for the given +path+ to the current
		### testing instance of Apache.
		def posting_to( path, headers={} )
			return HTTPAgent.new( 'localhost', LISTEN_PORT, path, :post, headers )
		end


		### Create a ContentMatcher that expects a response with the specified +status_code+.
		def respond_with( status_code )
			return ResponseMatcher.new( status_code )
		end

	end # module SpecMatchers
end # module Apache


