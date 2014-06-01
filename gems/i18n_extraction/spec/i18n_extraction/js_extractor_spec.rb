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

  describe JsExtractor do
    def extract(source, scope = 'asdf', options = {})
      scope_results = scope && (options.has_key?(:scope_results) ? options.delete(:scope_results) : true)

      extractor = JsExtractor.new
      source = "require(['i18n!#{scope}'], function(I18n) {\n#{source.gsub(/^/, '  ')}\n});" if scope
      extractor.process(source, options)
      (scope_results ?
          scope.split(/\./).inject(extractor.translations) { |hash, s| hash[s] } :
          extractor.translations) || {}
    end

    context "keys" do
      it "should allow valid string keys" do
        extract("I18n.t('foo', \"Foo\")").should == {'foo' => "Foo"}
      end

      it "should disallow everything else" do
        lambda { extract "I18n.t(foo, \"Foo\")" }.should raise_error /invalid key/
        lambda { extract "I18n.t('f' + 'o' + 'o', \"Foo\"" }.should raise_error /unable to "parse" I18n call/
        lambda { extract "I18n.t('f o o', \"Foo\"" }.should raise_error /unable to "parse" I18n call/
      end
    end

    context "default translations" do
      it "should allow strings" do
        extract("I18n.t('foo', \"Foo\")").should == {'foo' => "Foo"}
        extract("I18n.t('foo', 'F' +\n'o' +\n'o')").should == {'foo' => "Foo"}
      end

      it "should disallow everything else" do
        lambda { extract "I18n.t('foo', foo)" }.should raise_error /unable to "parse" I18n call/
        lambda { extract "I18n.t('foo', I18n.t('bar', 'bar'))" }.should raise_error /unable to "parse" I18n call/
      end

      it "should complain if there is no default" do
        lambda { extract("I18n.t('foo')") }.should raise_error(/no default provided for "asdf.foo"/)
      end

      it "should skip t for core translations with no defaults" do
        extract("I18n.t('#date.month_names')", 'asdf', :scope_results => false).should == {}
      end
    end

    context "placeholders" do
      it "should ensure all placeholders have corresponding options" do
        lambda { extract "I18n.t('foo', 'i have a %{foo}')" }.should raise_error(/interpolation value not provided for :foo/)
      end
    end

    context "pluralization" do
      it "should auto-pluralize single words + :count" do
        extract("I18n.t('foo', 'Foo', {count: 1})").should == {'foo' => {'one' => "1 Foo", 'other' => "%{count} Foos"}}
      end

      it "should not auto-pluralize other strings + :count" do
        extract("I18n.t('foo', 'Foo foo', {count: 1})").should == {'foo' => "Foo foo"}
      end

      it "should allow valid pluralization sub-keys" do
        extract("I18n.t('foo', {one: 'a foo', other: 'some foos'}, {count: 1})").should == {'foo' => {'one' => 'a foo', 'other' => 'some foos'}}
      end

      it "should complain if not all required pluralization sub-keys are provided" do
        lambda { extract("I18n.t('foo', {other: 'some foos'}, {count: 1})") }.should raise_error(/not all required :count sub-key\(s\) provided/)
      end

      it "should reject invalid pluralization sub-keys" do
        lambda { extract "I18n.t('foo', {invalid: '%{count} Foo'}, {count: 1})" }.should raise_error(/invalid :count sub-key\(s\):/)
      end
    end

    context "nesting" do
      it "should correctly evaluate i18n calls that are arguments to other (possibly) i18n calls" do
        extract("I18n.t('foo', 'Foo said \"%{bar}\"', {bar: I18n.t('bar', 'Hello bar')})").should == {'foo' => 'Foo said "%{bar}"', 'bar' => 'Hello bar'}
      end
    end

    context "scoping" do
      it "should correctly infer the scope" do
        extract(<<-SOURCE, nil).should == {'asdf' => {'bar' => 'Bar'}}
        define('bar',
        ['foo',
         'i18n!asdf'
        ], function(Foo, I18n) {
          I18n.t('bar', 'Bar');
        });
        SOURCE
      end

      it "should require a scope for all I18n calls" do
        lambda { extract(<<-SOURCE, nil) }.should raise_error /possibly unscoped I18n call on line 2/
        require(['i18n'], function(I18n) {
          I18n.t('bar', 'Bar');
        });
        SOURCE

        lambda { extract(<<-SOURCE, nil) }.should raise_error /possibly unscoped I18n call on line 1/
        I18n.t('bar', 'Bar');
        SOURCE
      end

      it "should auto-scope relative keys to the current scope" do
        extract("I18n.t('foo', 'Foo')", 'asdf', :scope_results => false).should == {'asdf' => {'foo' => "Foo"}}
      end

      it "should not auto-scope absolute keys" do
        extract("I18n.t('#foo', 'Foo')", 'asdf', :scope_results => false).should == {'foo' => "Foo"}
      end

      it "should not allow multiple scopes" do
        lambda { extract(<<-SOURCE, nil) }.should raise_error /multiple scopes are not allowed/
        require(['i18n!asdf'], function(I18n) {
          I18n.t('bar', 'Bar');
        });
        require(['i18n!qwerty'], function(I18n) {
          I18n.t('lol', 'Wut');
        });
        SOURCE
      end
    end

    context "collisions" do
      it "should not let you reuse a key" do
        lambda { extract "I18n.t('foo', 'Foo')\nI18n.t('foo', 'foo')" }.should raise_error 'cannot reuse key "asdf.foo"'
      end

      it "should not let you use a scope as a key" do
        lambda { extract "I18n.t('foo.bar', 'bar')\nI18n.t('foo', 'foo')" }.should raise_error '"asdf.foo" used as both a scope and a key'
      end

      it "should not let you use a key as a scope" do
        lambda { extract "I18n.t('foo', 'foo')\nI18n.t('foo.bar', 'bar')" }.should raise_error '"asdf.foo" used as both a scope and a key'
      end
    end

    context "erb" do
      it "should support jt and I18n.l calls" do
        extract(<<-SOURCE, nil, :erb => true).should eql({}) # doesn't actually extract it
        <% js_block do %>
          <script>
            require(['i18n'], function(I18n) {
              I18n.l('asdf', 'asdf')
              <%= jt('bar', 'Bar') %>
            });
          </script>
        <% end %>
        SOURCE
      end

      it "should not support the i18n AMD plugin" do
        lambda { extract(<<-SOURCE, nil, :erb => true) }.should raise_error "i18n amd plugin is not supported in js_blocks (line 3)"
        <% js_block do %>
          <script>
            require(['i18n!scope'], function(I18n) {
              <%= jt('bar', 'Bar') %>
            });
          </script>
        <% end %>
        SOURCE
      end

      it "should not allow jt calls outside of a require/define block" do
        lambda { extract(<<-SOURCE, nil, :erb => true) }.should raise_error /possibly unscoped jt call on line 3/
        <% js_block do %>
          <script>
            <%= jt('bar', 'Bar') %>
          </script>
        <% end %>
        SOURCE
      end

      it "should not allow raw I18n calls" do
        lambda { extract(<<-SOURCE, nil, :erb => true) }.should raise_error /raw I18n call on line 4/
        <% js_block do %>
          <script>
            require(['i18n'], function(I18n) {
              I18n.t('bar', 'Bar');
            });
          </script>
        <% end %>
        SOURCE
      end
    end
  end
end