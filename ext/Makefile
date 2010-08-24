# Generated automatically by configure.rb.

srcdir = /Users/mgranger/source/ruby/mod_ruby/ext
topdir = /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/universal-darwin10.0
hdrdir = /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/universal-darwin10.0
VPATH = $(srcdir)

arch = universal-darwin10.0
sitearch = universal-darwin10.0
ruby_version = 1.8

DESTDIR = 

prefix = $(DESTDIR)/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datadir = $(datarootdir)
libdir = $(exec_prefix)/lib
rubylibprefix = 
rubylibdir = $(libdir)/ruby/$(ruby_version)
archdir = $(rubylibdir)/$(arch)
sitedir = $(DESTDIR)/Library/Ruby/Site
sitelibdir = $(sitedir)/$(ruby_version)
sitearchdir = $(sitelibdir)/$(sitearch)
includedir = $(prefix)/include
mandir = $(DESTDIR)/usr/share/man

CC = gcc
AR = ar
LD = $(CC)
RANLIB = ranlib
RUBY = /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby
RUBY_BASE_NAME = 
RM = rm -f

CFLAGS = -arch x86_64 -g -Os -pipe -fno-common -DENABLE_DTRACE  -fno-common  -pipe -fno-common $(cflags) -Wall  -O2 -arch x86_64  -DDARWIN -DSIGPROCMASK_SETS_THREAD_MASK -no-cpp-precomp  -I. -I$(hdrdir) -I$(hdrdir)/$(arch) $(APACHE_INCLUDES) $(LIBAPREQ_INCLUDES)  
cflags = $(optflags) $(debugflags)
optflags = 
debugflags = 
COUTFLAG = -o
LDFLAGS = -L. -arch x86_64 
LIBS = -lpthread -ldl 
XLDFLAGS =  -L$(libdir)
DLDFLAGS = 
LDSHARED = cc -arch x86_64 -pipe -bundle -undefined dynamic_lookup
INSTALL = /opt/local/bin/ginstall -c
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DLLIB = $(INSTALL) -m 555
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_DIR = $(INSTALL) -d

ruby_install_name = ruby
RUBY_INSTALL_NAME = ruby
LIBRUBYARG = $(LIBRUBYARG_SHARED)
LIBRUBYARG_SHARED = -l$(RUBY_SO_NAME)
LIBRUBYARG_STATIC = -l$(RUBY_SO_NAME)
LIBRUBY_A = lib$(RUBY_SO_NAME)-static.a
LIBRUBY = $(LIBRUBY_SO)
RUBY_SO_NAME = ruby

APACHE_SRCDIR = 
APACHE_INCLUDES = -I/opt/local/apache2/include -I/opt/local/include -I/opt/local/include/apr-1
APACHE_LIBEXECDIR = $(DESTDIR)/opt/local/apache2/modules
APACHE_LIBDIR = /opt/local/lib
APACHE_LIBS = 
APACHE_SRC_UID = 
APACHE_SRC_GID = 

LIBAPREQ_INCLUDES = 

DEFFILE = 
LOCAL_LIBS = $(LIBRUBYARG) $(APACHE_LIBS)
LIBPATH =  -L$(APACHE_LIBDIR)

TARGET = mod_ruby.so

MAJOR = 1
MINOR = 3
TEENY = 0
VERSION = $(MAJOR).$(MINOR).$(TEENY)
SVNREPOS = https://projects.netlab.jp/svn/mod_ruby

RUBYLIBS	= apache/ruby-run.rb \
		  apache/registry.rb \
		  apache/eruby-run.rb \
		  apache/erb-run.rb \
		  apache/rd2html.rb \
		  apache/ruby-debug.rb \
		  apache/eruby-debug.rb \
		  apache/ruby-profile.rb \
		  apache/rails-dispatcher.rb \
		  apache/query.rb \
		  auto-reload.rb

OBJS		= mod_ruby.o \
		  ruby_config.o \
		  apachelib.o \
		  array_header.o \
		  table.o \
		  connection.o \
		  server.o \
		  request.o \
		  upload.o \
		  cookie.o \
		  paramtable.o \
		  multival.o \
		  bucket.o \
		  uri.o \
		  error.o \
		  apache_request.o \
		  apache_multipart_buffer.o \
		  apache_cookie.o

.c.o:
	$(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -c $<



all: $(TARGET)

install: install-shared install-ruby

site-install: install-shared install-siteruby

install-ruby:
	$(INSTALL_DIR) $(rubylibdir)/apache
	$(RUBY) -e "%w!$(RUBYLIBS)!.each{|file| system(%Q!#{'$(INSTALL_DATA)'} $(srcdir)/lib/#{file} $(rubylibdir)/#{file}!)}"

install-siteruby:
	$(INSTALL_DIR) $(sitelibdir)/apache
	$(RUBY) -e "%w!$(RUBYLIBS)!.each{|file| system(%Q!#{'$(INSTALL_DATA)'} $(srcdir)/lib/#{file} $(sitelibdir)/#{file}!)}"

install-static: all
	$(INSTALL_DIR) -o $(APACHE_SRC_UID) -g $(APACHE_SRC_GID) \
		$(APACHE_SRCDIR)/src/modules/ruby
	$(INSTALL_DATA) -o $(APACHE_SRC_UID) -g $(APACHE_SRC_GID) \
		$(TARGET) $(APACHE_SRCDIR)/src/modules/ruby
	$(INSTALL_DATA) -o $(APACHE_SRC_UID) -g $(APACHE_SRC_GID) \
		mod_ruby.c $(APACHE_SRCDIR)/src/modules/ruby
	$(INSTALL_DATA) -o $(APACHE_SRC_UID) -g $(APACHE_SRC_GID) \
		Makefile.tmpl $(APACHE_SRCDIR)/src/modules/ruby
	$(INSTALL_DATA) -o $(APACHE_SRC_UID) -g $(APACHE_SRC_GID) \
		Makefile.libdir $(APACHE_SRCDIR)/src/modules/ruby
	$(INSTALL_DATA) -o $(APACHE_SRC_UID) -g $(APACHE_SRC_GID) \
		libruby.module $(APACHE_SRCDIR)/src/modules/ruby
	$(INSTALL_DATA) -o $(APACHE_SRC_UID) -g $(APACHE_SRC_GID) \
		ruby_shared_stub.c $(APACHE_SRCDIR)/src/modules/ruby

install-shared: all
	$(INSTALL_DIR) $(APACHE_LIBEXECDIR)
	$(INSTALL_DLLIB) $(TARGET) $(APACHE_LIBEXECDIR)

clean:
	$(RM) libruby.a
	$(RM) mod_ruby.so tests/mod_ruby.so
	$(RM) $(OBJS)

distclean: clean
	$(RM) Makefile
	$(RM) doc/Makefile
	$(RM) libruby.module
	$(RM) mod_ruby.imp
	$(RM) test.cfg
	find . -name '*~' | xargs $(RM)

tag:
	svn copy $(SVNREPOS)/mod_ruby/trunk \
		 $(SVNREPOS)/mod_ruby/tags/$(VERSION) \
		 -m "tagged version $(VERSION)"

dist:
	svn export $(SVNREPOS)/mod_ruby/tags/$(VERSION) mod_ruby-$(VERSION)
	svn log -v $(SVNREPOS)/mod_ruby/trunk/ > mod_ruby-$(VERSION)/ChangeLog
	tar zcf ../mod_ruby-$(VERSION).tar.gz mod_ruby-$(VERSION)
	rm -rf mod_ruby-$(VERSION)

libruby.a: $(OBJS)
	$(AR) rcu $@ $(OBJS)
	$(RANLIB) $@

mod_ruby.so: $(OBJS)
	$(LDSHARED) -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(XLDFLAGS) $(LOCAL_LIBS) $(LIBS)

### depend
mod_ruby.o: mod_ruby.c mod_ruby.h ruby_config.h apachelib.h
ruby_config.o: ruby_config.c mod_ruby.h ruby_config.h
apachelib.o: apachelib.c mod_ruby.h apachelib.h
array_header.o: array_header.c mod_ruby.h apachelib.h
table.o: table.c mod_ruby.h apachelib.h
connection.o: connection.c mod_ruby.h apachelib.h
server.o: server.c mod_ruby.h apachelib.h
request.o: request.c mod_ruby.h apachelib.h
upload.o: upload.c mod_ruby.h apachelib.h
cookie.o: cookie.c mod_ruby.h apachelib.h
paramtable.o: paramtable.c mod_ruby.h apachelib.h
multival.o: multival.c mod_ruby.h apachelib.h
bucket.o: bucket.c mod_ruby.h apachelib.h
uri.o: uri.c mod_ruby.h apachelib.h
error.o: error.c mod_ruby.h apachelib.h

apache_request.o: apache_request.c mod_ruby.h apache_request.h
apache_multipart_buffer.o: apache_multipart_buffer.c mod_ruby.h apache_request.h apache_multipart_buffer.h
apache_cookie.o: apache_cookie.c apache_cookie.h apache_request.h
