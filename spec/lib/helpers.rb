#!/usr/bin/env ruby

require 'erb'
require 'pathname'
require 'singleton'
require 'open-uri'

module Apache

	require 'spec/lib/spechandler'

	module SpecHelpers

		BASEDIR             = Pathname( __FILE__ ).expand_path.dirname.parent.parent

		LIBDIR              = BASEDIR + 'lib'
		EXTDIR              = BASEDIR + 'ext'

		SPECDIR             = BASEDIR + 'spec'
		SPEC_DATADIR        = SPECDIR + 'data'
		SPEC_LIBDIR         = SPECDIR + 'lib'
		LISTEN_PORT         = rand( 2000 ) + 62_000

		TEST_DIRECTORY      = BASEDIR + "tmp_test_specs"
		TEST_DATADIR        = TEST_DIRECTORY + 'data'
		CONFIGFILE          = TEST_DIRECTORY + 'test.conf'

		HTTPD_CONF_TEMPLATE = SPEC_DATADIR + 'testing_httpd.conf.erb'
		HANDLER_RB          = TEST_DATADIR + 'handler.rb'

		$LOAD_PATH.unshift( SPEC_LIBDIR.to_s ) unless $LOAD_PATH.include?( SPEC_LIBDIR.to_s )

		PROGRAM_PATHS       = {}


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
			end
			return PROGRAM_PATHS[ program ]
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
			$stderr.puts( colorize(:bold) { msg.flatten.join(' ') } )
		end


		### Output a logging message if $VERBOSE is true
		def trace( *msg )
			return unless $VERBOSE
			output = colorize( msg.flatten.join(' '), 'yellow' )
			$stderr.puts( output )
		end


		### Return the specified args as a string, quoting any that have a space.
		def quotelist( *args )
			return args.flatten.collect {|part| part.to_s =~ /\s/ ? part.to_s.inspect : part.to_s }
		end


		### Run the specified command +cmd+ with system(), failing if the execution
		### fails.
		def run( *cmd )
			cmd.flatten!

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
			httpd = which( 'httpd' )
			version_output  = IO.read('|-') or exec httpd, '-v'
			$stderr.puts "version output: \n#{version_output.inspect}"
			return version_output[ %r{Server version: Apache/(\d+\.\d+\.\d+)}, 1 ].
				split('.').collect {|char| char.to_i }.pack('N*')
		end


		### Check the current directory for directories that look like they're
		### testing directories from previous tests, and tell any Apache instances
		### running in them to shut down.
		def stop_existing_servers
			httpd = which( 'httpd' )
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


		### Set up an Apache instance for testing.
		def setup_testing_apache( description, handler_class )
			stop_existing_servers()

			log "Setting up test httpd for %s tests with %p" %
				[ description, handler_class ]
			TEST_DATADIR.mkpath

			# Write the config file, expanded from an ERB template
			template = load_template( HTTPD_CONF_TEMPLATE )
			CONFIGFILE.open( 'w' ) do |ofh|
				output = template.result( binding() )
				ofh.print( output )
			end

			# Start the server
			httpd = which( 'httpd' )
			trace "Running Apache like: '#{httpd} -f #{CONFIGFILE} -e debug -X'"
			@pid = log_and_run @logfile, httpd, '-f', CONFIGFILE, '-e', 'debug', '-k', 'start'

			# Now wait for it to spin up, trying a connection once every 0.1s
			trace "Testing apache running as PID %d on port %d; waiting for it to spin up..." %
				[ @pid, LISTEN_PORT ]
			timeout = 0.0
			connected = false
			until connected || timeout >= 5.0
				begin
					TCPSocket.open( 'localhost', LISTEN_PORT )
				rescue Errno::ECONNREFUSED
					timeout += 0.1
					sleep 0.1
				else
					trace "  okay, it's up."
					connected = true
				end
			end
		end


		### Stop a running testing Apache instance
		def teardown_testing_apache
			httpd = which( 'httpd' )
			raise "No pid was set." unless @pid
			log "Tearing down test httpd at PID #@pid"

			log_and_run @logfile, httpd, '-f', CONFIGFILE, '-e', 'debug', '-k', 'stop'
			# Process.kill( :TERM, @pid )
			# killed_pid = Process.wait
			# log "  reaped pid #{killed_pid}"
			# pidfile = TEST_DATADIR + 'httpd.pid'
			# pidfile.unlink if pidfile.exist?
		end


		### Set up the Apache log
		### :FIXME: Figure out a way to inject the Apache log into the spec process somehow:
		###         FIFO? Tailed logfile? 
		def setup_logging( level=:crit )
			@logfile = BASEDIR + 'spec.log'
		end


		### Reset the logs. Currently doesn't do anything, but will eventually tear down 
		### anything set up by setup_logging().
		def reset_logging
		end


		### Write out the handler file by expanding it inside an ERB template.
		def write_handler_file( code )
			HANDLER_RB.dirname.mkpath
			HANDLER_RB.open( 'w' ) do |fh|
				fh.write( code )
			end
			return HANDLER_RB
		end


		#
		# Handler definition functions
		#

		### Write the source for a content handler (RubyHandler) to disk, then load it into
		### the spec process too.
		def RubyHandler( uri, code )
			tmpl = load_template( SPEC_DATADIR + 'rubyhandler.erb' )
			code = tmpl.result( binding() )
			filename = write_handler_file( code )
			Apache::SpecHandler.derivatives.clear
			Kernel.load( filename, true )
			new_handler = Apache::SpecHandler.derivatives.first
			new_handler.uri = uri

			return new_handler
		end


	end # module SpecHelpers


end # module Apache

