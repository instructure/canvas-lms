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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'i18n_extractor'

describe I18nJsExtractor do
  def extract(source, scope = 'asdf', options = {})
    scope_results = scope && (options.has_key?(:scope_results) ? options.delete(:scope_results) : true)

    extractor = I18nJsExtractor.new
    source = "I18n.scoped('#{scope}', function(I18n) {\n#{source}\n});" if scope
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
      lambda{ extract "I18n.t(foo, \"Foo\")" }.should raise_error /unable to "parse" I18n call/
      lambda{ extract "I18n.t('f' + 'o' + 'o', \"Foo\"" }.should raise_error /unable to "parse" I18n call/
      lambda{ extract "I18n.t('f o o', \"Foo\"" }.should raise_error /unable to "parse" I18n call/
    end
  end

  context "default translations" do
    it "should allow strings" do
      extract("I18n.t('foo', \"Foo\")").should == {'foo' => "Foo"}
      extract("I18n.t('foo', 'F' +\n'o' +\n'o')").should == {'foo' => "Foo"}
    end

    it "should disallow everything else" do
      lambda{ extract "I18n.t('foo', foo)" }.should raise_error /unable to "parse" I18n call/
      lambda{ extract "I18n.t('foo', I18n.t('bar', 'bar'))" }.should raise_error /unable to "parse" I18n call/
    end

    it "should complain if there is no default" do
      lambda{ extract("I18n.t('foo')")}.should raise_error(/no default provided for "asdf.foo"/)
    end

    it "should skip t for core translations with no defaults" do
      extract("I18n.t('#date.month_names')", 'asdf', :scope_results => false).should == {}
    end
  end

  context "placeholders" do
    it "should ensure all placeholders have corresponding options" do
      lambda{ extract "I18n.t('foo', 'i have a %{foo}')" }.should raise_error(/interpolation value not provided for :foo/)
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

    it "should reject invalid pluralization sub-keys" do
      lambda{ extract "I18n.t('foo', {invalid: '%{count} Foo'}, {count: 1})" }.should raise_error(/invalid :count sub-key\(s\):/)
    end
  end

  context "nesting" do
    it "should correctly evaluate i18n calls that are arguments to other (possibly) i18n calls" do
      extract("I18n.t('foo', 'Foo said \"%{bar}\"', {bar: I18n.t('bar', 'Hello bar')})").should == {'foo' => 'Foo said "%{bar}"', 'bar' => 'Hello bar'}
    end
  end

  context "scoping" do
    it "should require a scope for all I18n calls" do
      lambda{ extract(<<-SOURCE, nil) }.should raise_error /possibly unscoped I18n call on line 4/
        I18n.scoped('asdf', function(I18n) {
          I18n.t('bar', 'Bar');
        });
        I18n.t('foo', 'Foo');
      SOURCE
    end

    it "should auto-scope relative keys to the current scope" do
      extract("I18n.t('foo', 'Foo')", 'asdf', :scope_results => false).should == {'asdf' => {'foo' => "Foo"}}
    end

    it "should not auto-scope absolute keys" do
      extract("I18n.t('#foo', 'Foo')", 'asdf', :scope_results => false).should == {'foo' => "Foo"}
    end
  end

  context "collisions" do
    it "should not let you reuse a key" do
      lambda{ extract "I18n.t('foo', 'Foo')\nI18n.t('foo', 'foo')" }.should raise_error 'cannot reuse key "asdf.foo"'
    end

    it "should not let you use a scope as a key" do
      lambda{ extract "I18n.t('foo.bar', 'bar')\nI18n.t('foo', 'foo')" }.should raise_error '"asdf.foo" used as both a scope and a key'
    end

    it "should not let you use a key as a scope" do
      lambda{ extract "I18n.t('foo', 'foo')\nI18n.t('foo.bar', 'bar')" }.should raise_error '"asdf.foo" used as both a scope and a key'
    end
  end

  context "erb" do
    it "should require an :i18n_scope" do
      lambda{ extract(<<-SOURCE, nil, :erb => true) }.should raise_error /possibly unscoped I18n call/
        <% js_block do %>
          <script>
          I18n.t('#bar', 'Bar');
          </script>
        <% end %>
      SOURCE

      extract(<<-SOURCE, nil, :erb => true).should == {'asdf' => {'bar' => 'Bar'}}
        <% js_block :i18n_scope => 'asdf' do %>
          <script>
          I18n.t('bar', 'Bar');
          </script>
        <% end %>
      SOURCE
    end

    it "should not allow scoped blocks" do
      lambda{ extract(<<-SOURCE, nil, :erb => true) }.should raise_error /scoped blocks are no longer supported in js_blocks/
        <% js_block do %>
          <script>
          I18n.scoped('asdf', function(I18n) {
            I18n.t('#bar', 'Bar');
          });
          </script>
        <% end %>
      SOURCE

      # even if you provide an :i18n_scope, you still can't do a scoped block
      lambda{ extract(<<-SOURCE, nil, :erb => true) }.should raise_error /scoped blocks are no longer supported in js_blocks/
        <% js_block :i18n_scope => 'asdf' do %>
          <script>
          I18n.scoped('qwerty', function(I18n) {
            I18n.t('#bar', 'Bar');
          });
          </script>
        <% end %>
      SOURCE
    end

    it "should not allow absolute keys" do
      lambda{ extract(<<-SOURCE, nil, :erb => true) }.should raise_error /absolute keys are not supported in this context/
        <% js_block :i18n_scope => 'asdf' do %>
          <script>
          I18n.t('#bar', 'Bar');
          </script>
        <% end %>
      SOURCE
    end

    it "should not allow erb in defaults" do
      lambda{ extract(<<-SOURCE, nil, :erb => true) }.should raise_error /erb cannot be used inside of default values/
        <% js_block :i18n_scope => 'asdf' do %>
          <script>
          I18n.t('bar', 'Bar <%= no_can_do %>');
          </script>
        <% end %>
      SOURCE
    end
  end
end
