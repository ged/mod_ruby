#!/usr/bin/env ruby

require 'pathname'
require 'singleton'

module Apache
	class SpecHandler
		include Singleton

		def self::on( path, &block )
			self.instance.path_handlers[ path ] = block
		end

		def initialize
			@path_handlers = {}
		end

		attr_reader :path_handlers

		def handle( req )
			if block = self.path_handlers[ req.path_info ]
				return block.call( req )
			else
				req.server.log_error( "Missing handler for %p", req.path_info )
				return Apache::SERVER_ERROR
			end
		end

	end
end

module ModRubyTestingHelpers

	SPEC_DATA_DIR = Pathname( __FILE__ ).parent + 'data'
	HTTPD_CONF_TEMPLATE = SPEC_DATA_DIR + 'testing_httpd.conf.erb'


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
	def message( *msg )
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

		if cmd.length > 1
			trace( quotelist(*cmd) )
		else
			trace( cmd )
		end

		logfh = File.open( logpath, File::WRONLY|File::CREAT|File::APPEND )
		if pid = fork
			logfh.close
			Process.wait
		else
			$stdout.reopen( logfh )
			$stderr.reopen( $stdout )
			exec( *cmd )
			$stderr.puts "After the exec()?!??!"
			exit!
		end

		raise "Command failed: [%s]" % [cmd.join(' ')] unless $?.success?
	end


	### Check the current directory for directories that look like they're
	### testing directories from previous tests, and tell any Apache instances
	### running in them to shut down.
	def stop_existing_servers
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
					run 'httpd', '-d', datadir.to_s, '-k', 'stop'
				end
			end
		end
	end


	### Set up an Apache instance for testing.
	def setup_testing_apache( description )
		stop_existing_servers()

		$stderr.puts "Setting up test httpd for #{description} tests"
		@test_directory = Pathname.getwd + "tmp_test_specs"
		@test_datadir = @test_directory + 'data'
		@test_datadir.mkpath

		@basedir = Pathname( __FILE__ ).expand_path.dirname.parent.parent
		@listen_port = rand( 2000 ) + 62_000

		@configfile = @test_directory + 'test.conf'
		template = ERB.new
		@configfile.open( 'w' ) do |ofh|
			
		end

		log_and_run @logfile, @httpd, '-f', @configfile
	end


	def teardown_testing_apache( conn )
		puts "Tearing down test httpd"
		log_and_run @logfile, 'httpd', '-f', @configfile, '-k', 'stop'
	end
end


