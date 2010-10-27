#!/usr/bin/env ruby
#coding: utf-8

module Apache

	class Connection; end
	class Cookie; end
	class MultiVal; end
	class ParamTable; end
	class Request; end
	class Server; end
	class Table; end
	class Upload; end

	module TestConstants

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
		PIDFILE             = TEST_DIRECTORY + 'httpd.pid'

		ERRORLOG            = TEST_DATADIR + 'error.log'

		# The name of the config that gets included into the testing server's 
		# boilerplate config
		CONFIG_INCLUDE_FILE = TEST_DATADIR + 'handlers.conf'

		HTTPD_CONF_TEMPLATE = SPEC_DATADIR + 'testing_httpd.conf.erb'
		# HANDLER_RB          = TEST_DATADIR + 'handler.rb'

		unless defined?( M_GET )
			M_GET       = 0
			M_PUT       = 1
			M_POST      = 2
			M_DELETE    = 3
			M_CONNECT   = 4
			M_OPTIONS   = 5
			M_TRACE     = 6
			M_PATCH     = 7
			M_PROPFIND  = 8
			M_PROPPATCH = 9
			M_MKCOL     = 10
			M_COPY      = 11
			M_MOVE      = 12
			M_LOCK      = 13
			M_UNLOCK    = 14
			M_INVALID   = 26
			METHODS     = 64

			METHOD_NUMBERS_TO_NAMES = {
				M_CONNECT	=> 'CONNECT',
				M_COPY		=> 'COPY',
				M_DELETE	=> 'DELETE',
				M_GET		=> 'GET',
				M_INVALID	=> 'INVALID',
				M_LOCK		=> 'LOCK',
				M_MKCOL		=> 'MKCOL',
				M_MOVE		=> 'MOVE',
				M_OPTIONS	=> 'OPTIONS',
				M_PATCH		=> 'PATCH',
				M_POST		=> 'POST',
				M_PROPFIND	=> 'PROFIND',
				M_PROPPATCH => 'PROPATCH',
				M_PUT		=> 'PUT',
				M_TRACE		=> 'TRACE',
				M_UNLOCK	=> 'UNLOCK',
			}
			METHOD_NAMES_TO_NUMBERS = METHOD_NUMBERS_TO_NAMES.invert

			OPT_NONE      = 0
			OPT_INDEXES   = 1
			OPT_INCLUDES  = 2
			OPT_SYM_LINKS = 4
			OPT_EXECCGI   = 8
			OPT_ALL       = 15
			OPT_UNSET     = 16
			OPT_INCNOEXEC = 32
			OPT_SYM_OWNER = 64
			OPT_MULTI     = 128

			SATISFY_ALL    = 0
			SATISFY_ANY    = 1
			SATISFY_NOSPEC = 2

			REQUEST_NO_BODY         = 0
			REQUEST_CHUNKED_ERROR   = 1
			REQUEST_CHUNKED_DECHUNK = 2

			REMOTE_HOST       = 0
			REMOTE_NAME       = 1
			REMOTE_NOLOOKUP   = 2
			REMOTE_DOUBLE_REV = 3

			DONE     = -2
			DECLINED = -1
			OK       = 0

			HTTP_CONTINUE            = 100
			HTTP_SWITCHING_PROTOCOLS = 101
			HTTP_PROCESSING          = 102

			DOCUMENT_FOLLOWS       = 200
			HTTP_OK                = 200
			HTTP_CREATED           = 201
			HTTP_ACCEPTED          = 202
			HTTP_NON_AUTHORITATIVE = 203
			HTTP_NO_CONTENT        = 204
			HTTP_RESET_CONTENT     = 205
			HTTP_PARTIAL_CONTENT   = 206
			PARTIAL_CONTENT        = 206
			HTTP_MULTI_STATUS      = 207

			HTTP_MULTIPLE_CHOICES   = 300
			MULTIPLE_CHOICES        = 300
			HTTP_MOVED_PERMANENTLY  = 301
			MOVED                   = 301
			HTTP_MOVED_TEMPORARILY  = 302
			REDIRECT                = 302
			HTTP_SEE_OTHER          = 303
			HTTP_NOT_MODIFIED       = 304
			USE_LOCAL_COPY          = 304
			HTTP_USE_PROXY          = 305
			HTTP_TEMPORARY_REDIRECT = 307

			BAD_REQUEST                        = 400
			HTTP_BAD_REQUEST                   = 400
			AUTH_REQUIRED                      = 401
			HTTP_UNAUTHORIZED                  = 401
			HTTP_PAYMENT_REQUIRED              = 402
			FORBIDDEN                          = 403
			HTTP_FORBIDDEN                     = 403
			HTTP_NOT_FOUND                     = 404
			NOT_FOUND                          = 404
			HTTP_METHOD_NOT_ALLOWED            = 405
			METHOD_NOT_ALLOWED                 = 405
			HTTP_NOT_ACCEPTABLE                = 406
			NOT_ACCEPTABLE                     = 406
			HTTP_PROXY_AUTHENTICATION_REQUIRED = 407
			HTTP_REQUEST_TIME_OUT              = 408
			HTTP_CONFLICT                      = 409
			HTTP_GONE                          = 410
			HTTP_LENGTH_REQUIRED               = 411
			LENGTH_REQUIRED                    = 411
			HTTP_PRECONDITION_FAILED           = 412
			PRECONDITION_FAILED                = 412
			HTTP_REQUEST_ENTITY_TOO_LARGE      = 413
			HTTP_REQUEST_URI_TOO_LARGE         = 414
			HTTP_UNSUPPORTED_MEDIA_TYPE        = 415
			HTTP_RANGE_NOT_SATISFIABLE         = 416
			HTTP_EXPECTATION_FAILED            = 417
			HTTP_UNPROCESSABLE_ENTITY          = 422
			HTTP_LOCKED                        = 423
			HTTP_FAILED_DEPENDENCY             = 424

			HTTP_INTERNAL_SERVER_ERROR = 500
			SERVER_ERROR               = 500
			HTTP_NOT_IMPLEMENTED       = 501
			NOT_IMPLEMENTED            = 501
			BAD_GATEWAY                = 502
			HTTP_BAD_GATEWAY           = 502
			HTTP_SERVICE_UNAVAILABLE   = 503
			HTTP_GATEWAY_TIME_OUT      = 504
			HTTP_VERSION_NOT_SUPPORTED = 505
			HTTP_VARIANT_ALSO_VARIES   = 506
			VARIANT_ALSO_VARIES        = 506
			HTTP_INSUFFICIENT_STORAGE  = 507
			HTTP_NOT_EXTENDED          = 510

			STATUS_NAMES = {
				100 => 'HTTP_CONTINUE',
				101 => 'HTTP_SWITCHING_PROTOCOLS',
				102 => 'HTTP_PROCESSING',

				200 => 'HTTP_OK',
				201 => 'HTTP_CREATED',
				202 => 'HTTP_ACCEPTED',
				203 => 'HTTP_NON_AUTHORITATIVE',
				204 => 'HTTP_NO_CONTENT',
				205 => 'HTTP_RESET_CONTENT',
				206 => 'PARTIAL_CONTENT',
				207 => 'HTTP_MULTI_STATUS',

				300 => 'MULTIPLE_CHOICES',
				301 => 'MOVED',
				302 => 'REDIRECT',
				303 => 'HTTP_SEE_OTHER',
				304 => 'HTTP_NOT_MODIFIED',
				304 => 'USE_LOCAL_COPY',
				305 => 'HTTP_USE_PROXY',
				307 => 'HTTP_TEMPORARY_REDIRECT',

				400 => 'BAD_REQUEST',
				401 => 'AUTH_REQUIRED',
				402 => 'HTTP_PAYMENT_REQUIRED',
				403 => 'FORBIDDEN',
				404 => 'NOT_FOUND',
				405 => 'METHOD_NOT_ALLOWED',
				406 => 'NOT_ACCEPTABLE',
				407 => 'HTTP_PROXY_AUTHENTICATION_REQUIRED',
				408 => 'HTTP_REQUEST_TIME_OUT',
				409 => 'HTTP_CONFLICT',
				410 => 'HTTP_GONE',
				411 => 'LENGTH_REQUIRED',
				412 => 'PRECONDITION_FAILED',
				413 => 'HTTP_REQUEST_ENTITY_TOO_LARGE',
				414 => 'HTTP_REQUEST_URI_TOO_LARGE',
				415 => 'HTTP_UNSUPPORTED_MEDIA_TYPE',
				416 => 'HTTP_RANGE_NOT_SATISFIABLE',
				417 => 'HTTP_EXPECTATION_FAILED',
				422 => 'HTTP_UNPROCESSABLE_ENTITY',
				423 => 'HTTP_LOCKED',
				424 => 'HTTP_FAILED_DEPENDENCY',

				500 => 'SERVER_ERROR',
				501 => 'NOT_IMPLEMENTED',
				502 => 'BAD_GATEWAY',
				503 => 'HTTP_SERVICE_UNAVAILABLE',
				504 => 'HTTP_GATEWAY_TIME_OUT',
				505 => 'HTTP_VERSION_NOT_SUPPORTED',
				506 => 'VARIANT_ALSO_VARIES',
				507 => 'HTTP_INSUFFICIENT_STORAGE',
				510 => 'HTTP_NOT_EXTENDED'
			}
		end

	end # module TestConstants
end # module Apache

