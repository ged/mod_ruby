#!/usr/bin/env ruby

require 'erb'
require 'pathname'
require 'singleton'
require 'open-uri'
require 'logger'

require 'spec/lib/constants'

$logger = Logger.new( $stderr )
$default_logger = $logger

LOG_LEVELS = {
	:debug => Logger::DEBUG,
	:info  => Logger::INFO,
	:warn  => Logger::WARN,
	:error => Logger::ERROR,
	:fatal => Logger::FATAL,
}

module Apache

	### Generator for handler configuration files + the handlers themselves.
	class HandlerConfig
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
		def rubyhandler( url, code )
			self.handlers[ :rubyhandler ] << [ url, code ]
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
		def write_rubyhandler( url, code )
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
					SetHandler ruby-object
					RubyHandler #{handlerclass}
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


	module SpecHelpers
		include Apache::TestConstants

		# Paths to programs in the PATH (@see #which)
		PROGRAM_PATHS         = {}

		# The number of seconds to wait for processes to spin up and die off
		PROCESS_TIMEOUT       = 15.0

		# How many seconds to wait between process checks when waiting for one to spin up or die off
		PROCESS_WAIT_INTERVAL = 0.25

		# Set some ANSI escape code constants (Shamelessly stolen from Perl's
		# Term::ANSIColor by Russ Allbery <rra@stanford.edu> and Zenin <zenin@best.com>
		ANSI_ATTRIBUTES = {
			'clear'      => 0,
			'reset'      => 0,
			'bold'       => 1,
			'dark'       => 2,
			'underline'  => 4,
			'underscore' => 4,
			'blink'      => 5,
			'reverse'    => 7,
			'concealed'  => 8,

			'black'      => 30,   'on_black'   => 40,
			'red'        => 31,   'on_red'     => 41,
			'green'      => 32,   'on_green'   => 42,
			'yellow'     => 33,   'on_yellow'  => 43,
			'blue'       => 34,   'on_blue'    => 44,
			'magenta'    => 35,   'on_magenta' => 45,
			'cyan'       => 36,   'on_cyan'    => 46,
			'white'      => 37,   'on_white'   => 47
		}


		###############
		module_function
		###############

		### Make an easily-comparable version vector out of +version_string+ and return it.
		def vvec( version_string )
			return version_string.split('.').collect {|char| char.to_i }.pack('N*')
		end


		### Find an executable program in the current PATH and return it as a Pathname. Raises a
		### RuntimeError if the program cannot be found.
		def which( program )
			unless PROGRAM_PATHS.key?( program )
				raise "No PATH?!?" unless ENV['PATH']
				path = ENV['PATH'].split(/:/).
					collect {|dir| Pathname.new(dir) + program }.
					find {|path| path.exist? && path.executable? } or
					raise "the %p executable was not found in your PATH" % [ program ]
				PROGRAM_PATHS[ program ] = path
				log "Using #{program} at %s" % [ path ]
			end
			return PROGRAM_PATHS[ program ].to_s
		end


		### Create a string that contains the ANSI codes specified and return it
		def ansi_code( *attributes )
			attributes.flatten!
			attributes.collect! {|at| at.to_s }
			# $stderr.puts "Returning ansicode for TERM = %p: %p" %
			# 	[ ENV['TERM'], attributes ]
			return '' unless /(?:vt10[03]|xterm(?:-color)?|linux|screen)/i =~ ENV['TERM']
			attributes = ANSI_ATTRIBUTES.values_at( *attributes ).compact.join(';')

			# $stderr.puts "  attr is: %p" % [attributes]
			if attributes.empty?
				return ''
			else
				return "\e[%sm" % attributes
			end
		end


		### Colorize the given +string+ with the specified +attributes+ and return it, handling 
		### line-endings, color reset, etc.
		def colorize( *args )
			string = ''

			if block_given?
				string = yield
			else
				string = args.shift
			end

			ending = string[/(\s)$/] || ''
			string = string.rstrip

			return ansi_code( args.flatten ) + string + ansi_code( 'reset' ) + ending
		end


		### Output a message with highlighting.
		def log( *msg )
			if $stderr.tty?
				$logger.info( colorize(:cyan) {msg.flatten.join( ' ' )} )
			else
				$logger.info( msg.flatten.join(' ') )
			end
		end


		### Output a logging message if $VERBOSE is true
		def trace( *msg )
			if $stderr.tty?
				$logger.debug( colorize( :yellow ) {msg.flatten.join( ' ' )} )
			else
				$logger.debug( msg.flatten.join(' ') )
			end
		end


		### Return the specified args as a string, quoting any that have a space.
		def quotelist( *args )
			return args.flatten.collect {|part| part.to_s =~ /\s/ ? part.to_s.inspect : part.to_s }
		end


		### Run the specified command +cmd+ with system(), failing if the execution
		### fails.
		def run( *cmd )
			cmd.flatten!
			cmd.collect! {|part| part.to_s }

			if cmd.length > 1
				trace( quotelist(*cmd) )
			else
				trace( cmd )
			end

			system( *cmd )
			raise "Command failed: [%s]" % [cmd.join(' ')] unless $?.success?
		end


		### Run the specified command +cmd+ after redirecting stdout and stderr to the specified 
		### +logpath+, failing if the execution fails.
		def log_and_run( logpath, *cmd )
			cmd.flatten!
			cmd.collect! {|part| part.to_s }

			if cmd.length > 1
				trace( quotelist(*cmd) )
			else
				trace( cmd )
			end

			logfh = File.open( logpath, File::WRONLY|File::CREAT|File::APPEND )
			if pid = fork
				logfh.close
			else
				$stdout.reopen( logfh )
				$stderr.reopen( $stdout )
				exec( *cmd )
				$stderr.puts "Command %s failed: %s. See %s for details." % [
					quotelist(*cmd),
					$?,
					logpath
				]
				$! = 1 # Don't autorun if the exec failed
			end

			return pid
		end


		### Get the version string from Apache.
		def get_apache_version
			httpd = which( 'httpd' ).to_s
			version_output  = IO.read('|-') or exec httpd, '-v'
			trace "version output: \n#{version_output.inspect}"
			return version_output[ %r{Server version: Apache/(\d+\.\d+\.\d+)}, 1 ].
				split('.').collect {|char| char.to_i }.pack('N*')
		end


		### Check the current directory for directories that look like they're
		### testing directories from previous tests, and tell any Apache instances
		### running in them to shut down.
		def stop_existing_servers
			httpd = which( 'httpd' ).to_s
			pat = Pathname.getwd + 'tmp_test_*'
			Pathname.glob( pat.to_s ).each do |testdir|
				datadir = testdir + 'data'
				pidfile = datadir + 'httpd.pid'

				if pidfile.exist? && pid = pidfile.read.chomp.to_i
					begin
						Process.kill( 0, pid )
					rescue Errno::ESRCH
						trace "No httpd running for %s" % [ datadir ]
						# Process isn't alive, so don't try to stop it
					else
						trace "Stopping lingering Apache at PID %d" % [ pid ]
						run httpd, '-f', CONFIGFILE, '-k', 'stop'
					end
				end
			end
		end


		### Load an ERB template from +path+ in a way that works under both Ruby 
		### 1.8.x and 1.9.x.
		def load_template( path )
			path = Pathname( path )

			if Object.const_defined?( :Encoding )
				return ERB.new( path.read(:encoding => 'UTF-8') )
			else
				return ERB.new( path.read )
			end
		end


		### Run the given 'httpd' command with the correct config file and flags.
		def apache_cmd( command )
			httpd = which( 'httpd' )
			pid = log_and_run( @logfile, httpd, '-f', CONFIGFILE, '-e', 'debug', '-k', command )
			Process.waitpid( pid )
			return pid
		end


		### Set up an Apache instance for testing.
		def setup_testing_apache( description )
			stop_existing_servers()

			log "Setting up test httpd for %s tests" % [ description ]
			TEST_DATADIR.mkpath

			# Write the config file, expanded from an ERB template
			template = load_template( HTTPD_CONF_TEMPLATE )
			CONFIGFILE.open( 'w' ) do |ofh|
				output = template.result( binding() )
				ofh.print( output )
			end
			CONFIG_INCLUDE_FILE.open( 'w', 0644 ) {  } # touch the includefile

			# Start the server
			apache_cmd( 'start' )

			# Now wait for it to spin up, trying a connection once every 0.1s
			trace "Waiting for Apache on port %d to spin up..." % [ LISTEN_PORT ]
			timeout = 0.0
			connected = false
			until connected || timeout >= PROCESS_TIMEOUT
				begin
					TCPSocket.open( 'localhost', LISTEN_PORT )
				rescue Errno::ECONNREFUSED
					timeout += PROCESS_WAIT_INTERVAL
					sleep( PROCESS_WAIT_INTERVAL )
				else
					trace "  okay, it's up."
					connected = true
					@pid = Integer( PIDFILE.read )
				end
			end
		end


		### Stop a running testing Apache instance
		def teardown_testing_apache
			raise "No pid was set." unless @pid

			log "Tearing down test httpd at PID #@pid"
			apache_cmd( 'graceful-stop' )

			# Wait for the parent httpd process to disappear before returning
			timeout = 0.0
			trace "waiting for parent Apache at PID #@pid to exit..."
			until @pid.nil? || timeout >= PROCESS_TIMEOUT
				begin
					trace "  checking..."
					Process.kill( 0, @pid )
				rescue Errno::ESRCH
					trace "  nope, it's gone."
					@pid = nil
				else
					trace "  it's still around. Waiting %0.2f seconds until checking again." %
						[ PROCESS_WAIT_INTERVAL ]
					timeout += PROCESS_WAIT_INTERVAL
					sleep( PROCESS_WAIT_INTERVAL )
				end
			end

			trace "After teardown wait, pid is: %p" % [ @pid ]
			raise "Testing Apache at pid %d didn't halt within %d seconds" %
				[ @pid, PROCESS_TIMEOUT ] if @pid
		end


		### Create a logger that outputs to the Apache error log.
		def setup_logging( level=:fatal )
			@logfile = ERRORLOG
			@logfile.dirname.mkpath
			$logger = Logger.new( @logfile )
			$logger.level = LOG_LEVELS[ level ] || Logger::INFO
		end


		### Set logging to go back to STDERR.
		def reset_logging()
			@logfile = nil
			$logger = $default_logger
		end


		### Set up one or more handlers in the +block+ and then gracefully restart the testing
		### Apache.
		def install_handlers( &block )
			unless @pid
				abort "No testing apache running? Did you forget to call setup_testing_apache()?"
			end

			if self.example
				log( example.description )
			else
				log( "Group: ", self.class.description )
			end

			handlerconfig = HandlerConfig.new( &block )
			handlerconfig.generate_handlers
			apache_cmd( 'graceful' )
		end

		### Inject the portions of the error log that were written while the block
		### was called into the thread-local logging array (webkit-rspec-formatter support).
		### This is designed to be used as an 'around' hook in specs that want the error log
		### in rspec output.
		def capture_log
			raise LocalJumpError, "no block given" unless block_given?
			Thread.current[ 'logger-output' ] = []

			ERRORLOG.dirname.mkpath
			File.open( ERRORLOG, File::RDONLY ) do |log|
				log.seek( 0, IO::SEEK_END )
				yield
				Thread.current[ 'logger-output' ] << log.readlines.
					collect {|line| line.sub(/\n/, '<br />')}
			end
		end

	end # module SpecHelpers


	# A collection of methods to add to Numeric for convenience and
	# readability when calculating times and byte sizes.
	module NumericConstantMethods

		### A collection of convenience methods for calculating times using
		### Numeric objects:
		###
		###   # Add convenience methods to Numeric objects
		###   class Numeric
		###       include ThingFish::NumericConstantMethods::Time
		###   end
		###
		###   irb> 138.seconds.ago
		###       ==> Fri Aug 08 08:41:40 -0700 2008
		###   irb> 18.years.ago
		###       ==> Wed Aug 08 20:45:08 -0700 1990
		###   irb> 2.hours.before( 6.minutes.ago )
		###       ==> Fri Aug 08 06:40:38 -0700 2008
		###
		module Time

			### Number of seconds (returns receiver unmodified)
			def seconds
				return self
			end
			alias_method :second, :seconds

			### Returns number of seconds in <receiver> minutes
			def minutes
				return self * 60
			end
			alias_method :minute, :minutes

			### Returns the number of seconds in <receiver> hours
			def hours
				return self * 60.minutes
			end
			alias_method :hour, :hours

			### Returns the number of seconds in <receiver> days
			def days
				return self * 24.hours
			end
			alias_method :day, :days

			### Return the number of seconds in <receiver> weeks
			def weeks
				return self * 7.days
			end
			alias_method :week, :weeks

			### Returns the number of seconds in <receiver> fortnights
			def fortnights
				return self * 2.weeks
			end
			alias_method :fortnight, :fortnights

			### Returns the number of seconds in <receiver> months (approximate)
			def months
				return self * 30.days
			end
			alias_method :month, :months

			### Returns the number of seconds in <receiver> years (approximate)
			def years
				return (self * 365.25.days).to_i
			end
			alias_method :year, :years


			### Returns the Time <receiver> number of seconds before the
			### specified +time+. E.g., 2.hours.before( header.expiration )
			def before( time )
				return time - self
			end


			### Returns the Time <receiver> number of seconds ago. (e.g.,
			### expiration > 2.hours.ago )
			def ago
				return self.before( ::Time.now )
			end


			### Returns the Time <receiver> number of seconds after the given +time+.
			### E.g., 10.minutes.after( header.expiration )
			def after( time )
				return time + self
			end

			# Reads best without arguments:  10.minutes.from_now
			def from_now
				return self.after( ::Time.now )
			end
		end # module Time


		### A collection of convenience methods for calculating bytes using
		### Numeric objects:
		###
		###   # Add convenience methods to Numeric objects
		###   class Numeric
		###       include ThingFish::NumericConstantMethods::Bytes
		###   end
		###
		###   irb> 14.megabytes
		###       ==> 14680064
		###   irb> 188.gigabytes
		###       ==> 201863462912
		###   irb> 177263661663.size_suffix
		###       ==> "165.1G"
		###
		module Bytes

			# Bytes in a Kilobyte
			KILOBYTE = 1024

			# Bytes in a Megabyte
			MEGABYTE = 1024 ** 2

			# Bytes in a Gigabyte
			GIGABYTE = 1024 ** 3


			### Number of bytes (returns receiver unmodified)
			def bytes
				return self
			end
			alias_method :byte, :bytes

			### Returns the number of bytes in <receiver> kilobytes
			def kilobytes
				return self * 1024
			end
			alias_method :kilobyte, :kilobytes

			### Return the number of bytes in <receiver> megabytes
			def megabytes
				return self * 1024.kilobytes
			end
			alias_method :megabyte, :megabytes

			### Return the number of bytes in <receiver> gigabytes
			def gigabytes
				return self * 1024.megabytes
			end
			alias_method :gigabyte, :gigabytes

			### Return the number of bytes in <receiver> terabytes
			def terabytes
				return self * 1024.gigabytes
			end
			alias_method :terabyte, :terabytes

			### Return the number of bytes in <receiver> petabytes
			def petabytes
				return self * 1024.terabytes
			end
			alias_method :petabyte, :petabytes

			### Return the number of bytes in <receiver> exabytes
			def exabytes
				return self * 1024.petabytes
			end
			alias_method :exabyte, :exabytes

			### Return a human readable file size.
			def size_suffix
				bytes = self.to_f
				return case
					when bytes >= GIGABYTE then sprintf( "%0.1fG", bytes / GIGABYTE )
					when bytes >= MEGABYTE then sprintf( "%0.1fM", bytes / MEGABYTE )
					when bytes >= KILOBYTE then sprintf( "%0.1fK", bytes / KILOBYTE )
					else "%db" % [ self ]
					end
			end

		end # module Bytes

	end # module NumericConstantMethods

end # module Apache


class Numeric
	include Apache::NumericConstantMethods::Time,
	        Apache::NumericConstantMethods::Bytes
end

require 'spec/lib/matchers'


### Mock with Rspec
Rspec.configure do |config|
	config.mock_with :rspec
	config.include( Apache::TestConstants )
	config.include( Apache::SpecHelpers )
	config.include( Apache::SpecMatchers )
end

