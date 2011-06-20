StringMaster
======

*Most common string manipulations for a webapp*

Why bother?
-----------------------
Because every time I create a new webapp, I think about how I should process user-generated content. Should convert urls to links and images? Should I allow certain tags? Should I convert all new lines to &lt;br/&gt; tags? Well, now all that is as simple as calling a single method.

INSTALLATION
------------

1. gem install string_master
2. gem install ultraviolet (optional, if you want code highliting feature, only works in ruby 1.8.x)

Usage
---------------

Say you got this string

    s = "Hello, glorious owner of the website\nI hope <b>you</b> like my message"

Oh my god, what am I going to do with it?

    # try this
    s.prep.newlines_to_br.html_escape
    # which is equivalent to this (block notation)
    s.prep { |s| s.newlines_to_br; s.html_escape }


Result:

    Hello, glorious owner of the website
    I hope &lt;you&gt; like my message

Fuck yeah.

More
---------------
Please read RDoc to see all of the available methods of StringMaster class: http://rdoc.info/github/snitko/string_master/master/StringMaster
