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

describe CommunicationChannel do
  before(:each) do
    @pseudonym = mock('Pseudonym')
    @pseudonym.stubs(:destroyed?).returns(false)
    Pseudonym.stubs(:find_by_user_id).returns(@pseudonym)
  end

  it "should create a new instance given valid attributes" do
    factory_with_protected_attributes(CommunicationChannel, communication_channel_valid_attributes)
  end

  describe 'imported?' do
    it 'should default to false' do
      CommunicationChannel.new.should_not be_imported
    end

    it 'should be false if the channel has no pseudonym' do
      communication_channel_model
      @communication_channel.should_not be_imported
    end

    it 'should be false if the channel is associated with a pseudonym' do
      user_with_pseudonym(:active_all => true)
      channel = @pseudonym.communication_channel

      channel.should_not be_imported
    end

    it "should be true if the channel is the sis_communication_channel of a pseudonym" do
      user_with_pseudonym(:active_all => true)
      channel = @pseudonym.communication_channel
      @pseudonym.update_attribute(:sis_communication_channel_id, channel.id)

      channel.should be_imported
    end
  end

  it "should have a decent state machine" do
    communication_channel_model
    @cc.state.should eql(:unconfirmed)
    @cc.confirm
    @cc.state.should eql(:active)
    @cc.retire
    @cc.state.should eql(:retired)
    @cc.re_activate
    @cc.state.should eql(:active)
    
    communication_channel_model(:path => "another_path@example.com")
    @cc.state.should eql(:unconfirmed)
    @cc.retire
    @cc.state.should eql(:retired)
    @cc.re_activate
    @cc.state.should eql(:active)
  end
  
  it "should reset the bounce count when re_activating" do
    communication_channel_model
    @cc.bounce_count = 1
    @cc.confirm
    @cc.bounce_count.should eql(1)
    @cc.retire
    @cc.re_activate
    @cc.bounce_count.should eql(0)
  end
  
  it "should retire the communication channel if it's been bounced 5 times" do
    communication_channel_model
    @cc.bounce_count = 5
    @cc.state.should eql(:unconfirmed)
    @cc.save
    @cc.state.should eql(:retired)
    
    communication_channel_model
    @cc.bounce_count = 4
    @cc.save
    @cc.state.should eql(:unconfirmed)

    communication_channel_model
    @cc.bounce_count = 6
    @cc.save
    @cc.state.should eql(:retired)
  end
  
  it "should set a confirmation code unless one has been set" do
    CanvasSlug.expects(:generate).at_least(1).returns('abc123')
    communication_channel_model
    @cc.confirmation_code.should eql('abc123')
  end
  
  it "should be able to reset a confirmation code" do
    communication_channel_model
    old_cc = @cc.confirmation_code
    @cc.set_confirmation_code(true)
    @cc.confirmation_code.should_not eql(old_cc)
  end
  
  it "should use a 15-digit confirmation code for default or email path_type settings" do
    communication_channel_model
    @cc.path_type.should eql('email')
    @cc.confirmation_code.size.should eql(25)
  end
  
  it "should use a 4-digit confirmation_code for settings other than email" do
    communication_channel_model
    @cc.path_type = 'sms'
    @cc.set_confirmation_code(true)
    @cc.confirmation_code.size.should eql(4)
  end
  
  it "should default the path type to email" do
    communication_channel_model
    @cc.path_type.should eql('email')
  end
  
  it "should only allow email, or sms as path types" do
    communication_channel_model
    @cc.path_type = 'email'; @cc.save
    @cc.path_type.should eql('email')

    @cc.path_type = 'sms'; @cc.save
    @cc.path_type.should eql('sms')

    @cc.path_type = 'not valid'; @cc.save
    @cc.path_type.should eql('email')
  end
  
  it "should act as list" do
    CommunicationChannel.should be_respond_to(:acts_as_list)
  end
  
  it "should scope the list to the user" do
    @u1 = User.create!
    @u2 = User.create!
    @u1.should_not eql(@u2)
    @u1.id.should_not eql(@u2.id)
    @cc1 = @u1.communication_channels.create!(:path => 'jt@instructure.com')
    @cc2 = @u1.communication_channels.create!(:path => 'cody@instructure.com')
    @cc3 = @u2.communication_channels.create!(:path => 'brianp@instructure.com')
    @cc1.user.should eql(@u1)
    @cc2.user.should eql(@u1)
    @cc3.user.should eql(@u2)
    @cc1.user_id.should_not eql(@cc3.user_id)
    @cc2.position.should eql(2)
    @cc2.move_to_top
    @cc2.save
    @cc2.reload
    @cc2.position.should eql(1)
    @cc1.reload
    @cc1.position.should eql(2)
    @cc3.reload
    @cc3.position.should eql(1)
  end
  
  context "can_notify?" do
    it "should normally be able to be used" do
      communication_channel_model
      @communication_channel.should be_can_notify
    end
    
    it "should not be able to be used if it has a policy to not use it" do
      communication_channel_model
      notification_policy_model(:frequency => "never", :communication_channel => @communication_channel)
      @communication_channel.reload
      @communication_channel.should_not be_can_notify
    end
  end

  describe "by_email" do
    it "should return matching ccs case-insensitively" do
      @user = User.create!
      @cc = @user.communication_channels.create!(:path => 'user@example.com')
      @user.communication_channels.by_path('USER@EXAMPLE.COM').should == [@cc]
    end
  end

  it "should properly validate the uniqueness of path" do
    @user = User.create!
    @cc = @user.communication_channels.create!(:path => 'user1@example.com')
    # should allow a different address
    @user.communication_channels.create!(:path => 'user2@example.com')
    # should allow a different path_type
    @user.communication_channels.create!(:path => 'user1@example.com', :path_type => 'sms')
  end

  context "notifications" do
    it "should forward the root account to the message" do
      notification = Notification.create!(:name => 'Confirm Email Communication Channel', :category => 'Registration')
      @user = User.create!
      @user.register!
      @cc = @user.communication_channels.create!(:path => 'user1@example.com')
      account = Account.create!
      HostUrl.stubs(:context_host).with(account).returns('someserver.com')
      HostUrl.stubs(:context_host).with(nil).returns('default')
      @cc.send_confirmation!(account)
      message = Message.where(:communication_channel_id => @cc, :notification_id => notification).first
      message.should_not be_nil
      message.body.should match /someserver.com/
    end
  end

  it "should not allow deleting sms channels that are the otp channel" do
    user_with_pseudonym(:active_all => 1)
    @cc = @user.communication_channels.sms.create!(:path => 'bob')
    @cc.confirm!
    @user.otp_communication_channel = @cc
    @user.save!
    @cc.reload
    @cc.destroy.should be_false
    @cc.reload.should be_active
  end

  describe "merge candidates" do
    it "should return users with a matching e-mail address" do
      user1 = User.create!
      cc1 = user1.communication_channels.create!(:path => 'jt@instructure.com')

      user2 = User.create!
      cc2 = user2.communication_channels.create!(:path => 'jt@instructure.com')
      cc2.confirm!
      Account.default.pseudonyms.create!(:user => user2, :unique_id => 'user2')

      cc1.merge_candidates.should == [user2]
      cc1.has_merge_candidates?.should be_true
    end

    it "should not return users without an active pseudonym" do
      user1 = User.create!
      cc1 = user1.communication_channels.create!(:path => 'jt@instructure.com')

      user2 = User.create!
      cc2 = user2.communication_channels.create!(:path => 'jt@instructure.com')
      cc2.confirm!

      cc1.merge_candidates.should == []
      cc1.has_merge_candidates?.should be_false
    end

    it "should not return users that match on an unconfirmed cc" do
      user1 = User.create!
      cc1 = user1.communication_channels.create!(:path => 'jt@instructure.com')

      user2 = User.create!
      cc2 = user2.communication_channels.create!(:path => 'jt@instructure.com')
      Account.default.pseudonyms.create!(:user => user2, :unique_id => 'user2')

      cc1.merge_candidates.should == []
      cc1.has_merge_candidates?.should be_false
    end

    it "should only check one user for boolean result" do
      user1 = User.create!
      cc1 = user1.communication_channels.create!(:path => 'jt@instructure.com')

      user2 = User.create!
      cc2 = user2.communication_channels.create!(:path => 'jt@instructure.com')
      cc2.confirm!
      Account.default.pseudonyms.create!(:user => user2, :unique_id => 'user2')
      user3 = User.create!
      cc3 = user3.communication_channels.create!(:path => 'jt@instructure.com')
      cc3.confirm!
      Account.default.pseudonyms.create!(:user => user3, :unique_id => 'user3')

      User.any_instance.expects(:all_active_pseudonyms).once.returns([true])
      cc1.has_merge_candidates?.should be_true
    end

    context "sharding" do
      specs_require_sharding

      it "should find a match on another shard" do
        Enrollment.stubs(:cross_shard_invitations?).returns(true)
        user1 = User.create!
        cc1 = user1.communication_channels.create!(:path => 'jt@instructure.com')

        @shard1.activate do
          @user2 = User.create!
          cc2 = @user2.communication_channels.create!(:path => 'jt@instructure.com')
          cc2.confirm!
          account = Account.create!
          account.pseudonyms.create!(:user => @user2, :unique_id => 'user2')
        end

        pending if CommunicationChannel.associated_shards('jt@instructure.com') == [Shard.default]

        cc1.merge_candidates.should == [@user2]
        cc1.has_merge_candidates?.should be_true
      end

      it "should search a non-default shard *only*" do
        Enrollment.stubs(:cross_shard_invitations?).returns(false)
        user1 = User.create!
        cc1 = user1.communication_channels.create!(:path => 'jt@instructure.com')
        cc1.confirm!
        Account.default.pseudonyms.create!(:user => user1, :unique_id => 'user1')

        @shard1.activate do
          @user2 = User.create!
          @cc2 = @user2.communication_channels.create!(:path => 'jt@instructure.com')
          @cc2.confirm!
          account = Account.create!
          account.pseudonyms.create!(:user => @user2, :unique_id => 'user2')
        end

        cc1.merge_candidates.should == []
        @cc2.merge_candidates.should == []
      end
    end
  end
end
