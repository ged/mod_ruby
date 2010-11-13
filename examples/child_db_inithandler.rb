#!/usr/bin/env ruby -wKU

require 'pg'
require 'singleton'

class ChildDbInitHandler
    include Singleton

    ### Set up a database connection.
    def child_init( request )
        @conn = PGconn.connect( "host=localhost dbname=test" )
        request.server.log_info "Preconnect done: %p" % [ @conn ]
        return Apache::OK
    end

    ### Handle content, probably using the database connection.
    def handler( request )
        request.content_type = 'text/plain'
        request.puts "Database connection is: %p" % [ @conn ]
        return Apache::OK
    end

end

