#!/usr/bin/env ruby -w

#
# Not so much an experiment as documentation-generator: Shows the stages of a
# request which call it, along with the method being called.
#
# Usage:
#
#   RubyRequire stagelogger
#   
#   RubyChildInitHandler       StageLogger.instance
#   RubyPostReadRequestHandler StageLogger.instance
#   RubyTransHandler           StageLogger.instance  
#   
#   <Location /stages>
#       RubyHandler                StageLogger.instance
#   	RubyInitHandler			   StageLogger.instance
#   	RubyHeaderParserHandler	   StageLogger.instance
#   	RubyAccessHandler		   StageLogger.instance
#   	RubyAuthenHandler		   StageLogger.instance
#   	RubyAuthzHandler		   StageLogger.instance
#   	RubyTypeHandler			   StageLogger.instance
#   	RubyFixupHandler		   StageLogger.instance
#   	RubyLogHandler			   StageLogger.instance
#   	RubyErrorLogHandler		   StageLogger.instance
#   	RubyCleanupHandler         StageLogger.instance
#   </Location>
#

require 'singleton'

class StageLogger
	include Singleton

	MethodMap = {
		:child_init		   => 'RubyChildInitHandler',
		:post_read_request => 'RubyPostReadRequestHandler',
		:translate_uri	   => 'RubyTransHandler',
		:init			   => 'RubyInitHandler',
		:header_parse	   => 'RubyHeaderParserHandler',
		:check_access	   => 'RubyAccessHandler',
		:authorize		   => 'RubyAuthzHandler',
		:authenticate	   => 'RubyAuthenHandler',
		:find_types		   => 'RubyTypeHandler',
		:fixup			   => 'RubyFixupHandler',
		:handler		   => 'RubyContent Handler',
		:log_transaction   => 'RubyLogHandler',
		:log_error         => 'RubyErrorLogHandler',
		:cleanup		   => 'RubyCleanupHandler',
	}

	### Handle any of the methods that mod_ruby handlers call, logging each of them
	### with the method that was called, the handler, and the arguments it was called 
	### with.
	def method_missing( sym, req, *args )
		if MethodMap.key?( sym )
			stage = MethodMap[ sym ]
			req.server.log_error "StageLogger {%d}>> in %s %s(%p, %p)" % [
				Process.pid,
				stage,
				sym,
				req,
				args
			  ]
		else
			req.server.log_error "StageLogger {%d}>> unknown handler: %s(%p, %p)" % [
				Process.pid,
				sym,
				req,
				args
			  ]
		end

		return Apache::OK
	end


	### Handle the RubyAuthenHandler specially, as it requires we set some authentication
	### stuff and then decline in order for the RubyAuthzHandler to be called.
	def authenticate( req )
		req.server.log_error "StageLogger {%d}>> in RubyAuthenHandler authenticate(%p)" % 
			[ Process.pid, req ]

		req.auth_type = 'Basic'
		req.auth_name = 'StageLogger'
		req.user = 'stagelogger'

		return Apache::OK
	end


	### Handle the content handler differently so requests don't 404.
	def handler( req )
		req.content_type = "text/plain"
		req.puts "In content handler."
		req.server.log_error "StageLogger {%d}>> RubyHandler: handler(%p)" % [
			Process.pid,
			req
		  ]

		return Apache::OK
	end
end


# Results:

# [...] in ChildInitHandler child_init(#<Apache::Request:0x1033313d8>, [])
# [...] in PostReadRequestHandler post_read_request(#<Apache::Request:0x103330a00>, [])
# [...] in TransHandler translate_uri(#<Apache::Request:0x103330a00>, [])
# [...] in AccessHandler check_access(#<Apache::Request:0x103330a00>, [])
# [...] in RubyAuthenHandler authenticate(#<Apache::Request:0x103330a00>)
# [...] in AuthzHandler authorize(#<Apache::Request:0x103330a00>, [])
# [...] in TypeHandler find_types(#<Apache::Request:0x103330a00>, [])
# [...] in FixupHandler fixup(#<Apache::Request:0x103330a00>, [])
# [...] RubyHandler: handler(#<Apache::Request:0x103330a00>)
# [...] in LogHandler log_transaction(#<Apache::Request:0x103330a00>, [])
# [...] in CleanupHandler cleanup(#<Apache::Request:0x10332bff0>, [])
