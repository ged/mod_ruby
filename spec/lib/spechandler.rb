# A base spec handler class

module Apache
	class SpecHandler

		@derivatives = [];
		@uri = nil
		class << self
			attr_accessor :derivatives, :uri
		end

		def self::inherited( subclass )
			@derivatives << subclass
		end

		def self::unhandled_handler_method( handler, *args )
			define_method( handler ) do |req|
				req.server.log_error "Missing handler %p for %p" % [ handler, req.path_info ]
				return Apache::SERVER_ERROR
			end
		end

		unhandled_handler_method( :handler )
		unhandled_handler_method( :translate_uri )
		unhandled_handler_method( :authenticate )
		unhandled_handler_method( :authorize )
		unhandled_handler_method( :check_access )
		unhandled_handler_method( :find_types )
		unhandled_handler_method( :fixup )
		unhandled_handler_method( :log_transaction )
		unhandled_handler_method( :header_parser )
		unhandled_handler_method( :post_read_request )
		unhandled_handler_method( :cleanup )
		unhandled_handler_method( :init )
	end
end

