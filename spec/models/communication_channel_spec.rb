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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

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
      expect(CommunicationChannel.new).not_to be_imported
    end

    it 'should be false if the channel has no pseudonym' do
      communication_channel_model
      expect(@communication_channel).not_to be_imported
    end

    it 'should be false if the channel is associated with a pseudonym' do
      user_with_pseudonym(:active_all => true)
      channel = @pseudonym.communication_channel

      expect(channel).not_to be_imported
    end

    it "should be true if the channel is the sis_communication_channel of a pseudonym" do
      user_with_pseudonym(:active_all => true)
      channel = @pseudonym.communication_channel
      @pseudonym.update_attribute(:sis_communication_channel_id, channel.id)

      expect(channel).to be_imported
    end
  end

  it "should have a decent state machine" do
    communication_channel_model
    expect(@cc.state).to eql(:unconfirmed)
    @cc.confirm
    expect(@cc.state).to eql(:active)
    @cc.retire
    expect(@cc.state).to eql(:retired)
    @cc.re_activate
    expect(@cc.state).to eql(:active)
    
    communication_channel_model(:path => "another_path@example.com")
    expect(@cc.state).to eql(:unconfirmed)
    @cc.retire
    expect(@cc.state).to eql(:retired)
    @cc.re_activate
    expect(@cc.state).to eql(:active)
  end
  
  it "should set a confirmation code unless one has been set" do
    CanvasSlug.expects(:generate).at_least(1).returns('abc123')
    communication_channel_model
    expect(@cc.confirmation_code).to eql('abc123')
  end
  
  it "should be able to reset a confirmation code" do
    communication_channel_model
    old_cc = @cc.confirmation_code
    @cc.set_confirmation_code(true)
    expect(@cc.confirmation_code).not_to eql(old_cc)
  end
  
  it "should use a 15-digit confirmation code for default or email path_type settings" do
    communication_channel_model
    expect(@cc.path_type).to eql('email')
    expect(@cc.confirmation_code.size).to eql(25)
  end
  
  it "should use a 4-digit confirmation_code for settings other than email" do
    communication_channel_model
    @cc.path_type = 'sms'
    @cc.set_confirmation_code(true)
    expect(@cc.confirmation_code.size).to eql(4)
  end
  
  it "should default the path type to email" do
    communication_channel_model
    expect(@cc.path_type).to eql('email')
  end

  it "should provide a confirmation url" do
    HostUrl.expects(:protocol).returns('https')
    HostUrl.expects(:context_host).returns('test.canvas.com')
    CanvasSlug.expects(:generate).returns('abc123')
    communication_channel_model
    expect(@cc.confirmation_url).to eql('https://test.canvas.com/register/abc123')
  end

  it "should only allow email, or sms as path types" do
    communication_channel_model
    @cc.path_type = 'email'; @cc.save
    expect(@cc.path_type).to eql('email')

    @cc.path_type = 'sms'; @cc.save
    expect(@cc.path_type).to eql('sms')

    @cc.path_type = 'not valid'; @cc.save
    expect(@cc.path_type).to eql('email')
  end
  
  it "should act as list" do
    expect(CommunicationChannel).to be_respond_to(:acts_as_list)
  end
  
  it "should scope the list to the user" do
    @u1 = User.create!
    @u2 = User.create!
    expect(@u1).not_to eql(@u2)
    expect(@u1.id).not_to eql(@u2.id)
    @cc1 = @u1.communication_channels.create!(:path => 'jt@instructure.com')
    @cc2 = @u1.communication_channels.create!(:path => 'cody@instructure.com')
    @cc3 = @u2.communication_channels.create!(:path => 'brianp@instructure.com')
    expect(@cc1.user).to eql(@u1)
    expect(@cc2.user).to eql(@u1)
    expect(@cc3.user).to eql(@u2)
    expect(@cc1.user_id).not_to eql(@cc3.user_id)
    expect(@cc2.position).to eql(2)
    @cc2.move_to_top
    @cc2.save
    @cc2.reload
    expect(@cc2.position).to eql(1)
    @cc1.reload
    expect(@cc1.position).to eql(2)
    @cc3.reload
    expect(@cc3.position).to eql(1)
  end
  
  context "can_notify?" do
    it "should normally be able to be used" do
      communication_channel_model
      expect(@communication_channel).to be_can_notify
    end
    
    it "should not be able to be used if it has a policy to not use it" do
      communication_channel_model
      notification_policy_model(:frequency => "never", :communication_channel => @communication_channel)
      @communication_channel.reload
      expect(@communication_channel).not_to be_can_notify
    end
  end

  describe "by_email" do
    it "should return matching ccs case-insensitively" do
      @user = User.create!
      @cc = @user.communication_channels.create!(:path => 'user@example.com')
      expect(@user.communication_channels.by_path('USER@EXAMPLE.COM')).to eq [@cc]
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
      expect(message).not_to be_nil
      expect(message.body).to match /someserver.com/
    end
  end

  it "should not allow deleting sms channels that are the otp channel" do
    user_with_pseudonym(:active_all => 1)
    @cc = @user.communication_channels.sms.create!(:path => 'bob')
    @cc.confirm!
    @user.otp_communication_channel = @cc
    @user.save!
    @cc.reload
    expect(@cc.destroy).to be_falsey
    expect(@cc.reload).to be_active
  end

  describe "merge candidates" do
    let_once(:user1) { User.create! }
    let_once(:cc1) { user1.communication_channels.create!(:path => 'jt@instructure.com') }
    it "should return users with a matching e-mail address" do
      user2 = User.create!
      cc2 = user2.communication_channels.create!(:path => 'jt@instructure.com')
      cc2.confirm!
      Account.default.pseudonyms.create!(:user => user2, :unique_id => 'user2')

      expect(cc1.merge_candidates).to eq [user2]
      expect(cc1.has_merge_candidates?).to be_truthy
    end

    it "should not return users without an active pseudonym" do
      user2 = User.create!
      cc2 = user2.communication_channels.create!(:path => 'jt@instructure.com')
      cc2.confirm!

      expect(cc1.merge_candidates).to eq []
      expect(cc1.has_merge_candidates?).to be_falsey
    end

    it "should not return users that match on an unconfirmed cc" do
      user2 = User.create!
      cc2 = user2.communication_channels.create!(:path => 'jt@instructure.com')
      Account.default.pseudonyms.create!(:user => user2, :unique_id => 'user2')

      expect(cc1.merge_candidates).to eq []
      expect(cc1.has_merge_candidates?).to be_falsey
    end

    it "should only check one user for boolean result" do
      user2 = User.create!
      cc2 = user2.communication_channels.create!(:path => 'jt@instructure.com')
      cc2.confirm!
      Account.default.pseudonyms.create!(:user => user2, :unique_id => 'user2')
      user3 = User.create!
      cc3 = user3.communication_channels.create!(:path => 'jt@instructure.com')
      cc3.confirm!
      Account.default.pseudonyms.create!(:user => user3, :unique_id => 'user3')

      User.any_instance.expects(:all_active_pseudonyms).once.returns([true])
      expect(cc1.has_merge_candidates?).to be_truthy
    end

    describe ".bounce_for_path" do
      it "flags paths with too many bounces" do
        @cc1 = communication_channel_model(path: 'not_as_bouncy@example.edu')
        @cc2 = communication_channel_model(path: 'bouncy@example.edu')

        %w{bouncy@example.edu Bouncy@example.edu bOuNcY@Example.edu bouncy@example.edu not_as_bouncy@example.edu bouncy@example.edu}.each{|path| CommunicationChannel.bounce_for_path(path)}

        @cc1.reload
        expect(@cc1.bounce_count).to eq 1
        expect(@cc1.bouncing?).to be_falsey

        @cc2.reload
        expect(@cc2.bounce_count).to eq 5
        expect(@cc2.bouncing?).to be_truthy
      end
    end

    context "sharding" do
      specs_require_sharding

      it "should find a match on another shard" do
        Enrollment.stubs(:cross_shard_invitations?).returns(true)
        @shard1.activate do
          @user2 = User.create!
          cc2 = @user2.communication_channels.create!(:path => 'jt@instructure.com')
          cc2.confirm!
          account = Account.create!
          account.pseudonyms.create!(:user => @user2, :unique_id => 'user2')
        end

        skip if CommunicationChannel.associated_shards('jt@instructure.com') == [Shard.default]

        expect(cc1.merge_candidates).to eq [@user2]
        expect(cc1.has_merge_candidates?).to be_truthy
      end

      it "should search a non-default shard *only*" do
        Enrollment.stubs(:cross_shard_invitations?).returns(false)
        cc1.confirm!
        Account.default.pseudonyms.create!(:user => user1, :unique_id => 'user1')

        @shard1.activate do
          @user2 = User.create!
          @cc2 = @user2.communication_channels.create!(:path => 'jt@instructure.com')
          @cc2.confirm!
          account = Account.create!
          account.pseudonyms.create!(:user => @user2, :unique_id => 'user2')
        end

        expect(cc1.merge_candidates).to eq []
        expect(@cc2.merge_candidates).to eq []
      end

      describe ".bounce_for_path" do
        it "flags paths with too many bounces" do
          @cc1 = communication_channel_model(path: 'not_as_bouncy@example.edu')
          @shard1.activate do
            @cc2 = communication_channel_model(path: 'bouncy@example.edu')
          end

          skip if CommunicationChannel.associated_shards('bouncy@example.edu') == [Shard.default]

          @shard2.activate do
            @cc3 = communication_channel_model(path: 'BOUNCY@example.edu')
          end

          %w{bouncy@example.edu Bouncy@example.edu bOuNcY@Example.edu bouncy@example.edu not_as_bouncy@example.edu bouncy@example.edu}.each{|path| CommunicationChannel.bounce_for_path(path)}

          @cc1.reload
          expect(@cc1.bounce_count).to eq 1
          expect(@cc1.bouncing?).to be_falsey

          @cc2.reload
          expect(@cc2.bounce_count).to eq 5
          expect(@cc2.bouncing?).to be_truthy

          @cc3.reload
          expect(@cc3.bounce_count).to eq 5
          expect(@cc3.bouncing?).to be_truthy
        end
      end
    end
  end
end
