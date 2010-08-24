#!/usr/bin/env rake

require 'rbconfig'
require 'pathname'

require 'spec'
require 'spec/runner'

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


$dryrun = false

### Config constants
BASEDIR       = Pathname.new( __FILE__ ).dirname.relative_path_from( Pathname.getwd )
BINDIR        = BASEDIR + 'bin'
LIBDIR        = BASEDIR + 'lib'
EXTDIR        = BASEDIR + 'ext'
DOCSDIR       = BASEDIR + 'doc'
PKGDIR        = BASEDIR + 'pkg'
DATADIR       = BASEDIR + 'data'

MANUALDIR     = DOCSDIR + 'manual'

PROJECT_NAME  = 'mod_ruby'
PKG_NAME      = PROJECT_NAME.downcase
PKG_SUMMARY   = 'Ruby binding for the Apache API'
VERSION_FILE  = EXTDIR + 'mod_ruby.h'
PKG_VERSION   = VERSION_FILE.
	read[ %r{^#define MOD_RUBY_STRING_VERSION "mod_ruby/(\d+\.\d+\.\d+)"}, 1 ]

PKG_FILE_NAME = "#{PKG_NAME.downcase}-#{PKG_VERSION}"
GEM_FILE_NAME = "#{PKG_FILE_NAME}.gem"

TEXT_FILES    = Rake::FileList.new( %w[Rakefile ChangeLog README* LICENSE] )
BIN_FILES     = Rake::FileList.new( "#{BINDIR}/*" )
LIB_FILES     = Rake::FileList.new( "#{LIBDIR}/**/*.rb" )
EXT_FILES     = Rake::FileList.new( "#{EXTDIR}/**/*.{c,h,rb}" )
DATA_FILES    = Rake::FileList.new( "#{DATADIR}/**/*" )

SPECDIR       = BASEDIR + 'spec'
SPECLIBDIR    = SPECDIR + 'lib'
SPEC_FILES    = Rake::FileList.new( "#{SPECDIR}/**/*_spec.rb", "#{SPECLIBDIR}/**/*.rb" )

RELEASE_FILES = TEXT_FILES +
                SPEC_FILES +
                BIN_FILES  +
                LIB_FILES  +
                EXT_FILES  +
                DATA_FILES

COMMON_SPEC_OPTS = ['-Du']



#
# Tasks for mod_ruby
#

desc "Generate regular color 'doc' spec output"
task :spec do |task|
	opts = Spec::Runner::Options.new( $stderr, $stdout )
	opts.parse_format( 'specdoc' )
	opts.parse_diff( 'unified' )
	opts.colour = true
	opts.files.push( *SPEC_FILES )

	Spec::Runner.use( opts )
	opts.run_examples
end


