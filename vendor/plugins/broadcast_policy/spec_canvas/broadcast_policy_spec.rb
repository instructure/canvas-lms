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

require File.expand_path(File.dirname(__FILE__) + '/../../../../spec/spec_helper')

describe Instructure::BroadcastPolicy, "set_broadcast_policy" do
  before(:each) do
    class AnotherModel
      class << self
        def before_save(obj)
          true
        end
        def after_save(obj)
          true
        end
      end
      extend Instructure::BroadcastPolicy::ClassMethods
    end
  end

  it "should include some instance methods when available" do
    a = AnotherModel.new
    a.should_not be_respond_to(:just_created)
    AnotherModel.send(:has_a_broadcast_policy)
    a.should be_respond_to(:just_created)
  end

  it "should allow multiple blocks" do
    foo = Canvas::MessageHelper.create_notification('Foo', 'Foo', 0, '', 'Foo')
    bar = Canvas::MessageHelper.create_notification('Bar', 'Bar', 0, '', 'Bar')

    class AnotherModel
      has_a_broadcast_policy

      set_broadcast_policy do
        dispatch :foo
        to       {}
        whenever {}
      end

      set_broadcast_policy do
        dispatch :bar
        to       {}
        whenever {}
      end
    end

    list = AnotherModel.broadcast_policy_list
    list.find_policy_for(foo).should be_present
    list.find_policy_for(bar).should be_present
  end
  # it "should require a block" do
  #   lambda{
  #     class AnotherModel
  #       set_broadcast_policy
  #     end
  #   }.should raise_error
  # 
  #   lambda{
  #     class AnotherModel
  #       set_broadcast_policy do
  #       end
  #     end
  #   }.should_not raise_error
  #   a = AnotherModel.new
  #   a.broadcast_policy.should_not be_nil
  # end
  # 
  # it "should set the notification" do
  #   class AnotherModel
  #     set_broadcast_policy do
  #       dispatch(:some_name)
  #     end
  #   end
  # 
  #   @n = mock('notifications')
  #   @n.should_receive(:find_by_name).and_return('implementing notification')
  #   @a = AnotherModel.new
  #   @a.stub!(:notifications).and_return(@n)
  #   @a.broadcast_policy
  #   @a.implementing_notification.should eql('implementing notification')
  #   
  # end
  # 
  # it "should set the to_list" do
  #   class AnotherModel
  #     set_broadcast_policy do
  #       to { [1,2,3] }
  #     end
  #   end
  #   
  #   @a = AnotherModel.new
  #   @a.broadcast_policy # Not typical
  #   @a.to_list.should eql([1,2,3])
  # end
  # 
  # it "should build a full broadcast policy" do
  #   class AnotherModel
  #     set_broadcast_policy do
  #       dispatch(:some_notification)
  #       to { [1,2,3] }
  #       whenever { |record| record.some_method }
  #     end
  #   end
  #   
  #   @n = mock('notifications')
  #   @n.should_receive(:find_by_name).and_return('implementing notification')
  #   @a = AnotherModel.new
  #   @a.stub!(:notifications).and_return(@n)
  #   @a.stub!(:some_method).and_return(true)
  #   @a.broadcast_policy
  #   @a.full_broadcast_policies.size.should eql(1)
  #   @a.full_broadcast_policies.first.should be_is_a(Policy::InstanceMethods::FullBroadcastPolicy)
  #   @a.full_broadcast_policies.first.notification.should eql('implementing notification')
  #   @a.full_broadcast_policies.first.to_list.should eql([1,2,3])
  #   @a.full_broadcast_policies.first.notification.should_receive(:create_message).and_return('useful message')
  #   @a.full_broadcast_policies.first.check_policy(@a)
  #   
  # end
  
  after(:each) do
    Object.send(:remove_const, :AnotherModel)
  end
  
end
