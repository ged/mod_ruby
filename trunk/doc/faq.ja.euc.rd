=begin

= mod_ruby FAQ

[((<�ܼ�|URL:index.ja.jis.html>))
|((<RD����|URL:faq.ja.euc.rd>))]

* ((<mod_ruby�Ȥϲ��Ǥ���?>))
* ((<�ɤ���mod_ruby������Ǥ��ޤ���?>))
* ((<�Х��ʥ�ѥå������Ϥ���ޤ���?>))
* ((<mod_ruby�Υ᡼��󥰥ꥹ�ȤϤ���ޤ���?>))
* ((<mod_ruby�ϰ����Ǥ���?>))
* ((<�Ť������򤹤륹����ץȤˤ���̤�����ޤ���?>))
* ((<Windows��ư���ޤ���?>))
* ((<LoadModule��ȿ�Ǥ���ޤ���>))
* ((<�ʤ�Content-Type���֥饦����ɽ�������ΤǤ���?>))
* ((<�饤�֥����ѹ���ȿ�Ǥ���ʤ��ΤǤ���?>))
* ((<SecurityError��ȯ�����ޤ���>))
* ((<Location�إå�����Ϥ��Ƥ��꤯ư���ޤ���>))
* ((<CGI::Session����꤯ư���ޤ���>))
* ((<�ʤ������顼���Фޤ���>))
* ((<Apache������ޤ���>))
* ((<(({apachectl restart}))�ǥ���꡼�����ޤ���>))
* ((<libruby.so��liberuby.so�����Ĥ���ޤ���>))
* ((<��¸�Υ��饹�������Ǥ��ޤ���>))

== mod_ruby�Ȥϲ��Ǥ���?

mod_ruby��Ruby���󥿥ץ꥿��Apache(WWW������)���Ȥ߹��ߡ�Apache��ľ��
Ruby��CGI������ץȤ�¹ԤǤ���褦�ˤ��ޤ���
mod_ruby��Ȥ��ȡ��̾��CGI���⥹����ץȤϹ�®�˵�ư����ޤ���

[((<�ܼ������|mod_ruby FAQ>))]

== �ɤ���mod_ruby������Ǥ��ޤ���?

mod_ruby�θ��������֥�����((<URL:http://www.modruby.net/>))
������Ǥ��ޤ���

[((<�ܼ������|mod_ruby FAQ>))]

== �Х��ʥ�ѥå������Ϥ���ޤ���?

Debian GNU/Linux��FreeBSD�Ǥ�ɸ��ѥå������Ȥ����󶡤���Ƥ��ޤ���

RPM��((<Vine Linux|URL:http://www.vinelinux.org/>))���󶡤���Ƥ��ޤ���

[((<�ܼ������|mod_ruby FAQ>))]

== mod_ruby�Υ᡼��󥰥ꥹ�ȤϤ���ޤ���?

�Ѹ�Υ᡼��󥰥ꥹ��((<URL:mailto:modruby@modruby.net>))��
���ܸ�Υ᡼��󥰥ꥹ��((<URL:mailto:modruby-ja@modruby.net>)))������ޤ���

���ɤ���ˤ�((<URL:mailto:modruby-ctl@modruby.net>))
���뤤��((<URL:mailto:modruby-ja-ctl@modruby.net>))�ˡ�

  subscribe Your-First-Name Your-Last-Name

�Τ褦����ʸ�Υ᡼������äƤ���������

[((<�ܼ������|mod_ruby FAQ>))]

== mod_ruby�ϰ����Ǥ���?

�������ϡ֤Ϥ��פǤ���֤������פǤ���

mod_ruby�Υǥե���Ȥ�$SAFE���ͤ�1�ʤΤǡ�CGI�ץ�����ޤΥߥ��ˤ�ä�
�������ƥ��ۡ�����äƤ��ޤ���ǽ�����㤯�ʤ�ޤ������Ȥ��С�
eval(cgi["foo"][0])��SecurityError�ˤʤ�ޤ���

������mod_ruby�Ǥ�ʣ���Υ�����ץȤ���Ĥ�Ruby���󥿥ץ꥿�����Ѥ��뤿�ᡢ
���륹����ץȤ��������Х�ʾ��֤��ѹ�����ȡ�¾�Υ�����ץȤˤ�ƶ���
�ڤӤޤ���
�������äơ�ISP�ʤɤǿ���Ǥ��ʤ�������¿���Υ桼����mod_ruby�λ��Ѥ�
�����褦�ʤ��Ȥ��򤱤Ƥ���������

[((<�ܼ������|mod_ruby FAQ>))]

== �Ť������򤹤륹����ץȤˤ���̤�����ޤ���?

�Ť������򤹤�(�¹Ի��֤�Ĺ��)������ץȤǤϵ�ư�ˤ����륳���Ȥ�
����Ū�˾������ʤ뤿�ᡢmod_ruby�ˤ��ץ��������������Ȥκ︺��
���̤Ϥ��ޤ�ʤ��ΤǤϤʤ������ȹͤ���ͤ⤤�뤫�⤷��ޤ���

���������ƥ��ȷ�̤ˤ��ȡ��ºݤˤϤ��Τ褦�ʥ�����ץȤǤ⡢�ä�
����ٻ����礭�ʸ��̤����뤳�Ȥ���ǧ����Ƥ��ޤ���
����ϡ�mod_ruby�Ǥϼ¹Ԥ����ץ��������������˸��뤿�ᡢ������
�ޥ���ؤ���٤��ڸ�����뤿����ȹͤ����ޤ���

[((<�ܼ������|mod_ruby FAQ>))]

== Windows��ư���ޤ���?

���(�����ˤ�)Windows�ޥ������äƤ��ʤ��Τǡ��ޤ�ư���ޤ���

Apache 2.0�򥵥ݡ��Ȥ���褦�ˤʤä���ư�����⤷��ޤ���

[((<�ܼ������|mod_ruby FAQ>))]

== LoadModule��ȿ�Ǥ���ޤ���

httpd.conf��ClearModuleList�����Ҥ���Ƥ�����ϡ�����ʹߤ�
�ʲ��Τ褦�˵��Ҥ���ɬ�פ�����ޤ���

  AddModule mod_ruby.c

[((<�ܼ������|mod_ruby FAQ>))]

== �ʤ�Content-Type���֥饦����ɽ�������ΤǤ���?

���Υ�����ץȤ�mod_ruby��Ǥ�������ư��ޤ���

  print "Content-Type: text/plain\r\n\r\n"
  print "hello world"

�����mod_ruby��NPH-CGI�Ǥ��ꡢHTTP���ơ������饤���
���Ϥ��ʤ�����Ǥ���
���Τ褦�˼�ʬ��HTTP���ơ������饤�����Ϥ���ɬ�פ�
����ޤ���

  print "HTTP/1.1 200 OK\r\n"
  print "Content-Type: text/plain\r\n\r\n"
  print "hello world"

���뤤��cgi.rb�����Ѥ��뤳�Ȥ�Ǥ��ޤ���

  require "cgi"
  
  cgi = CGI.new
  print cgi.header("type"=>"text/plain")
  print "hello world"

���Υ�����ץȤ��������Τ�Τ��褤�Ǥ��礦��

[((<�ܼ������|mod_ruby FAQ>))]

== �饤�֥����ѹ���ȿ�Ǥ���ʤ��ΤǤ���?

mod_ruby�Ǥ�ʣ���Υ�����ץȤǰ�Ĥ�Ruby���󥿥ץ꥿��ͭ���ޤ���
(({require 'foo'}))��¹Ԥ�����硢�饤�֥�꤬�����ɤ����Τ�
�ǽ�ΰ������ʤΤǡ����θ�(({require 'foo'}))��¹Ԥ��Ƥ�
�饤�֥�꤬�Ƥӥ����ɤ���뤳�ȤϤ���ޤ���

  # apachectl stop
  # apachectl start

�Ȥ��ơ�Apache��Ƶ�ư���뤫���ǥХå����(({require}))������
(({load}))��ȤäƤ���������

[((<�ܼ������|mod_ruby FAQ>))]

== SecurityError��ȯ�����ޤ���

mod_ruby�Ǥϥǥե���Ȥ�(({$SAFE}))���ͤ�(({1}))�ˤʤ뤿�ᡢ
�������줿ʸ����Ǵ���������Ԥ���SecurityError��ȯ�����ޤ���
�����������Ǥʤ���ʬ���äƤ�����ϡ�(({untaint}))��
�������줿ʸ�����������Ƥ�뤳�Ȥ�SecurityError�����Ǥ��ޤ���

  query = CGI.new
  filename = query.params["filename"][0].dup
  filename.untaint
  file = open(filename)

���Ѱդ�(({untaint}))�ϥ������ƥ��ۡ�����äƤ��ޤ���ǽ����
����Τǡ���ʬ���դ��Ƥ���������

[((<�ܼ������|mod_ruby FAQ>))]

== Location�إå�����Ϥ��Ƥ��꤯ư���ޤ���

HTTP���ơ������饤���200 OK���֤�(�ǥե���Ȥ�ư��)�ȡ�
Location�إå���Ϳ���Ƥ⤽��URL�˥����פ��Ƥ���ޤ���

  r = Apache.request
  r.status_line = "302 Found"
  r.headers_out["Location"] = "http://www.modruby.net/"
  r.content_type = "text/html; charset=iso-8859-1"
  r.send_http_header
  print "<html><body><h1>302 Found</h1></body></html>"

�Τ褦�˥��ơ������饤�����ꤹ�뤫��

  r = Apache.request
  r.headers_out["Location"] = "http://www.modruby.net/"
  exit Apache::REDIRECT

�Τ褦�˽�λ���ơ����������ꤷ�Ƥ���������

[((<�ܼ������|mod_ruby FAQ>))]

== CGI::Session����꤯ư���ޤ���

mod_ruby�Ǥ�CGI::Session�ϼ�ưŪ�˥�����������ޤ���
�������ä�����Ū�˥����������Ƥ��ɬ�פ�����ޤ���

  session = CGI::Session.new(...)
  begin
    ...
  ensure
    session.close
  end

���������CGI::Session��ͭ�Τ�ΤǤϤ���ޤ���
�ե�����ʤɤ�Ʊ�ͤ˥�����������ɬ�פ�����ޤ���

[((<�ܼ������|mod_ruby FAQ>))]

== �ʤ������顼���Фޤ���

������ץȤΥХ��ʤɤǥ��󥿥ץ꥿�ξ��֤����������ʤ�ȡ����θ��
������ץȤμ¹Ԥ����꤬�Ф��ǽ��������ޤ���
���Τ褦�ʾ���Apache��Ƶ�ư���Ƥ���������

[((<�ܼ������|mod_ruby FAQ>))]

== Apache������ޤ���

Ruby�Υ���ѥ����egcs-1.1.2��ȤäƤ����硢Apache��Segmentation Fault��
������������ޤ���
���ξ�硢Ruby�κǿ���(1.6.2�ʹ�)�ǻ�ƤߤƤ���������

����ʳ��ξ����������Ϻ�Ԥ�((<���Ľ���|URL:mailto:shugo@modruby.net>))
����𤷤Ƥ���������Ȥ��꤬�����Ǥ���

[((<�ܼ������|mod_ruby FAQ>))]

== (({apachectl restart}))�ǥ���꡼�����ޤ���

������Ruby��API�Ǥϥ��󥿥ץ꥿��malloc()���������free()������ˡ���ʤ����ᡢ
apachectl restart��¹Ԥ��뤿�Ӥˡ�Apache�����Ѥ�����꤬�����Ƥ��äƤ��ޤ��ޤ���

���̡�

  # apachectl stop
  # apachectl start

�Τ褦�ˡ�Apache�򤤤ä�����ߤ����Ƥ��顢�Ƥӵ�ư����褦�ˤ��Ƥ���������

[((<�ܼ������|mod_ruby FAQ>))]

== libruby.so��liberuby.so�����Ĥ���ޤ���

�����餯��libruby.so�����󥹥ȡ��뤵�줿��꤬���¹Ի��Υ饤�֥���
�����ѥ��ˡ��ޤޤ�Ƥ��ޤ���

¿����Linux�ǥ����ȥ�ӥ塼�����Ǥϡ�/usr/local/lib�ϼ¹Ի��Υ饤�֥���
�����ѥ��˴ޤޤ�ޤ���
mod_ruby��/usr/local�ʲ��˥��󥹥ȡ��뤹����ϡ����Τ褦�ʹԤ�
/etc/ld.so.conf���ɲä���ldconfig��¹Ԥ��Ƥ���������

  /usr/local/lib

[((<�ܼ������|mod_ruby FAQ>))]

== ��¸�Υ��饹�������Ǥ��ޤ���

mod_ruby������ץ����ľ�ܴ�¸�Υ��饹���������뤳�ȤϤǤ��ޤ���
(���ˡ����������饹���������ޤ���)
�ʤ��ʤ顢mod_ruby������ץȤ�Kernel#load(filename, true)�ˤ�ä�
�����ɤ���뤫��Ǥ���

��¸�Υ��饹����������ɬ�פ�������ϡ��饤�֥�����Ǻ������Ԥ���
mod_ruby������ץȤ��餽�Υ饤�֥���require����褦�ˤ��Ƥ���������

[((<�ܼ������|mod_ruby FAQ>))]

=end