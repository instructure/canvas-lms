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

describe Mailbox do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :purpose => "value for purpose",
      :content_parser => "value for content_parser",
      :mailboxable_entity_type => "Notification",
      :mailboxable_entity_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Mailbox.create!(@valid_attributes)
  end
  
  it "should have a useful state machine" do
    mailbox_model
    @m.state.should eql(:active)
    @m.deactivate
    @m.state.should eql(:inactive)
    @m.activate
    @m.state.should eql(:active)
    @m.terminate
    @m.state.should eql(:terminated)
    
    mailbox_model
    @m.deactivate
    @m.terminate
    @m.state.should eql(:terminated)
  end
  
  it "should derive the path from the handle" do
    mailbox_model
    @p = @m.path
    @m.handle.should_not be_nil
    @p.should match(Regexp.new(@m.handle + "@" + HostUrl.outgoing_email_domain))
  end
  
end

def mailbox_model(opts={})
  @m = Mailbox.create!(@valid_attributes.merge(opts))
end
