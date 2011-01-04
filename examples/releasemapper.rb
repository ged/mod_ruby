#!/usr/bin/env ruby -wKU

# releasemapper.rb

require 'pathname'

# A RubyTransHandler example -- maps a URI like '/releases/package-current.tar.gz' 
# into the latest version of 'package' in a release directory. Note that this doesn't
# do version comparison -- it relies on the mtime of the file instead -- but it easily 
# could.
class ReleaseMapper

	### Set up a handler that maps URLs to archives in the given release_dir.
	def initialize( release_dir )
		@release_dir = Pathname( release_dir )
		@release_dir.untaint

		Apache.request.server.log_info "Setting up a translation handler for %s" %
			[ @release_dir ]
	end


	######
	public
	######

	### Translate requests
	def translate_uri( req )
		if req.uri =~ %r{/releases/(\w+)-latest\.gem}
			gemname = $1.untaint
			req.server.log_info "%s: Translating for the %p gem" % [ self.class.name, gemname ]

			# Find the last-updated release with the specified name
			target = Pathname.glob( @release_dir + "#{gemname}-*.gem" ).
				collect( &:untaint ).
				sort_by {|path| path.mtime }.
				last

			# Set the translated path if one was found
			if target
				req.server.log_info "Mapped request for #{req.uri} to #{target}"
				req.filename = target.to_s

				# Indicate that translation has been done
				return Apache::OK
			else
				req.server.log_debug "Not translating: No release corresponded to #{req.uri}."
			end

		end

		# Let other translation handlers run
		return Apache::DECLINED
	end

end

