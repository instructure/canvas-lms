# encoding: UTF-8
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

module HandlebarsTasks
  
  describe Handlebars do

    context "i18n" do

      it "should convert translate helper blocks to inline calls" do
        Handlebars.prepare_i18n('{{#t "test"}}this is a test of {{foo}}{{/t}}', 'test')[:content].
            should eql('{{{t "test" "this is a test of %{foo}" scope="test"}}}')
      end

      it "should flag triple-stashed interpolation variables as safe" do
        Handlebars.prepare_i18n('{{#t "pizza"}}give me {{{input}}} pizzas{{/t}}', 'test')[:content].
            should eql('{{{t "pizza" "give me %h{input} pizzas" scope="test"}}}')
      end

      it "should extract wrappers" do
        Handlebars.prepare_i18n('{{#t "test"}}<b>{{person}}</b> is <b>so</b> <b title="{{definition}}"><i>cool</i></b>{{/t}}', 'test')[:content].
            should eql('{{{t "test" "*%{person}* is *so* **cool**" scope="test" w0="<b>$1</b>" w1="<b title=\\"%{definition}\\"><i>$1</i></b>"}}}')
      end

      it "should remove extraneous whitespace from the translation and wrappers" do
        Handlebars.prepare_i18n(<<-HBS, 'test')[:content].strip.
          {{#t "test"}}
            <b>
              ohai
            </b>
          {{/t}}
        HBS
          should eql('{{{t "test" "*ohai *" scope="test" w0="<b> $1</b>"}}}')
      end

      it "should not allow nested helper calls" do
        lambda {
          Handlebars.prepare_i18n('{{#t "test"}}{{call a helper}}{{/t}}', 'test')
        }.should raise_error
      end

      it "should fix up the scope" do
        Handlebars.scopify('_test').should == "test"
        Handlebars.scopify('test/test').should == "test.test"
        Handlebars.scopify('test/_this_is-a_test').should == "test.this_is_a_test"
        Handlebars.scopify('test/_andThisIsATest').should == "test.and_this_is_a_test"
      end

    end

  end
end