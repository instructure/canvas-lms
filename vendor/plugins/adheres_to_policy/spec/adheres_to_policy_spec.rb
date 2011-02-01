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

require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), "/../lib/adheres_to_policy")

include ::Instructure::Adheres

describe Policy, "set_policy" do
  
  before(:all) do
    class AnotherModel
      extend Policy::ClassMethods
      adheres_to_policy
    end
  end
    
  it "should take a block" do
    lambda{ class AnotherModel
      set_policy { 1 + 1 }
    end }.should_not raise_error
  end
    
  after(:all) do
    Object.send(:remove_const, :AnotherModel)
  end
end

describe Policy::ClassMethods do
  it "should allow a class to extend itself via adheres_to_policy" do
    lambda{
      class A
        extend Policy::ClassMethods
        adheres_to_policy
      end
    }.should_not raise_error

    A.methods.should be_include("set_policy")
    A.methods.should be_include("set_permissions")
    
    a = A.new
    %w(policy check_policy grants_rights? has_rights?).each do |method|
      a.methods.should be_include(method)
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :A)
  end
end

describe Policy::SingletonMethods do
  before(:all) do
    class A
      extend Policy::ClassMethods
      adheres_to_policy
    end
  end
  
  it "should have policy_block available" do
    A.methods.should be_include("policy_block")
    A.methods.should be_include("policy_block=")
    A.policy_block = "Devlin Rocks!"
    A.policy_block.should eql("Devlin Rocks!")
  end
  
  it "should filter policy_block through a block filter with set_policy" do
    A.methods.should be_include("set_policy")
    lambda {A.set_policy(1)}.should raise_error
    b = lambda {1}
    lambda {A.set_policy(&b)}.should_not raise_error
    A.policy_block.should eql(b)
  end
  
  it "should use set_permissions as set_policy" do
    A.methods.should be_include("set_permissions")
    lambda {A.set_permissions(1)}.should raise_error
    b = lambda {1}
    lambda {A.set_permissions(&b)}.should_not raise_error
    A.policy_block.should eql(b)
  end

  after(:all) do
    Object.send(:remove_const, :A)
  end
end

describe Policy::InstanceMethods do
  before(:all) do
    class A
      attr_accessor :user
      extend Policy::ClassMethods
      adheres_to_policy
      set_policy do
        given { |user| self.user == user }
        set { can :read }
      end
    end
  end
  
  before(:each) do
    @a = A.new
  end
  
  it "should have setup a series of methods on the instance" do
    %w(policy check_policy grants_rights? has_rights?).each do |method|
      @a.methods.should be_include(method)
    end
  end
  
  it "should provide a Policy instance through policy" do
    @a.policy.should be_is_a(Policy)
  end
  
  it "should continue to use the same Policy instance (an important check, since this is also a constructor)" do
    @a.policy.should eql(@a.policy)
  end
  
  it "should be able to check a policy" do
    @a.user = 1
    @a.check_policy(1).should eql([:read])
  end
  
  after(:all) do
    Object.send(:remove_const, :A)
  end
end

# describe Policy::InstanceMethods do
#   
#   before(:all) do
#     class AnotherModel
#       extend Policy::ClassMethods
#       
#       set_policy do
#         given 1 do
#           can :read
#         end
#       end
#     end
#   end
# 
#   it "should make the policy available" do
#     AnotherModel.policy.should be_is_a(Policy)
#   end
#   
#   it "should have a policy" do
#     a = AnotherModel.new
#     a.policy.should eql(AnotherModel.policy)
#   end
#   
#   it "should be able to check a policy" do
#     a = AnotherModel.new
#     user = mock_model(User)
#     lambda{a.check_policy(user)}.should_not raise_error
#   end  
# 
#   after(:all) do
#     Object.send(:remove_const, :AnotherModel)
#   end
# end
# 
# describe Policy, "DSL" do
#     
#   it "should be able to extend another class" do
#     lambda{
#       class AModel
#         extend Policy::ClassMethods
#         set_policy do
#           given true do
#             can :read
#           end
#           given false do
#             can :write
#           end
#         end
#       end
#     }.should_not raise_error
#   end
#   
#   it "should record the permissions from the passing given statements" do
#     a = AModel.new
#     a.check_policy(mock_model(User)).should be_include(:read)
#   end
#   
#   it "should not record the permissions from the failing given statements" do
#     a = AModel.new
#     a.check_policy(mock_model(User)).should_not be_include(:write)
#   end
#   
#   it "should provide a can_bucket (things that can be done)" do
#     a = AModel.new
#     a.check_policy(mock_model(User))
#     a.policy.can_bucket.should eql([:read])
#   end
#   
#   it "should have hierarchal rules" do
#     class BModel
#       extend Policy::ClassMethods
#       set_policy do
#         given true do
#           can :read
#         end
#         given true do
#           cannot :read
#         end
#       end
#     end
# 
#     b = BModel.new
#     b.check_policy(mock_model(User)).should eql([])
#     Object.send(:remove_const, :BModel)
#   end
#   
#   after(:all) do
#     Object.send(:remove_const, :AModel)
#   end
# end
# 
# describe Policy, "scoping" do
#   class CModel
#     attr_accessor :x
#     extend Policy::ClassMethods
#     # set_policy do
#     #   given x == 1 do
#     #     can :read
#     #   end
#     # end
#   end
#   
#   it "should read the context of the local class" do
#     # c1 = CModel.new; c1.x = 0
#     # c2 = CModel.new; c2.x = 1
#     # c1.check_policy(mock_model(User)).should_not be_include?(:read)
#     # c2.check_policy(mock_model(User)).should_ be_include?(:read)
#   end
#   
#   after(:all) do
#     Object.send(:remove_const, :CModel)
#   end
# end
