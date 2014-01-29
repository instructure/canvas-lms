h1. CanvasCrummy

This is a fork of an early version of the crummy gem.
http://rubygems.org/gems/crummy

TODO: use a more current version of the gem instead of this forked one

h2. Introduction

Crummy is a simple and tasty way to add breadcrumbs to your Rails applications.

h2. Install

The gem is hosted on gemcutter, so if you haven’t already, add it as a gem source:

<pre>
  <code>
    gem sources -a http://gemcutter.org/
  </code>
</pre>

Then install the Formtastic gem:

<pre>
  <code>
    gem install crummy
  </code>
</pre>

You can also install it as a Rails plugin:

<pre>
  <code>
    script/plugin install git://github.com/zachinglis/crummy.git
  </code>
</pre>

h2. Example

In your controllers you may add_crumb either like a before_filter or within a method (It is also available to views).

<pre>
  <code>
    class ApplicationController
      add_crumb "Home", '/'
    end
    
    class BusinessController < ApplicationController
      add_crumb("Businesses") { |instance| instance.send :businesses_path }
      add_crumb("Comments", :only => "comments") { |instance| instance.send :businesses_comments_path }
      before_filter :load_comment, :only => "show"
      add_crumb :comment, :only => "show"
  
      def show
        add_crumb @business.display_name, @business
      end
      
      def load_comment
        @comment = Comment.find(params[:id])
      end
    end
  </code>
</pre>

Then in your view:

<pre>
  <code>
    <%= render_crumbs %>
  </code>
</pre>

h2. Options for render_crumb_

render_crumbs renders the list of crumbs as either html or xml

It takes 3 options

The output format. Can either be :xml or :html. Defaults to :html

<code>:format => (:html|:xml)</code>

The seperator text. It does not assume you want spaces on either side so you must specify. Defaults to <code>&raquo;</code> for :html and <code><crumb></code> for :xml

<code>:seperator => string</code>

Render links in the output. Defaults to +true+

<code>:link => boolean</code>        

h3. Examples

<pre>
 <code>
  render_crumbs                     #=> <a href="/">Home</a> &raquo; <a href="/businesses">Businesses</a>
  render_crumbs :seperator => ' | ' #=> <a href="/">Home</a> | <a href="/businesses">Businesses</a>
  render_crumbs :format => :xml     #=> <crumb href="/">Home</crumb><crumb href="/businesses">Businesses</crumb>
 </code>
</pre>
A crumb with a nil link will just output plain text.

h2. Notes

The variable set is set to @_crumbs as to not conflict with your code.

h2. Todo

* Port over rspecs from project to plugin (Fully tested in a project)
* Accept instances of models as a single argument
* Allow for variables in names. (The workaround is to do your own before_filter for that currently)

h2. Credits

* "Zach Inglis":http://zachinglis.com
* "Rein Henrichs":http://reinh.com
* "Les Hill":http://blog.leshill.org/
* "Sandro Turriate":http://turriate.com/
* "Przemysław Kowalczyk":http://szeryf.wordpress.com/2008/06/13/easy-and-flexible-breadcrumbs-for-rails/ - feature ideas

*Copyright (c) 2008 Zach Inglis, released under the MIT license*
