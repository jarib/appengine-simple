Setup
=====

1. jruby -S gem install warbler sinatra
2. Download [Google App Engine SDK for Java][sdk] 
3. Add the <appengine-sdk>/bin dir to your PATH
4. Edit appengine-web.xml and add your app name in <application></application>

Dev server + deploy
======================

jruby -S rake appengine:server
jruby -S rake appengine:deploy EMAIL=<your email> PASSWORD=<your password>
  

Thanks
======

Thanks to Nick Sieger and http://jruby-rack.appspot.com/ for making this so easy!

[sdk]: http://code.google.com/appengine/downloads.html