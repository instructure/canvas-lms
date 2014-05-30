#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'spec_helper'

module I18nExtraction

  describe RubyExtractor do
    def extract(source, scope = 'asdf.', scope_results = true, in_html_view = false)
      sexps = RubyParser.new.parse(source)
      extractor = RubyExtractor.new
      extractor.scope = scope
      extractor.in_html_view = in_html_view
      extractor.process(sexps)
      (scope_results ?
          scope.split(/\./).inject(extractor.translations) { |hash, s| hash[s] } :
          extractor.translations) || {}
    end

    context "well-formedness" do
      it "should complain about missing arguments" do
        lambda { extract("t 'foo'") }.should raise_error /insufficient arguments for translate call/
      end
    end

    context "keys" do
      it "should allow string keys" do
        extract("t 'foo', \"Foo\"").should == {'foo' => "Foo"}
      end

      it "should allow symbol keys" do
        extract("t :foo, \"Foo\"").should == {'foo' => "Foo"}
      end

      it "should disallow everything else" do
        lambda { extract "t foo, \"Foo\"" }.should raise_error /invalid translation key/
        lambda { extract "t \"f\#{o}o\", \"Foo\"" }.should raise_error /invalid translation key/
        lambda { extract "t true ? :foo : :bar, \"Foo\"" }.should raise_error /invalid translation key/
      end
    end

    context "default translations" do
      it "should allow strings" do
        extract("t 'foo', \"Foo\"").should == {'foo' => "Foo"}
        extract("t 'foo2', <<-STR\nFoo\nSTR").should == {'foo2' => "Foo"}
        extract("t 'foo', 'F' + 'o' + 'o'").should == {'foo' => "Foo"}
      end

      it "should disallow everything else" do
        lambda { extract "t 'foo', \"F\#{o}o\"" }.should raise_error /invalid en default/
        lambda { extract "t 'foo', foo" }.should raise_error /invalid en default/
        lambda { extract "t 'foo', (true ? 'Foo' : 'Bar')" }.should raise_error /invalid en default/
      end
    end

    context "placeholders" do
      it "should ensure all placeholders have corresponding options" do
        lambda { extract "t 'foo', 'i have a %{foo}'" }.should raise_error(/interpolation value not provided for :foo/)
        extract("t 'foo', 'i have a %{foo}', :foo => 'foo'").should == {'foo' => 'i have a %{foo}'}
        lambda { extract "jt 'foo', 'i have a %{foo}', '{}'" }.should raise_error(/interpolation value not provided for :foo/)
        extract("jt 'foo', 'i have a %{foo}', '{foo: a_foo}'").should == {'foo' => 'i have a %{foo}'}
      end
    end

    context "pluralization" do
      it "should auto-pluralize single words + :count" do
        extract("t 'foo', 'Foo', :count => 1").should == {'foo' => {'one' => "1 Foo", 'other' => "%{count} Foos"}}
      end

      it "should not auto-pluralize other strings + :count" do
        extract("t 'foo', 'Foo foo', :count => 1").should == {'foo' => "Foo foo"}
      end

      it "should allow valid pluralization sub-keys" do
        extract("t 'foo', {:one => 'a foo', :other => 'some foos'}, :count => 1").should == {'foo' => {'one' => 'a foo', 'other' => 'some foos'}}
      end

      it "should complain if not all required pluralization sub-keys are provided" do
        lambda { extract("t 'foo', {:other => 'some foos'}, :count => 1") }.should raise_error(/not all required :count sub-key\(s\) provided/)
      end

      it "should reject invalid pluralization sub-keys" do
        lambda { extract "t 'foo', {:invalid => '%{count} Foo'}, :count => 1" }.should raise_error(/invalid :count sub-key\(s\)/)
      end
    end

    context "labels" do
      it "should interpret symbol names as the key" do
        extract("label :thing, :the_foo, :foo, :en => 'Foo'").should == {'labels' => {"foo" => "Foo"}}
        extract("f.label :the_foo, :foo, :en => 'Foo'").should == {'labels' => {"foo" => "Foo"}}
        extract("label_tag :the_foo, :foo, :en => 'Foo'").should == {'labels' => {"foo" => "Foo"}}
      end

      it "should infer the key from the method if not provided" do
        extract("label :thing, :the_foo, :en => 'Foo'").should == {'labels' => {"the_foo" => "Foo"}}
        extract("f.label :the_foo, :en => 'Foo'").should == {'labels' => {"the_foo" => "Foo"}}
        extract("label_tag :the_foo, :en => 'Foo'").should == {'labels' => {"the_foo" => "Foo"}}
      end

      it "should skip label calls with non-symbol keys (i.e. just a standard label)" do
        extract("label :thing, :the_foo, 'foo'").should == {}
        extract("f.label :the_foo, 'foo'").should == {}
        extract("label_tag :thing, 'foo'").should == {}
      end

      it "should complain if a label call has a non-symbol key and a default" do
        lambda { extract "label :thing, :the_foo, 'foo', :en => 'Foo'" }.should raise_error /invalid translation key/
        lambda { extract "f.label :the_foo, 'foo', :en => 'Foo'" }.should raise_error /invalid translation key/
        lambda { extract "label_tag :the_foo, 'foo', :en => 'Foo'" }.should raise_error /invalid translation key/
      end

      it "should not auto-scope absolute keys" do
        extract("label :thing, :the_foo, :'#foo', :en => 'Foo'", '').should == {"foo" => "Foo"}
        extract("f.label :the_foo, :'#foo', :en => 'Foo'", '').should == {"foo" => "Foo"}
        extract("label_tag :the_foo, :'#foo', :en => 'Foo'", '').should == {"foo" => "Foo"}
      end

      it "should complain if no default is provided" do
        lambda { extract "label :thing, :the_foo, :foo" }.should raise_error /invalid\/missing en default nil/
        lambda { extract "f.label :the_foo, :foo" }.should raise_error /invalid\/missing en default nil/
        lambda { extract "label_tag :the_foo, :foo" }.should raise_error /invalid\/missing en default nil/
      end
    end

    context "nesting" do
      it "should correctly evaluate i18n calls that are arguments to other (possibly) i18n calls" do
        extract("t :foo, 'Foo said \"%{bar}\"', :bar => t(:bar, 'Hello bar')").should == {'foo' => 'Foo said "%{bar}"', 'bar' => 'Hello bar'}
        extract("label :thing, :the_foo, t(:bar, 'Bar')").should == {'bar' => 'Bar'}
        extract("f.label :the_foo, t(:bar, 'Bar')").should == {'bar' => 'Bar'}
      end

      it "should ignore i18n calls within i18n method definitions" do
        extract("def t(*args); other.t *args; end").should == {}
      end
    end

    context "scoping" do
      it "should auto-scope relative keys to the current scope" do
        extract("t 'foo', 'Foo'", 'asdf.', false).should == {'asdf' => {'foo' => "Foo"}}
      end

      it "should not auto-scope absolute keys" do
        extract("t '#foo', 'Foo'", 'asdf.', false).should == {'foo' => "Foo"}
      end

      it "should not auto-scope keys with I18n as the receiver" do
        extract("I18n.t 'foo', 'Foo'", 'asdf.', false).should == {'foo' => 'Foo'}
      end

      it "should auto-scope plugin registration" do
        extract("Canvas::Plugin.register('dim_dim', :web_conferencing, {:name => lambda{ t :name, \"DimDim\" }})", '', false).should ==
            {'plugins' => {'dim_dim' => {'name' => "DimDim"}}}
      end

      it "should require explicit keys if there is no scope" do
        lambda { extract("t 'foo', 'Foo'", '') }.should raise_error /ambiguous translation key "foo"/
      end
    end

    context "collisions" do
      it "should not let you reuse a key" do
        lambda { extract "t 'foo', 'Foo'\nt 'foo', 'foo'" }.should raise_error 'cannot reuse key "asdf.foo"'
      end

      it "should not let you use a scope as a key" do
        lambda { extract "t 'foo.bar', 'bar'\nt 'foo', 'foo'" }.should raise_error '"asdf.foo" used as both a scope and a key'
      end

      it "should not let you use a key as a scope" do
        lambda { extract "t 'foo', 'foo'\nt 'foo.bar', 'bar'" }.should raise_error '"asdf.foo" used as both a scope and a key'
      end
    end

    context "whitespace" do
      it "should remove extraneous whitespace from view translate calls" do
        extract("t 'foo', \"\\n Foo \\t foo!\\n\"", 'asdf.', true, true).should == {'foo' => "Foo foo!"}
      end

      it "should strip whitespace from all other calls" do
        extract("t 'foo', \"\\n Foo \\t foo!\\n\"").should == {'foo' => "Foo \t foo!"}
        extract("mt 'foo', \"\\n Foo \\t foo!\\n\"").should == {'foo' => "Foo \t foo!"}
      end
    end

    context "sanitization" do
      it "should reject stuff that looks sufficiently html-y" do
        lambda { extract "t 'dude', 'this is <em>important</em>'" }.should raise_error /html tags on line 1/
      end

      it "should generally be ok with angle brackets" do
        extract("t 'obvious', 'TIL 1 < 2'").should == {'obvious' => 'TIL 1 < 2'}
        extract("t 'email', 'please enter an email, e.g. Joe User <joe@example.com>'").should == {'email' => 'please enter an email, e.g. Joe User <joe@example.com>'}
      end
    end
  end
end