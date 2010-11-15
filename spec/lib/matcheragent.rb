#!/usr/bin/env ruby

require 'uri'
require 'net/http'

require 'spec/lib/constants'
require 'spec/lib/helpers'
require 'spec/lib/matchers'

# An object for building up HTTP requests.
class Apache::SpecMatchers::MatcherAgent
	include Apache::TestConstants,
	        Apache::SpecHelpers

	### Create a new Request wrapper around an HTTP request object.
	def initialize( host, port, path, verb=:get, headers={} )
		@host     = host
		@port     = port
		@path     = path

		@verb     = verb
		@headers  = headers || {}
		@body     = nil
		@params   = {}
		@request  = nil
		@response = nil

		@debug_output = ''
	end

	attr_accessor :host, :port, :path, :verb, :headers, :body, :params, :request
	attr_reader :debug_output


	### Fetch the response and delegate the expection to it.
	def response
		unless @response
			trace "Sending a %s to the server..." % [ self.verb ]
			self.request = self.send( "make_%s_request" % [self.verb.to_s] )

			http = Net::HTTP.new( self.host, self.port )
			http.set_debug_output( @debug_output )
			http.start do |http|
				trace "  connected; sending request..."
				@response = http.request( self.request, self.body )

				# Net::HTTP doesn't do anything with encoding headers 
				# (http://redmine.ruby-lang.org/issues/show/2567), but since we
				# control both ends, go ahead and force encoding if there's an
				# encoding header.
				if defined?( Encoding ) && @response.key?('Content-encoding') && @response.body
					enc = @response['Content-encoding']
					@response.body.force_encoding( enc )
				end

				trace "  got response: %p" % [ @response ]
			end
		end

		return @response
	end


	### Add an entity body to a POST or PUT request.
	def with_body( data )
		@body = data
		return self
	end


	### Add form parameters to a GET or POST request.
	def with_form_parameters( params )
		trace "  setting form parameters to: %p" % [ params ]
		@params = params
		return self
	end


	#########
	protected
	#########

	### Make a Net::HTTP::Get request with the configured path, headers, params, etc. and
	### return it.
	def make_get_request
		path = self.path
		path += '?' + self.get_query_args unless self.params.empty?
		return Net::HTTP::Get.new( path, self.headers )
	end


	### Make a Net::HTTP::Head request 
	def make_head_request
		path = self.path
		path += '?' + self.get_query_args unless self.params.empty?
		return Net::HTTP::Head.new( path, self.headers )
	end


	### Make a Net::HTTP::Post request with the configured path, headers, params, etc. and
	### return it.
	def make_post_request
		request = Net::HTTP::Post.new( self.path, self.headers )
		request.set_form_data( self.params ) unless self.params.empty?
		return request
	end


	### Make a Net::HTTP::Put request with the configured path, headers, etc. and
	### return it.
	def make_put_request
		return Net::HTTP::Put.new( self.path, self.headers )
	end


	### Make a Net::HTTP::Delete request with the configured path, headers, etc. and
	### return it.
	def make_delete_request
		return Net::HTTP::Head.new( self.path, self.headers )
	end


	### Make a Net::HTTP::Options request with the configured path, headers, etc. and
	### return it.
	def make_options_request
		return Net::HTTP::Options.new( self.path, self.headers )
	end


	### Make a query arguments String out of the requested form params.
	def get_query_args
		return '' if self.params.empty?

		trace "  encoding query args from param hash: %p" % [ params ]
		if URI.respond_to?( :encode_www_form )
			rval = URI.encode_www_form( self.params )
		else
			rval = self.params.collect do |k,v|
				k = URI.escape( k.to_s )
				if v.is_a?( Array )
					v.collect {|val| "%s=%s" % [k, URI.escape(val.to_s)] }
				else
					"%s=%s" % [ k, URI.escape(v.to_s) ]
				end
			end.flatten.compact.join( '&' )
		end

		trace "    query args: %p" % [ rval ]
		return rval
	end


end # class MatcherAgent


