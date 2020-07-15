#
# Copyright (C) 2011 - present Instructure, Inc.
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
    @pseudonym = double('Pseudonym')
    allow(@pseudonym).to receive(:destroyed?).and_return(false)
    allow(Pseudonym).to receive(:find_by_user_id).and_return(@pseudonym)
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

  it 'should set the root account based on the pseudonym' do
    user_with_pseudonym(active_all: true)
    channel = @pseudonym.communication_channel

    expect(channel.root_account_id).to eq @pseudonym.account.id
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

  it "should reset the bounce count when being reactivated" do
    communication_channel_model
    @cc.confirm
    @cc.retire
    @cc.bounce_count = 2
    @cc.save!
    @cc.re_activate
    @cc.reload
    expect(@cc.bounce_count).to eq(0)
  end

  it "should set a confirmation code unless one has been set" do
    expect(CanvasSlug).to receive(:generate).at_least(1).and_return('abc123')
    communication_channel_model
    expect(@cc.confirmation_code).to eql('abc123')
  end

  it "should be able to reset a confirmation code" do
    communication_channel_model
    old_cc = @cc.confirmation_code
    @cc.set_confirmation_code(true)
    expect(@cc.confirmation_code).not_to eql(old_cc)
  end

  it "should not send two reset confirmation code" do
    cc = communication_channel_model
    enable_cache do
      expect(cc).to receive(:set_confirmation_code).twice # once from create, once from first forgot
      cc.forgot_password!
      cc.forgot_password!
      cc.forgot_password!
    end
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
    expect(HostUrl).to receive(:protocol).and_return('https')
    expect(HostUrl).to receive(:context_host).and_return('test.canvas.com')
    expect(CanvasSlug).to receive(:generate).and_return('abc123')
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

  it 'should sort of validate emails' do
    user = User.create!
    invalid_stuff = {username: "invalid", user: user, pseudonym_id: "1" }
    expect{communication_channel(user, invalid_stuff)}.to raise_error(ActiveRecord::RecordInvalid)
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

  it "should correctly count the number of confirmations sent" do
    account = Account.create!
    @u1 = User.create!
    @cc1 = @u1.communication_channels.create!(:path => 'landong@instructure.com')
    @cc1.send_confirmation!(account)
    @cc1.send_confirmation!(account)
    @cc1.send_confirmation!(account)
    # Note this 4th one should not count up
    @cc1.send_confirmation!(account)
    @cc2 = @u1.communication_channels.create!(:path => 'steveb@instructure.com')
    @cc2.send_confirmation!(account)
    @cc2.send_confirmation!(account)
    @cc3 = @u1.communication_channels.create!(:path => 'aaronh@instructure.com')
    @cc3.send_confirmation!(account)
    expect(@cc1.confirmation_sent_count).to eql(3)
    expect(@cc2.confirmation_sent_count).to eql(2)
    expect(@cc3.confirmation_sent_count).to eql(1)
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

  context "destroy_permanently!" do
    it "does not violate foreign key constraints" do
      communication_channel_model
      notification_policy_model(:frequency => "daily", :communication_channel => @communication_channel)
      delayed_message_model(:notification_policy_id => @notification_policy.id)
      @communication_channel.destroy_permanently!
    end
  end

  context "notifications" do
    it "should forward the root account to the message" do
      notification = Notification.create!(:name => 'Confirm Email Communication Channel', :category => 'Registration')
      @user = User.create!
      @user.register!
      @cc = @user.communication_channels.create!(:path => 'user1@example.com')
      account = Account.create!
      allow(HostUrl).to receive(:context_host).with(account).and_return('someserver.com')
      allow(HostUrl).to receive(:context_host).with(@cc).and_return('someserver.com')
      allow(HostUrl).to receive(:context_host).with(nil).and_return('default')
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

  describe '#last_bounce_summary' do
    it 'gets the diagnostic code' do
      user = User.create!
      cc = user.communication_channels.create!(path: 'path@example.com') do |cc|
        cc.last_bounce_details = {
          'bouncedRecipients' => [
            {
              'diagnosticCode' => 'stuff and things'
            }
          ]
        }
      end

      expect(cc.last_bounce_summary).to eq('stuff and things')
    end

    it "doesn't fail when there isn't a last bounce" do
      user = User.create!
      cc = user.communication_channels.create!(path: 'path@example.com')

      expect(cc.last_bounce_details).to be_nil
      expect(cc.last_bounce_summary).to be_nil
    end
  end

  describe '#last_transient_bounce_summary' do
    it 'gets the diagnostic code' do
      user = User.create!
      cc = user.communication_channels.create!(path: 'path@example.com') do |cc|
        cc.last_transient_bounce_details = {
          'bouncedRecipients' => [
            {
              'diagnosticCode' => 'stuff and things'
            }
          ]
        }
      end

      expect(cc.last_transient_bounce_summary).to eq('stuff and things')
    end

    it "doesn't fail when there isn't a last transient bounce" do
      user = User.create!
      cc = user.communication_channels.create!(path: 'path@example.com')

      expect(cc.last_transient_bounce_details).to be_nil
      expect(cc.last_transient_bounce_summary).to be_nil
    end
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

      expect_any_instance_of(User).to receive(:all_active_pseudonyms).once.and_return([true])
      expect(cc1.has_merge_candidates?).to be_truthy
    end

    it "does not return users for push channels" do
      user2 = User.create!
      cc2 = user2.communication_channels.create!(:path => 'push', :path_type => CommunicationChannel::TYPE_PUSH)
      cc2.confirm!
      Account.default.pseudonyms.create!(:user => user2, :unique_id => 'user2')
      user3 = User.create!
      cc3 = user3.communication_channels.create!(:path => 'push', :path_type => CommunicationChannel::TYPE_PUSH)
      cc3.confirm!
      Account.default.pseudonyms.create!(:user => user3, :unique_id => 'user3')

      expect(cc1.has_merge_candidates?).to be_falsey
    end

    describe ".bounce_for_path" do
      it "flags paths with too many bounces" do
        @cc1 = communication_channel_model(path: 'not_as_bouncy@example.edu')
        @cc2 = communication_channel_model(path: 'bouncy@example.edu')

        %w{bouncy@example.edu Bouncy@example.edu bOuNcY@Example.edu bouncy@example.edu bouncy@example.edu}.each do |path|
          CommunicationChannel.bounce_for_path(
            path: path,
            timestamp: nil,
            details: nil,
            permanent_bounce: true,
            suppression_bounce: false
          )
        end

        @cc1.reload
        expect(@cc1.bounce_count).to eq 0
        expect(@cc1.bouncing?).to be_falsey

        @cc2.reload
        expect(@cc2.bounce_count).to eq 5
        expect(@cc2.bouncing?).to be_truthy
      end

      it "stores the date of the last hard bounce" do
        cc = communication_channel_model(
          path: 'foo@bar.edu',
          last_bounce_at: '2015-01-01T01:01:01.000Z',
          last_suppression_bounce_at: '2015-03-03T03:03:03.000Z',
          last_transient_bounce_at: '2015-04-04T04:04:04.000Z'
        )
        CommunicationChannel.bounce_for_path(
          path: 'foo@bar.edu',
          timestamp: '2015-02-02T02:02:02.000Z',
          details: nil,
          permanent_bounce: true,
          suppression_bounce: false
        )

        cc.reload
        expect(cc.last_bounce_at).to eq('2015-02-02T02:02:02.000Z')
        expect(cc.last_suppression_bounce_at).to eq('2015-03-03T03:03:03.000Z')
        expect(cc.last_transient_bounce_at).to eq('2015-04-04T04:04:04.000Z')
      end

      it "stores the date of the last soft bounce bounce" do
        cc = communication_channel_model(
          path: 'foo@bar.edu',
          last_bounce_at: '2015-01-01T01:01:01.000Z',
          last_suppression_bounce_at: '2015-03-03T03:03:03.000Z',
          last_transient_bounce_at: '2015-04-04T04:04:04.000Z'
        )
        CommunicationChannel.bounce_for_path(
          path: 'foo@bar.edu',
          timestamp: '2015-05-05T05:05:05.000Z',
          details: nil,
          permanent_bounce: false,
          suppression_bounce: false
        )

        cc.reload
        expect(cc.last_bounce_at).to eq('2015-01-01T01:01:01.000Z')
        expect(cc.last_suppression_bounce_at).to eq('2015-03-03T03:03:03.000Z')
        expect(cc.last_transient_bounce_at).to eq('2015-05-05T05:05:05.000Z')
      end

      it "stores the date of the last suppression bounce" do
        cc = communication_channel_model(
          path: 'foo@bar.edu',
          last_bounce_at: '2015-01-01T01:01:01.000Z',
          last_suppression_bounce_at: '2015-03-03T03:03:03.000Z',
          last_transient_bounce_at: '2015-04-04T04:04:04.000Z'
        )
        CommunicationChannel.bounce_for_path(
          path: 'foo@bar.edu',
          timestamp: '2015-02-02T02:02:02.000Z',
          details: nil,
          permanent_bounce: true,
          suppression_bounce: true
        )

        cc.reload
        expect(cc.last_bounce_at).to eq('2015-01-01T01:01:01.000Z')
        expect(cc.last_suppression_bounce_at).to eq('2015-02-02T02:02:02.000Z')
        expect(cc.last_transient_bounce_at).to eq('2015-04-04T04:04:04.000Z')
      end

      it "stores the details of the last hard bounce" do
        cc = communication_channel_model(path: 'foo@bar.edu')
        CommunicationChannel.bounce_for_path(
          path: 'foo@bar.edu',
          timestamp: nil,
          details: {'some' => 'details', 'foo' => 'bar'},
          permanent_bounce: true,
          suppression_bounce: false
        )

        cc.reload
        expect(cc.last_bounce_details).to eq('some' => 'details', 'foo' => 'bar')
        expect(cc.last_transient_bounce_details).to be_nil
      end

      it "stores the details of the last soft bounce" do
        cc = communication_channel_model(path: 'foo@bar.edu')
        CommunicationChannel.bounce_for_path(
          path: 'foo@bar.edu',
          timestamp: nil,
          details: {'some' => 'details', 'foo' => 'bar'},
          permanent_bounce: false,
          suppression_bounce: false
        )

        cc.reload
        expect(cc.last_transient_bounce_details).to eq('some' => 'details', 'foo' => 'bar')
        expect(cc.last_bounce_details).to be_nil
      end

      it "does not store the details of the last suppression bounce" do
        cc = communication_channel_model(
          path: 'foo@bar.edu',
          last_bounce_details: {'existing' => 'details'}
        )
        CommunicationChannel.bounce_for_path(
          path: 'foo@bar.edu',
          timestamp: nil,
          details: {'some' => 'details', 'foo' => 'bar'},
          permanent_bounce: true,
          suppression_bounce: true
        )

        cc.reload
        expect(cc.last_bounce_details).to eq('existing' => 'details')
        expect(cc.last_transient_bounce_details).to be_nil
      end
    end

    context "sharding" do
      specs_require_sharding

      it "should find a match on another shard" do
        allow(Enrollment).to receive(:cross_shard_invitations?).and_return(true)
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
        allow(Enrollment).to receive(:cross_shard_invitations?).and_return(false)
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

          %w{bouncy@example.edu Bouncy@example.edu bOuNcY@Example.edu bouncy@example.edu bouncy@example.edu}.each do |path|
            CommunicationChannel.bounce_for_path(
              path: path,
              timestamp: nil,
              details: nil,
              permanent_bounce: true,
              suppression_bounce: false
            )
          end

          @cc1.reload
          expect(@cc1.bounce_count).to eq 0
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

  describe "#send_otp!" do
    let(:cc) do
      cc = CommunicationChannel.new
      cc.path = '8015555555@txt.att.net'
      cc
    end

    it "sends directly via SMS if configured" do
      expect(cc.e164_path).to eq '+18015555555'
      account = double()
      allow(account).to receive(:feature_enabled?).and_return(true)
      allow(account).to receive(:global_id).and_return('totes_an_ID')
      expect(Services::NotificationService).to receive(:process).with(
        "otp:#{cc.global_id}",
        anything,
        'sms',
        cc.e164_path,
        true
      )
      expect(InstStatsd::Statsd).to receive(:increment).with("message.deliver.sms.one_time_password",
                                                             { short_stat: "message.deliver",
                                                               tags: { path_type: "sms", notification_name: 'one_time_password' } })

      expect(InstStatsd::Statsd).to receive(:increment).with("message.deliver.sms.totes_an_ID",
                                                             { short_stat: "message.deliver_per_account",
                                                               tags: { path_type: "sms", root_account_id: 'totes_an_ID' } })
      expect(cc).to receive(:send_otp_via_sms_gateway!).never
      cc.send_otp!('123456', account)
    end

    it "sends via email if not configured" do
      expect(Services::NotificationService).to receive(:process).never
      expect(cc).to receive(:send_otp_via_sms_gateway!).once
      cc.send_otp!('123456')
    end
  end

  describe '#user_can_have_more_channels?' do
    before(:each) do
      @domain_root_account = Account.default
      @user = User.create!
    end

    subject { CommunicationChannel.user_can_have_more_channels?(@user, @domain_root_account) }

    it 'returns true if :max_communication_channels settings is not set' do
      expect(subject).to be_truthy
    end

    describe 'when :max_communication_channels is set' do
      before(:each) do
        @domain_root_account.settings[:max_communication_channels] = 2
        @domain_root_account.save!
      end

      it 'returns true if the current number of CCs is less then the setting' do
        @user.communication_channels.create!(:path => 'cc1@test.com')
        expect(subject).to be_truthy
      end

      describe 'when there are more CCs then the setting' do
        before(:each) do
          @cc1 = @user.communication_channels.create!(:path => 'cc1@test.com')
          @cc2 = @user.communication_channels.create!(:path => 'cc2@test.com')
        end

        it 'returns false if the CCs are active' do
          expect(subject).to be_falsey
        end

        it 'returns false if the CCs are retired and were recently created' do
          @cc1.destroy!
          @cc2.destroy!
          expect(subject).to be_falsey
        end

        it 'returns true if the CCs are retired and not recently created' do
          @cc1.update_columns(created_at: 1.day.ago)
          @cc1.destroy!
          expect(subject).to be_truthy
        end
      end
    end
  end
end
