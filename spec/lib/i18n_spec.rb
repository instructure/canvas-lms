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

describe I18n do
  context "html safety" do
    it "should not return a SafeBuffer if no SafeBuffers are interpolated" do
      translation = I18n.t(:foo, "I want %{number} widgets from %{company}", :number => 2, :company => "Acme Co.")
      # even though Fixnum is html_safe, that shouldn't trigger our html_safe
      # fu (since we don't necessarily want things html-escaped)
      translation.html_safe?.should be_false
      translation.should eql("I want 2 widgets from Acme Co.")
    end

    it "should return a SafeBuffer if a SafeBuffer is interpolated" do
      translation = I18n.t(:foo, "I want %{text_field} widgets", :text_field => "<input>".html_safe)
      translation.html_safe?.should be_true
      translation.should eql("I want <input> widgets")
    end

    it "should html_escape the translation if a SafeBuffer is interpolated" do
      translation = I18n.t(:foo, "If you create an <input> tag, you will see %{text_field}", :text_field => "<input>".html_safe)
      translation.html_safe?.should be_true
      translation.should eql("If you create an &lt;input&gt; tag, you will see <input>")
    end

    it "should html_escape unsafe interpolated variables if a SafeBuffer is interpolated" do
      translation = I18n.t(:foo, "If you create an %{unsafe_tag} tag, you will see %{tag}", :unsafe_tag => "<input>", :tag => "<input>".html_safe)
      translation.html_safe?.should be_true
      translation.should eql("If you create an &lt;input&gt; tag, you will see <input>")
    end

    it "should apply :wrapper" do
      translation = I18n.t(:foo, "This is *important*", :wrapper => '<em class="super-important">\1</em>')
      translation.html_safe?.should be_true
      translation.should == %{This is <em class="super-important">important</em>}
    end

    it "should apply :wrappers" do
      translation = I18n.t(:foo, 'User *%{firstname}* #%{lastname}#', :wrapper => { '*' => '<span class="firstname">\1</span>', '#' => '<span class="lastname">\1</span>' }, :firstname => "User", :lastname => "Amp&Name")
      translation.html_safe?.should be_true
      translation.should == %{User <span class="firstname">User</span> <span class="lastname">Amp&amp;Name</span>}
    end

    it "should apply all duplicate wrappers" do
      translation = I18n.t(:foo, 'From *here* to *there*', :wrapper => '<span>\1</span>')
      translation.html_safe?.should be_true
      translation.should == %{From <span>here</span> to <span>there</span>}
    end

    it "should handle similar looking wrappers" do
      translation = I18n.t(:foo, 'From *here* to **there** and ***everywhere***',
                           :wrapper => { '*' => '<span class="1">\1</span>',
                               '**' => '<span class="2">\1</span>',
                               '***' => '<span class="3">\1</span>' })
      translation.html_safe?.should be_true
      translation.should == %{From <span class="1">here</span> to <span class="2">there</span> and <span class="3">everywhere</span>}
    end
  end

  context "pluralization" do
    it "should accept hashes for the default value" do
      I18n.t(:foo, {:one => "1 thing", :other => "%{count} things"}, :count => 1).
        should == "1 thing"
      I18n.t(:foo, {:one => "1 thing", :other => "%{count} things"}, :count => 2).
        should == "2 things"
    end

    it "should pluralize single-word default values" do
      I18n.t(:foo, "thing", :count => 1).
        should == "1 thing"
      I18n.t(:foo, "thing", :count => 2).
        should == "2 things"
    end

    it "should not pluralize multi-word default values" do
      I18n.t(:foo, "thing count: %{count}", :count => 1).
        should == "thing count: 1"
      I18n.t(:foo, "thing count: %{count}", :count => 2).
        should == "thing count: 2"
    end
  end

  context "_core_en.js" do
    it "should be up-to-date" do
      pending('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
      translations = {'en' => I18n.backend.direct_lookup('en').slice(*I18nTasks::Utils::CORE_KEYS)}

      # HINT: if this spec fails, run `rake i18n:generate_js`...
      # it probably means you added a format or a new language
      File.read('public/javascripts/translations/_core_en.js').should ==
          I18nTasks::Utils.dump_js(translations)
    end
  end

  context "interpolation" do
    before { I18n.locale = I18n.default_locale }
    after { I18n.locale = I18n.default_locale }

    it "should fall back to en if the current locale's interpolation is broken" do
      I18n.locale = :es
      I18n.backend.stub es: {__interpolation_test: "Hola %{mundo}"} do
        I18n.t(:__interpolation_test, "Hello %{mundo}", {mundo: "WORLD"}).
          should == "Hola WORLD"
        I18n.t(:__interpolation_test, "Hello %{world}", {world: "WORLD"}).
          should == "Hello WORLD"
      end
    end

    it "should raise an error if the the en interpolation is broken" do
      lambda {
        I18n.t(:__interpolation_test, "Hello %{world}", {foo: "bar"})
      }.should raise_error(I18n::MissingInterpolationArgument)
    end
  end
end
