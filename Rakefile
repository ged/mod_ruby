#!/usr/bin/env rake

require 'rbconfig'
require 'pathname'

require 'rubygems'
require 'rubygems/package_task'

require 'rspec'
require 'rspec/core/rake_task'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'

#
# Rakefile for mod_ruby
# $Id$
#
# Author:
# - Michael Granger <ged@FaerieMUD.org>
#
#


$dryrun = Rake.application.options.dryrun ? true : false
$trace = Rake.application.options.trace ? true : false

### Config constants
BASEDIR       = Pathname.new( __FILE__ ).dirname.relative_path_from( Pathname.getwd )
BINDIR        = BASEDIR + 'bin'
LIBDIR        = BASEDIR + 'lib'
EXTDIR        = BASEDIR + 'ext'
DOCSDIR       = BASEDIR + 'doc'
PKGDIR        = BASEDIR + 'pkg'
DATADIR       = BASEDIR + 'data'

MANUALDIR     = DOCSDIR + 'manual'
API_DOCSDIR   = DOCSDIR + 'api'

PROJECT_NAME  = 'mod_ruby'
PKG_NAME      = PROJECT_NAME.downcase
PKG_SUMMARY   = 'Ruby binding for the Apache API'
VERSION_FILE  = EXTDIR + 'mod_ruby.h'
PKG_VERSION   = VERSION_FILE.
	read[ %r{^#define MOD_RUBY_STRING_VERSION "mod_ruby/(\d+\.\d+\.\d+)"}, 1 ]

PKG_FILE_NAME = "#{PKG_NAME.downcase}-#{PKG_VERSION}"
GEM_FILE_NAME = "#{PKG_FILE_NAME}.gem"

TEXT_FILES    = Rake::FileList.new( %w[Rakefile ChangeLog COPYING LEGAL LICENSE.apreq 
                                       NOTICE *.textile] )
BIN_FILES     = Rake::FileList.new( "#{BINDIR}/*" )
LIB_FILES     = Rake::FileList.new( "#{LIBDIR}/**/*.rb" )
EXT_FILES     = Rake::FileList.new( "#{EXTDIR}/**/*.{c,h}" )
BUILD_FILES   = Rake::FileList.new( "#{EXTDIR}/**/*.{rb,in,tmpl,libdir,module}" )
DATA_FILES    = Rake::FileList.new( "#{DATADIR}/**/*" )
DOC_FILES     = Rake::FileList.new( "#{BASEDIR}/**/*.textile", 'NOTICE',
                                    'LICENSE.apreq', 'COPYING', 'LEGAL', 'ChangeLog' )

SPECDIR       = BASEDIR + 'spec'
SPECLIBDIR    = SPECDIR + 'lib'
SPECDATADIR   = SPECDIR + 'data'
SPEC_FILES    = Rake::FileList.new(
	"#{SPECDIR}/**/*_spec.rb",
	"#{SPECLIBDIR}/**/*.rb",
	"#{SPECDATADIR}/**/*.erb"
)
SPEC_TMPDIR   = BASEDIR + 'tmp_test_specs'


# The compiled Apache module file
MODRUBY_MODULE = EXTDIR + 'mod_ruby.so'
MAKEFILE       = EXTDIR + 'Makefile'
AUTOCONF_RB    = EXTDIR + 'autoconf.rb'
CONFIGURE_RB   = EXTDIR + 'configure.rb'

# RubyGems (at least as of 1.3.7) looks for 'configure', not configure.rb,
# even when you explicitly specify otherwise, so we have to make a
# copy for the gem.
CONFIGURE      = EXTDIR + 'configure'


# :FIXME: I don't know if this is a reasonable way to know what
# language to build the docs in. Also, is it fair to assume that if
# the language *isn't* set to Japanese, the docs should be built in
# English?
# 
# If only RDoc supported m17n...
# README_FILE = ((ENV['LANG'] || '') =~ /\bja\b/) ? 'README.ja' : 'README.en'
README_FILE = 'README.textile'

# Options for RDoc documentation
RDOC_OPTIONS = [
	'--tab-width=4',
	'--show-hash',
	'--include', BASEDIR.to_s,
	"--main=#{README_FILE}",
	"--title=#{PKG_NAME}",
  ]

# Options for YARD documentation
YARD_OPTIONS = [
	'--use-cache',
	'--no-private',
	'--protected',
	'--hide-void-return',
	'-r', README_FILE,
	'--exclude', 'rails_dispatcher\\.rb',
	'--files', DOC_FILES.join(','),
	'--output-dir', API_DOCSDIR.to_s,
	'--title', "#{PKG_NAME} #{PKG_VERSION}",
  ]

# The manifest for packaging
RELEASE_FILES = TEXT_FILES  +
                SPEC_FILES  +
                BIN_FILES   +
                LIB_FILES   +
                EXT_FILES   +
                BUILD_FILES +
                DATA_FILES

# RubyGem specification
GEMSPEC = Gem::Specification.new do |gem|
	gem.name              = 'mod_ruby'
	gem.version           = PKG_VERSION

	gem.summary           = 'Embedding Ruby in the Apache web server'
	gem.description       = "mod_ruby embeds the Ruby interpreter into the Apache web " +
		"server, allowing Ruby CGI scripts to be executed natively. These scripts " +
		"will start up much faster than without mod_ruby. You can also extend Apache " +
		"by mod_ruby. mod_ruby provides Apache API to Ruby."

	gem.authors           = "Shugo Maeda"
	gem.email             = ["shugo@ruby-lang.org"]
	gem.homepage          = 'http://github.com/shugo/mod_ruby'

	gem.has_rdoc          = true
	gem.rdoc_options      = RDOC_OPTIONS
	gem.extra_rdoc_files  = [
		# :TODO: After I add the 'rd' converter for YARD
		'doc/classes.en.rd',
		'doc/classes.ja.euc.rd',
		'doc/default.css',
		'doc/directives.en.rd',
		'doc/directives.ja.euc.rd',
		'doc/faq.en.rd',
		'doc/faq.ja.euc.rd',
		'doc/index.en.rd',
		'doc/index.ja.euc.rd',
		'doc/install.en.rd',
		'doc/install.ja.euc.rd',
		'doc/writing-handlers.textile',
	]

	gem.extensions        = 'ext/configure'

	gem.files             = RELEASE_FILES
	gem.test_files        = SPEC_FILES

	gem.requirements << 'Apache >= 2.0.0'
end

# Append docs/lib to the load path if it exists for documentation
# helpers.
DOCSLIB = DOCSDIR + 'lib'
DOCFILES = Rake::FileList[ LIB_FILES + EXT_FILES + GEMSPEC.extra_rdoc_files ]
$LOAD_PATH.unshift( DOCSLIB.to_s ) if DOCSLIB.exist?

$LOAD_PATH.unshift( BASEDIR.expand_path.to_s ) unless $LOAD_PATH.include?( BASEDIR.expand_path.to_s )
require 'rake/helpers'
include RakefileHelpers


#
# Tasks for mod_ruby
#

desc "Default task -- compile, run specs, generate API docs, and build a gem"
task :default => [:spec, :apidocs, :gem]


#
# Compilation tasks
#

desc "Compile the Apache module (#{MODRUBY_MODULE})"
task :compile => MODRUBY_MODULE.to_s

file AUTOCONF_RB

desc "Create the configuration script from #{AUTOCONF_RB}"
file CONFIGURE_RB => AUTOCONF_RB.to_s do
	Dir.chdir( AUTOCONF_RB.dirname ) do
		run 'ruby', AUTOCONF_RB.basename.to_s
	end
end
CLOBBER.include( CONFIGURE_RB.to_s )

desc "Create the mod_ruby Makefile"
file MAKEFILE => CONFIGURE_RB.to_s do
	configure_argv = ARGV.select {|arg| arg.index('-') == 0 }
	trace "Configuration args: %p" % [ configure_argv ]

	Dir.chdir( EXTDIR ) do
		run 'ruby', CONFIGURE_RB.basename.to_s, *configure_argv
	end
end
CLOBBER.include( MAKEFILE.to_s )

desc "Compile #{MODRUBY_MODULE}"
file MODRUBY_MODULE => [ MAKEFILE.to_s ] + EXT_FILES.collect {|f| f.to_s } do
	Dir.chdir( EXTDIR ) do
		run 'make'
	end
end
CLEAN.include( MODRUBY_MODULE.to_s )
CLEAN.include( EXT_FILES.pathmap("%X.o") )


#
# Testing tasks
#

desc "Run the unit tests"
task :spec => 'spec:default'
task :test => :spec

namespace :spec do

	RSpec::Core::RakeTask.new( :default ) do |task|
		task.rspec_opts = "-cfd"
	end
	task :default => [ MODRUBY_MODULE.to_s ]

end
CLEAN.include( SPEC_TMPDIR.to_s )


#
# Packaging task
#

desc "Build the mod_ruby gem"
Gem::PackageTask.new( GEMSPEC ) do |pkg|
	pkg.need_zip = true
	pkg.need_tar = true
end
CLEAN.include( PKGDIR.to_s )
task :gem => [ CONFIGURE_RB.to_s ]

#
# Documentation tasks
#

# Prefer YARD, fallback to RDoc
begin
	require 'yard'
	require 'yard/rake/yardoc_task'

	# Undo the monkeypatch yard/globals.rb installs and
	# re-install them as a mixin
	# <metamonkeypatch>
	class Object
		remove_method :log
		remove_method :P
	end

	module YardGlobals
		def P(namespace, name = nil)
			namespace, name = nil, namespace if name.nil?
			YARD::Registry.resolve(namespace, name, false, true)
		end

		def log
			YARD::Logger.instance
		end
	end

	class YARD::CLI::Base; include YardGlobals; end
	class YARD::CLI::Command; include YardGlobals; end
	class YARD::Parser::SourceParser; extend YardGlobals; include YardGlobals; end
	class YARD::Parser::CParser; include YardGlobals; end
	class YARD::CodeObjects::Base; include YardGlobals; end
	class YARD::Handlers::Base; include YardGlobals; end
	class YARD::Handlers::Processor; include YardGlobals; end
	class YARD::Serializers::Base; include YardGlobals; end
	class YARD::RegistryStore; include YardGlobals; end
	class YARD::Docstring; include YardGlobals; end
	module YARD::Templates::Helpers::ModuleHelper; include YardGlobals; end
	module YARD::Tags::RefTaglist; include YardGlobals; end

	if vvec(RUBY_VERSION) >= vvec("1.9.1")
		# Monkeypatched to allow more than two '#' characters at the beginning
		# of the comment line.
		# Patched from yard-0.5.8
		require 'yard/parser/ruby/ruby_parser'
		class YARD::Parser::Ruby::RipperParser < Ripper
			def on_comment(comment)
				# $stderr.puts "Adding comment: %p" % [ comment ]
				visit_ns_token(:comment, comment)

				comment = comment.gsub(/^\#+\s?/, '').chomp
				append_comment = @comments[lineno - 1]

				if append_comment && @comments_last_column == column
					@comments.delete(lineno - 1)
					comment = append_comment + "\n" + comment
				end

				@comments[lineno] = comment
				@comments_last_column = column
			end
		end # class YARD::Parser::Ruby::RipperParser
	end

	# </metamonkeypatch>

	YARD_OPTIONS = [] unless defined?( YARD_OPTIONS )

	# This file makes YARD throw fits for reasons I don't entirely understand.
	DOCFILES.exclude( 'lib/apache/rails-dispatcher.rb' )

	yardoctask = YARD::Rake::YardocTask.new( :apidocs ) do |task|
		task.files   = DOCFILES
		task.options = YARD_OPTIONS
		task.options << '--debug' << '--verbose' if $trace
	end
	yardoctask.before = lambda {
		trace "Calling yardoc like:",
			"  yardoc %s" % [ quotelist(yardoctask.options + yardoctask.files).join(' ') ]
	}
	task :apidocs => [ 'ChangeLog' ]

	YARDOC_CACHE = BASEDIR + '.yardoc'
	CLOBBER.include( YARDOC_CACHE.to_s )

rescue LoadError
	require 'rdoc/task'

	desc "Build API documentation in #{API_DOCSDIR}"
	RDoc::Task.new( :apidocs ) do |task|
		task.main     = "README"
		task.rdoc_files.include( DOCFILES )
		task.rdoc_dir = API_DOCSDIR.to_s
		task.options  = RDOC_OPTIONS
	end
end

# Need the DOCFILES to exist to build the API docs
task :apidocs => DOCFILES
CLEAN.include( API_DOCSDIR.to_s  )


#
# Commit tasks -- not done yet.
#

require 'rake/hg'
include MercurialHelpers


file 'ChangeLog' do |task|
	$stderr.puts "Updating #{task.name}"

	hgdir = BASEDIR + '.hg'
	gitdir = BASEDIR + '.git'

	changelog = if gitdir.exist?
		changelog = IO.read( '|-' ) or
			exec 'git', 'log', '--summary', '--stat', '--no-merges', '--date=short'
	elsif hgdir.exist?
		changelog = make_changelog()
	else
		changelog = "Not a version-controlled directory, no changelog."
	end

	File.open( task.name, 'w' ) do |fh|
		fh.print( changelog )
	end
end
CLOBBER.include( 'ChangeLog' )


