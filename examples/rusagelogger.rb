#!/usr/bin/env ruby -wKU

require 'singleton'
require 'rusage'

class RusageLogger
    include Singleton

	### Set up the handler's instance variables.
	def initialize
		@counter = 0
		@initial_usage = nil
	end


	######
	public
	######

    ### Set the initial usage right after the request is read.
    def post_read_request( request )
		# Only count the main request, not subrequests
		if request.main?
			@counter += 1
        	@initial_usage = Process.rusage
			request.server.log_info "Initial rusage (%s): %p" % [ request.uri, @initial_usage ]
		end
        return Apache::DECLINED
    end

    ### Handle content, probably using the database connection.
    def log_transaction( request )
		if @initial_usage
			usage = Process.rusage
			maxrss_delta = usage.maxrss - @initial_usage.maxrss
			utime_delta = usage.utime - @initial_usage.utime
			stime_delta = usage.stime - @initial_usage.stime

			logmsg = "Usage deltas for child %d (after %d request/s): rss: %0.1fKb, utime: %0.3f, stime: %0.3f" %
				[ Process.pid, @counter, maxrss_delta/1024.0, utime_delta, stime_delta ]
	        request.server.log_info( logmsg )
		end

        return Apache::DECLINED
    end

end

