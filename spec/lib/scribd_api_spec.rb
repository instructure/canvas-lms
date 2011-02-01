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

describe ScribdAPI do
  # Shorthand
  def instance
    ScribdAPI.instance
  end

  before do
    Scribd::API.instance.stub!(:key=).and_return(true)
    Scribd::API.instance.stub!(:secret=).and_return(true)
    Scribd::User.stub!(:login).and_return(true)
  end
  
  it "should offer the same instance every time" do
    instance.should be_is_a(ScribdAPI)
    instance.should eql(instance)
  end
  
  it "should pass unknown calls down to the instance" do
    instance.stub!(:blah).and_return('found me')
    ScribdAPI.blah.should eql('found me')
  end
  
  it "should offer a Scribd::API for api" do
    instance.api.should be_is_a(Scribd::API)
  end
  
  it "should get the conversion status" do
    @doc = mock(:scribd_document)
    @doc.should_receive(:conversion_status).and_return(:status)
    Scribd::API.should_not_receive(:set_user)
    instance.get_status(@doc).should eql(:status)
  end
  
  it "should be able to upload a file" do
    Scribd::Document.should_receive(:upload).and_return('dispatched')
    ScribdAPI.upload('filename.txt', 'txt')
  end
  
  it "should only upload if the file actually exists" do
    Scribd::API.should_not_receive(:upload)
    ErrorLogging.should_receive(:log_error).and_return(true)
    ScribdAPI.upload('not_a_file')
  end
end
