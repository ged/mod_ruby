#!/usr/bin/env ruby

require 'pathname'
require 'spec/lib/constants'
require 'spec/lib/helpers'


### Generator for handler configuration files + the handlers themselves.
class Apache::HandlerConfig
	include Apache::TestConstants

	# The directory that contains all the templates for building handler
	# classes and configs
	HANDLER_TEMPLATE_DIR = Pathname( __FILE__ ).dirname.parent + 'data/handlers'


	### Create a new handler configuration, then call the given +block+ in 
	### the context of the new object.
	def initialize( &block )
		@handlers = Hash.new do |h,k|
			h[k] = []
		end
		@handler_counter = 0

		case block.arity
		when -1, 0
			self.instance_eval( &block )
		else
			block.call( self )
		end
	end


	attr_reader :handlers


	### Install a RubyHandler at the specified +url+ with the body of the
	### #handle method containing the specified +code+.
	def rubyhandler( url, code, location_config=nil )
		self.handlers[ :rubyhandler ] << [ url, code, location_config ]
	end


	### Install a RubyFixupHandler at the specified +url+ with the body of the
	### #fixup method containing the specified +code+.
	def fixuphandler( url, code, location_config=nil )
		self.handlers[ :rubyfixuphandler ] << [ url, code, location_config ]
	end


	### Install a RubyAccessHandler at the specified +url+ with the body of the
	### #check_access method containing the specified +code+.
	def accesshandler( url, code, location_config=nil )
		self.handlers[ :rubyaccesshandler ] << [ url, code, location_config ]
	end


	### Install a RubyLogHandler at the specified +url+ with the body of the
	### #log_transaction method containing the specified +code+.
	def loghandler( url, code, location_config=nil )
		self.handlers[ :rubyloghandler ] << [ url, code, location_config ]
	end


	### Write the configured handlers to the CONFIG_INCLUDE_FILE.
	def generate_handlers
		config = self.generate_handler_config
		CONFIG_INCLUDE_FILE.open( 'w', 0644 ) do |fh|
			fh.print( config )
		end
	end


	### Generate the Apache config for any handlers which have been defined 
	### and return it as a String.
	def generate_handler_config
		config = ''
		self.handlers.each do |handlertype, handler_config|
			# $stderr.puts "Writing #{handlertype}s"
			handler_config.each do |args|
				# $stderr.puts "  config: %p" % [ args ]
				config << self.send( "write_#{handlertype}", *args )
			end
		end

		return config
	end


	### Write out the Ruby source for the specified RubyHandler, and return the config
	### that points to it.
	def write_rubyhandler( url, code, location_config=nil )
		@handler_counter += 1
		handlerfile = TEST_DATADIR + "rubyhandler%d.rb" % [ @handler_counter ]
		handlerclass = "TestRubyHandler%d" % [ @handler_counter ]

		handler_template = self.load_handler_template( :rubyhandler )

		handlercode = handler_template.result( binding() )
		handlerfile.open( 'w', 0644 ) do |fh|
			fh.print( handlercode )
		end

		return %{
			RubyRequire #{handlerfile}
			<Location #{url}>
				#{location_config || ''}
				SetHandler ruby-object
				RubyHandler #{handlerclass}
			</Location>
		}.gsub( /^\t{4}/, '' )
	end


	### Write out the Ruby source for the specified RubyFixupHandler, and return the config
	### that points to it.
	def write_rubyfixuphandler( url, code, location_config=nil )
		@handler_counter += 1
		handlerfile = TEST_DATADIR + "rubyfixuphandler%d.rb" % [ @handler_counter ]
		handlerclass = "TestRubyFixupHandler%d" % [ @handler_counter ]

		handler_template = self.load_handler_template( :rubyfixuphandler )

		handlercode = handler_template.result( binding() )
		handlerfile.open( 'w', 0644 ) do |fh|
			fh.print( handlercode )
		end

		return %{
			RubyRequire #{handlerfile}
			<Location #{url}>
				#{location_config || ''}
				RubyFixupHandler #{handlerclass}
			</Location>
		}.gsub( /^\t{4}/, '' )
	end


	### Write out the Ruby source for the specified RubyAccessHandler, and return the config
	### that points to it.
	def write_rubyaccesshandler( url, code, location_config=nil )
		@handler_counter += 1
		handlerfile = TEST_DATADIR + "rubyaccesshandler%d.rb" % [ @handler_counter ]
		handlerclass = "TestRubyAccessHandler%d" % [ @handler_counter ]

		handler_template = self.load_handler_template( :rubyaccesshandler )

		handlercode = handler_template.result( binding() )
		handlerfile.open( 'w', 0644 ) do |fh|
			fh.print( handlercode )
		end

		return %{
			RubyRequire #{handlerfile}
			<Location #{url}>
				#{location_config || ''}
				RubyAccessHandler #{handlerclass}
			</Location>
		}.gsub( /^\t{4}/, '' )
	end


	### Write out the Ruby source for the specified RubyLogHandler, and return the config
	### that points to it.
	def write_rubyloghandler( url, code, location_config=nil )
		@handler_counter += 1
		handlerfile = TEST_DATADIR + "rubyloghandler%d.rb" % [ @handler_counter ]
		handlerclass = "TestRubyLogHandler%d" % [ @handler_counter ]

		handler_template = self.load_handler_template( :rubyloghandler )

		handlercode = handler_template.result( binding() )
		handlerfile.open( 'w', 0644 ) do |fh|
			fh.print( handlercode )
		end

		return %{
			RubyRequire #{handlerfile}
			<Location #{url}>
				#{location_config || ''}
				RubyLogHandler #{handlerclass}
			</Location>
		}.gsub( /^\t{4}/, '' )
	end


	### Load an ERB template for the given +handlertype+ and return it.
	def load_handler_template( handlertype )
		tmplpath = HANDLER_TEMPLATE_DIR + "#{handlertype}_class.erb"
		if Object.const_defined?( :Encoding )
			return ERB.new( tmplpath.read(:encoding => 'UTF-8'), nil, '%<>' )
		else
			return ERB.new( tmplpath.read, nil, '%<>' )
		end
	end

end # class HandlerConfig
