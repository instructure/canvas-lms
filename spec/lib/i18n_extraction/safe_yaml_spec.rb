#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe I18nExtraction::SafeYAML do
  describe ".load" do
    before { YAML.send :include, I18nExtraction::SafeYAML }
    after { YAML.yolo! }

    it "should accept safe yaml" do
       ret = YAML.load <<-YML
         foo: 'bar'
         baz: 1
       YML
       ret.should == {'foo' => 'bar', 'baz' => 1}
    end

    it "should accept safe explicit types" do
       ret = YAML.load <<-YML
         !binary bG9sd3V0
       YML
       ret.should == 'lolwut'
    end

    it "should reject arbitrary explicit types" do
       ret = YAML.load <<-YML
         foo: 'bar'
         baz: !ruby/int 123
       YML
       ret.should == false

       ret = YAML.load <<-YML
         !who/knows pwn
       YML
       ret.should == false
    end

    it "should still work with io-ishes" do
       ret = YAML.load StringIO.new <<-YML
         foo: 'bar'
         baz: 1
       YML
       ret.should == {'foo' => 'bar', 'baz' => 1}
    end
  end
end
