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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

shared_examples_for "url validation tests" do

  def test_url_validation(model)
    # should add http://
    model.url = "example.com"
    model.save!
    model.errors.size.should == 0
    model.url.should == "http://example.com"

    # should remove whitespace
    model.url = "   example.com  "
    model.save!
    model.errors.size.should == 0
    model.url.should == "http://example.com"

    model.url = "   http://www.example.com  "
    model.save!
    model.errors.size.should == 0
    model.url.should == "http://www.example.com"

    # should not work on invalid urls
    ["/relativepath",
     "",
     "invalidscheme://www.example.com",
     "not a url"].each do |invalid_url|
      model.url = invalid_url
      saved = model.save
      [model.url, saved].should == [invalid_url, false]
      model.errors.size.should == 1
      model.errors.full_messages.join.should =~ /not a valid URL/
    end

    # should work on valid urls
    ["http://www.sub.test.example.tld./thing1?query#hash",
     "https://localhost/test/",
     "HTTP://localhost/test/",
     "http://192.168.24.205:1000",
     "http://user:password@host.tld:5555/path/to/thing",
     "http://user:password@host.tld/path/to/thing",
     "http://" + ("a"*300) + ".com",
     "http://www.example.com"].each do |valid_url|
      model.url = valid_url
      model.save!
      model.errors.size.should == 0
      model.url.should == valid_url
    end

    # should support nil urls
    model.url = nil
    model.save!
    model.errors.size.should == 0
    model.url.should be_nil
  end

end
