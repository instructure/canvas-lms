RailsXss
========

This plugin replaces the default ERB template handlers with erubis, and switches the behaviour to escape by default rather than requiring you to escape.  This is consistent with the behaviour in Rails 3.0.

Strings now have a notion of "html safe",  which is false by default.  Whenever rails copies a string into the response body it checks whether or not the string is safe, safe strings are copied verbatim into the response body, but unsafe strings are escaped first.  

All the XSS-proof helpers like link_to and form_tag now return safe strings, and will continue to work unmodified.  If you have your own helpers which return strings you *know* are safe,  you will need to explicitly tell rails that they're safe.  For an example, take the following helper.

    
    def some_helper
      (1..5).map do |i|
        "<li>#{i}</li>"
      end.join("\n")
    end

With this plugin installed, the html will be escaped.  So you will need to do one of the following:

1) Use the raw helper in your template.  raw will ensure that your string is copied verbatim into the response body.

    <%= raw some_helper %>

2) Mark the string as safe in the helper itself:

    def some_helper
      (1..5).map do |i|
        "<li>#{i}</li>"
      end.join("\n").html_safe
    end
  
3) Use the safe_helper meta programming method:

    module ApplicationHelper
      def some_helper
        #...
      end
      safe_helper :some_helper
    end  

Example
-------

BEFORE:

    <%= params[:own_me] %>        => XSS attack
    <%=h params[:own_me] %>       => No XSS
    <%= @blog_post.content %>     => Displays the HTML
                                
AFTER:                          

    <%= params[:own_me] %>        => No XSS 
    <%=h params[:own_me] %>       => No XSS (same result)
    <%= @blog_post.content %>     => *escapes* the HTML
    <%= raw @blog_post.content %> => Displays the HTML
  
  
Gotchas
---

#### textilize and simple_format do *not* return safe strings

Both these methods support arbitrary HTML and are *not* safe to embed directly in your document.  You'll need to do something like:

    <%= sanitize(textilize(@blog_post.content_textile)) %>

#### Safe strings aren't magic.

Once a string has been marked as safe, the only operations which will maintain that HTML safety are String#<<, String#concat and String#+.  All other operations are safety ignorant so it's still probably possible to break your app if you're doing something like

    value = something_safe
    value.gsub!(/a/, params[:own_me])

Don't do that.

#### String interpolation won't be safe, even when it 'should' be

    value = "#{something_safe}#{something_else_safe}"
    value.html_safe? # => false
  
This is intended functionality and can't be fixed.

Getting Started
===============

1. Install rails 2.3.8 or higher, or freeze rails from 2-3-stable.
2. Install erubis (gem install erubis)
3. Install this plugin (ruby script/plugin install git://github.com/rails/rails_xss.git)
4. Report anything that breaks.

Copyright (c) 2009 Koziarski Software Ltd, released under the MIT license. For full details see MIT-LICENSE included in this distribution.
