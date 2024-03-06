# frozen_string_literal: true

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

describe CommunicationChannel do
  before(:once) do
    Messages::Partitioner.process
  end

  before do
    @pseudonym = double("Pseudonym")
    allow(@pseudonym).to receive(:destroyed?).and_return(false)
    allow(Pseudonym).to receive(:find_by_user_id).and_return(@pseudonym)
  end

  it "creates a new instance given valid attributes" do
    factory_with_protected_attributes(CommunicationChannel, communication_channel_valid_attributes)
  end

  describe "::trusted_confirmation_redirect?" do
    before do
      @cc_redirect_trust_policies = CommunicationChannel.instance_variable_get(:@redirect_trust_policies)
      CommunicationChannel.instance_variable_set(:@redirect_trust_policies, nil)
    end

    after do
      CommunicationChannel.instance_variable_set(:@redirect_trust_policies, @cc_redirect_trust_policies)
    end

    let(:account) { double("Account") }
    let(:url) { "http://some.place" }

    it "is falsey by default" do
      expect(CommunicationChannel.trusted_confirmation_redirect?(account, url)).to be_falsey
    end

    it "is falsey if no policies return true" do
      CommunicationChannel.add_confirmation_redirect_trust_policy { false }

      expect(CommunicationChannel.trusted_confirmation_redirect?(account, url)).to be_falsey
    end

    it "is truthy if any given policy returns true" do
      CommunicationChannel.add_confirmation_redirect_trust_policy { false }
      CommunicationChannel.add_confirmation_redirect_trust_policy { true }

      expect(CommunicationChannel.trusted_confirmation_redirect?(account, url)).to be_truthy
    end

    it "is falsey for non-http(s) URLs" do
      CommunicationChannel.add_confirmation_redirect_trust_policy { true }

      mailto = "mailto:bill@microsoft.net"
      expect(CommunicationChannel.trusted_confirmation_redirect?(account, mailto)).to be_falsey
    end

    it "passes the given params to the policies" do
      root_account_param = nil
      uri_param = nil

      CommunicationChannel.add_confirmation_redirect_trust_policy do |root_account, uri|
        root_account_param = root_account
        uri_param = uri
      end

      CommunicationChannel.trusted_confirmation_redirect?(account, url)

      expect(root_account_param).to eq(account)
      expect(uri_param).to eq(URI(url))
    end
  end

  describe "imported?" do
    it "defaults to false" do
      expect(CommunicationChannel.new).not_to be_imported
    end

    it "is false if the channel has no pseudonym" do
      communication_channel_model
      expect(@communication_channel).not_to be_imported
    end

    it "is false if the channel is associated with a pseudonym" do
      user_with_pseudonym(active_all: true)
      channel = @pseudonym.communication_channel

      expect(channel).not_to be_imported
    end

    it "is true if the channel is the sis_communication_channel of a pseudonym" do
      user_with_pseudonym(active_all: true)
      channel = @pseudonym.communication_channel
      @pseudonym.update_attribute(:sis_communication_channel_id, channel.id)

      expect(channel).to be_imported
    end
  end

  it "has a decent state machine" do
    communication_channel_model
    expect(@cc.state).to be(:unconfirmed)
    @cc.confirm
    expect(@cc.state).to be(:active)
    @cc.retire
    expect(@cc.state).to be(:retired)
    @cc.re_activate
    expect(@cc.state).to be(:active)

    communication_channel_model(path: "another_path@example.com")
    expect(@cc.state).to be(:unconfirmed)
    @cc.retire
    expect(@cc.state).to be(:retired)
    @cc.re_activate
    expect(@cc.state).to be(:active)
  end

  it "creates notification policies when confirmed if there are Notifications" do
    Notification.create!(name: "Confirm Email Communication Channel", category: "Registration")
    communication_channel_model
    expect(@cc.state).to be(:unconfirmed)
    expect(@cc.notification_policies).to be_empty

    @cc.confirm
    expect(@cc.notification_policies).not_to be_empty
  end

  it "resets the bounce count when being reactivated" do
    communication_channel_model
    @cc.confirm
    @cc.retire
    @cc.bounce_count = 2
    @cc.save!
    @cc.re_activate
    @cc.reload
    expect(@cc.bounce_count).to eq(0)
  end

  it "sets a confirmation code unless one has been set" do
    expect(CanvasSlug).to receive(:generate).at_least(1).and_return("abc123")
    communication_channel_model
    expect(@cc.confirmation_code).to eql("abc123")
  end

  it "does not increment confirmation_sent_count on bouncing channel" do
    account = Account.create!
    cc = communication_channel_model(
      path: "foo@bar.edu",
      last_bounce_at: "2015-01-01T01:01:01.000Z",
      last_suppression_bounce_at: "2015-03-03T03:03:03.000Z",
      last_transient_bounce_at: "2015-04-04T04:04:04.000Z",
      updated_at: "2015-04-04T04:04:04.000Z"
    )
    CommunicationChannel.bounce_for_path(
      path: "foo@bar.edu",
      timestamp: "2015-02-02T02:02:02.000Z",
      details: nil,
      permanent_bounce: true,
      suppression_bounce: false
    )
    conf_count = cc.reload.confirmation_sent_count
    cc.send_confirmation!(account)
    expect(cc.reload.confirmation_sent_count).to eq conf_count
  end

  it "is able to reset a confirmation code" do
    communication_channel_model
    old_cc = @cc.confirmation_code
    @cc.set_confirmation_code(true)
    expect(@cc.confirmation_code).not_to eql(old_cc)
  end

  it "does not send two reset confirmation code" do
    cc = communication_channel_model
    enable_cache do
      expect(cc).to receive(:set_confirmation_code).twice # once from create, once from first forgot
      cc.forgot_password!
      cc.forgot_password!
      cc.forgot_password!
    end
  end

  it "does not update cache if workflow_state doesn't change" do
    cc = communication_channel_model
    expect(cc.user).not_to receive(:clear_email_cache!)
    cc.save!
  end

  it "updates cache if workflow_state does change" do
    cc = communication_channel_model
    expect(cc.user).to receive(:clear_email_cache!).once
    cc.destroy
  end

  it "uses a 15-digit confirmation code for default or email path_type settings" do
    communication_channel_model
    expect(@cc.path_type).to eql("email")
    expect(@cc.confirmation_code.size).to be(25)
  end

  it "uses a 4-digit confirmation_code for settings other than email" do
    communication_channel_model
    @cc.path_type = "sms"
    @cc.set_confirmation_code(true)
    expect(@cc.confirmation_code.size).to be(4)
  end

  it "defaults the path type to email" do
    communication_channel_model
    expect(@cc.path_type).to eql("email")
  end

  it "provides a confirmation url" do
    expect(HostUrl).to receive(:protocol).and_return("https")
    expect(HostUrl).to receive(:context_host).and_return("test.canvas.com")
    expect(CanvasSlug).to receive(:generate).and_return("abc123")
    communication_channel_model
    expect(@cc.confirmation_url).to eql("https://test.canvas.com/register/abc123")
  end

  it "only allows email, or sms as path types" do
    communication_channel_model
    @cc.path_type = "email"
    @cc.save
    expect(@cc.path_type).to eql("email")

    @cc.path_type = "sms"
    @cc.save
    expect(@cc.path_type).to eql("sms")

    @cc.path_type = "not valid"
    @cc.save
    expect(@cc.path_type).to eql("email")
  end

  it "sorts of validate emails" do
    user = User.create!
    invalid_stuff = { username: "invalid", user:, pseudonym_id: "1" }
    expect { communication_channel(user, invalid_stuff) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "limits quantity of channels a user can have" do
    stub_const("CommunicationChannel::MAX_CCS_PER_USER", 3)
    user = User.create!(name: "jim halpert")
    expect { 5.times { |i| communication_channel(user, username: "user_#{user.id}_#{i}@example.com") } }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "acts as list" do
    expect(CommunicationChannel).to respond_to(:acts_as_list)
  end

  it "scopes the list to the user" do
    @u1 = User.create!
    @u2 = User.create!
    expect(@u1).not_to eql(@u2)
    expect(@u1.id).not_to eql(@u2.id)
    @cc1 = communication_channel(@u1, { username: "jt@instructure.com" })
    @cc2 = communication_channel(@u1, { username: "cody@instructure.com" })
    @cc3 = communication_channel(@u2, { username: "brianp@instructure.com" })
    expect(@cc1.user).to eql(@u1)
    expect(@cc2.user).to eql(@u1)
    expect(@cc3.user).to eql(@u2)
    expect(@cc1.user_id).not_to eql(@cc3.user_id)
    expect(@cc2.position).to be(2)
    @cc2.move_to_top
    @cc2.save
    @cc2.reload
    expect(@cc2.position).to be(1)
    @cc1.reload
    expect(@cc1.position).to be(2)
    @cc3.reload
    expect(@cc3.position).to be(1)
  end

  it "counts the number of confirmations sent correctly" do
    account = Account.create!
    @u1 = User.create!
    @cc1 = communication_channel(@u1, { username: "landong@instructure.com" })
    @cc1.send_confirmation!(account)
    @cc1.send_confirmation!(account)
    @cc1.send_confirmation!(account)
    # Note this 4th one should not count up
    @cc1.send_confirmation!(account)
    @cc2 = communication_channel(@u1, { username: "steveb@instructure.com" })
    @cc2.send_confirmation!(account)
    @cc2.send_confirmation!(account)
    @cc3 = communication_channel(@u1, { username: "aaronh@instructure.com" })
    @cc3.send_confirmation!(account)
    expect(@cc1.confirmation_sent_count).to be(3)
    expect(@cc2.confirmation_sent_count).to be(2)
    expect(@cc3.confirmation_sent_count).to be(1)
  end

  describe "by_email" do
    it "returns matching ccs case-insensitively" do
      @user = User.create!
      communication_channel(@user, { username: "user@example.com" })
      expect(@user.communication_channels.by_path("USER@EXAMPLE.COM")).to eq [@cc]
    end
  end

  it "properly validates the uniqueness of path" do
    @user = User.create!
    communication_channel(@user, { username: "user1@example.com" })
    # should allow a different address
    communication_channel(@user, { username: "user2@example.com" })
    # should allow a different path_type
    communication_channel(@user, { username: "user1@example.com", path_type: "sms" })
  end

  context "destroy_permanently!" do
    it "does not violate foreign key constraints" do
      communication_channel_model
      notification_policy_model(frequency: "daily", communication_channel: @communication_channel)
      delayed_message_model(notification_policy_id: @notification_policy.id)
      @communication_channel.destroy_permanently!
    end
  end

  context "notifications" do
    it "forwards the root account to the message" do
      notification = Notification.create!(name: "Confirm Email Communication Channel", category: "Registration")
      @user = User.create!
      @user.register!
      communication_channel(@user, { username: "user1@example.com" })
      account = Account.create!
      allow(HostUrl).to receive(:context_host).with(account, any_args).and_return("someserver.com")
      allow(HostUrl).to receive(:context_host).with(@cc, any_args).and_return("someserver.com")
      @cc.send_confirmation!(account)
      message = Message.where(communication_channel_id: @cc, notification_id: notification).first
      expect(message).not_to be_nil
      expect(message.body).to match(/someserver.com/)
    end
  end

  it "does not allow deleting sms channels that are the otp channel" do
    user_with_pseudonym(active_all: 1)
    @cc = @user.communication_channels.sms.create!(path: "bob")
    @cc.confirm!
    @user.otp_communication_channel = @cc
    @user.save!
    @cc.reload
    expect(@cc.destroy).to be_falsey
    expect(@cc.reload).to be_active
  end

  describe "#last_bounce_summary" do
    it "gets the diagnostic code" do
      user = User.create!
      cc = communication_channel(user, {
                                   username: "path@example.com",
                                   last_bounce_details: { "bouncedRecipients" => [{ "diagnosticCode" => "stuff and things" }] }
                                 })

      expect(cc.last_bounce_summary).to eq("stuff and things")
    end

    it "doesn't fail when there isn't a last bounce" do
      user = User.create!
      cc = communication_channel(user, { username: "path@example.com" })

      expect(cc.last_bounce_details).to be_nil
      expect(cc.last_bounce_summary).to be_nil
    end
  end

  describe "#last_transient_bounce_summary" do
    it "gets the diagnostic code" do
      user = User.create!
      cc = communication_channel(user, {
                                   username: "path@example.com",
                                   last_transient_bounce_details: { "bouncedRecipients" => [{ "diagnosticCode" => "stuff and things" }] }
                                 })

      expect(cc.last_transient_bounce_summary).to eq("stuff and things")
    end

    it "doesn't fail when there isn't a last transient bounce" do
      user = User.create!
      cc = communication_channel(user, { username: "path@example.com" })

      expect(cc.last_transient_bounce_details).to be_nil
      expect(cc.last_transient_bounce_summary).to be_nil
    end
  end

  describe "merge candidates" do
    let_once(:user1) { User.create! }
    let_once(:cc1) { communication_channel(user1, username: "jt@instructure.com") }
    it "returns users with a matching e-mail address" do
      user2 = User.create!
      communication_channel(user2, { username: "jt@instructure.com", active_cc: true })
      Account.default.pseudonyms.create!(user: user2, unique_id: "user2")

      expect(cc1.merge_candidates).to eq [user2]
      expect(cc1.has_merge_candidates?).to be_truthy
    end

    it "does not return users without an active pseudonym" do
      user2 = User.create!
      communication_channel(user2, { username: "jt@instructure.com", active_cc: true })

      expect(cc1.merge_candidates).to eq []
      expect(cc1.has_merge_candidates?).to be_falsey
    end

    it "does not return users that match on an unconfirmed cc" do
      user2 = User.create!
      communication_channel(user2, { username: "jt@instructure.com" })
      Account.default.pseudonyms.create!(user: user2, unique_id: "user2")

      expect(cc1.merge_candidates).to eq []
      expect(cc1.has_merge_candidates?).to be_falsey
    end

    it "only checks one user for boolean result" do
      user2 = User.create!
      communication_channel(user2, { username: "jt@instructure.com", active_cc: true })
      Account.default.pseudonyms.create!(user: user2, unique_id: "user2")
      user3 = User.create!
      communication_channel(user3, { username: "jt@instructure.com", active_cc: true })
      Account.default.pseudonyms.create!(user: user3, unique_id: "user3")

      expect_any_instance_of(User).to receive(:all_active_pseudonyms).once.and_return([true])
      expect(cc1.has_merge_candidates?).to be_truthy
    end

    it "does not return users for push channels" do
      user2 = User.create!
      communication_channel(user2, { username: "push", path_type: CommunicationChannel::TYPE_PUSH, active_cc: true })
      Account.default.pseudonyms.create!(user: user2, unique_id: "user2")
      user3 = User.create!
      communication_channel(user3, { username: "push", path_type: CommunicationChannel::TYPE_PUSH, active_cc: true })
      Account.default.pseudonyms.create!(user: user3, unique_id: "user3")

      expect(cc1.has_merge_candidates?).to be_falsey
    end

    describe ".bounce_for_path" do
      it "flags paths with too many bounces and doesn't process subsequent bounces" do
        @cc1 = communication_channel_model(path: "not_as_bouncy@example.edu")
        @cc2 = communication_channel_model(path: "bouncy@example.edu")

        %w[bouncy@example.edu Bouncy@example.edu bOuNcY@Example.edu bouncy@example.edu bouncy@example.edu].each do |path|
          CommunicationChannel.bounce_for_path(
            path:,
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
        expect(@cc2.bounce_count).to eq 1
        expect(@cc2.bouncing?).to be_truthy
      end

      it "stores the date of the last hard bounce" do
        cc = communication_channel_model(
          path: "foo@bar.edu",
          last_bounce_at: "2015-01-01T01:01:01.000Z",
          last_suppression_bounce_at: "2015-03-03T03:03:03.000Z",
          last_transient_bounce_at: "2015-04-04T04:04:04.000Z",
          updated_at: "2015-04-04T04:04:04.000Z"
        )
        CommunicationChannel.bounce_for_path(
          path: "foo@bar.edu",
          timestamp: "2015-02-02T02:02:02.000Z",
          details: nil,
          permanent_bounce: true,
          suppression_bounce: false
        )

        cc.reload
        expect(cc.last_bounce_at).to eq("2015-02-02T02:02:02.000Z")
        expect(cc.last_suppression_bounce_at).to eq("2015-03-03T03:03:03.000Z")
        expect(cc.last_transient_bounce_at).to eq("2015-04-04T04:04:04.000Z")
      end

      it "stores the date of the last soft bounce bounce" do
        cc = communication_channel_model(
          path: "foo@bar.edu",
          last_bounce_at: "2015-01-01T01:01:01.000Z",
          last_suppression_bounce_at: "2015-03-03T03:03:03.000Z",
          last_transient_bounce_at: "2015-04-04T04:04:04.000Z",
          updated_at: "2015-04-04T04:04:04.000Z"
        )
        CommunicationChannel.bounce_for_path(
          path: "foo@bar.edu",
          timestamp: "2015-05-05T05:05:05.000Z",
          details: nil,
          permanent_bounce: false,
          suppression_bounce: false
        )

        cc.reload
        expect(cc.last_bounce_at).to eq("2015-01-01T01:01:01.000Z")
        expect(cc.last_suppression_bounce_at).to eq("2015-03-03T03:03:03.000Z")
        expect(cc.last_transient_bounce_at).to eq("2015-05-05T05:05:05.000Z")
      end

      it "stores the date of the last suppression bounce" do
        cc = communication_channel_model(
          path: "foo@bar.edu",
          last_bounce_at: "2015-01-01T01:01:01.000Z",
          last_suppression_bounce_at: "2015-03-03T03:03:03.000Z",
          last_transient_bounce_at: "2015-04-04T04:04:04.000Z",
          updated_at: "2015-04-04T04:04:04.000Z"
        )
        CommunicationChannel.bounce_for_path(
          path: "foo@bar.edu",
          timestamp: "2015-02-02T02:02:02.000Z",
          details: nil,
          permanent_bounce: true,
          suppression_bounce: true
        )

        cc.reload
        expect(cc.last_bounce_at).to eq("2015-01-01T01:01:01.000Z")
        expect(cc.last_suppression_bounce_at).to eq("2015-02-02T02:02:02.000Z")
        expect(cc.last_transient_bounce_at).to eq("2015-04-04T04:04:04.000Z")
      end

      it "stores the details of the last hard bounce" do
        cc = communication_channel_model(path: "foo@bar.edu")
        CommunicationChannel.bounce_for_path(
          path: "foo@bar.edu",
          timestamp: nil,
          details: { "some" => "details", "foo" => "bar" },
          permanent_bounce: true,
          suppression_bounce: false
        )

        cc.reload
        expect(cc.last_bounce_details).to eq("some" => "details", "foo" => "bar")
        expect(cc.last_transient_bounce_details).to be_nil
      end

      it "won't bounce twice in a row" do
        cc = communication_channel_model(path: "foo@bar.edu")
        bounce_action = lambda do
          CommunicationChannel.bounce_for_path(
            path: cc.path,
            timestamp: Time.zone.now,
            details: { "some" => "details" },
            permanent_bounce: false,
            suppression_bounce: false
          )
        end
        expect { bounce_action.call }.to change {
          cc.reload.last_transient_bounce_at
        }
        expect { bounce_action.call }.to not_change {
          cc.reload.last_transient_bounce_at
        }
        Timecop.travel(3.hours) do
          expect { bounce_action.call }.to change {
            cc.reload.last_transient_bounce_at
          }
        end
      end

      it "accounts for current callbacks in bulk bouncer" do
        # If you hit this spec failure, you changed the callbacks that have been
        # checked in the communication_channel save. Make sure that it is not an
        # action that would need to happen for the bounce_for_path method. If it
        # does not need to happen, add it to the list below. If it does, handle
        # that, then add it to the list here.
        accounted_for_callbacks = %i[
          after_save_collection_association
          assert_path_type
          autosave_associated_records_for_pseudonym
          autosave_associated_records_for_user
          around_save_collection_association
          broadcast_notifications
          clear_user_email_cache
          consider_building_pseudonym
          set_confirmation_code
          set_root_account_ids
          after_save_flag_old_microsoft_sync_user_mappings
          consider_building_notification_policies
        ]
        expect(CommunicationChannel._save_callbacks.collect(&:filter).select { |k| k.is_a? Symbol } - accounted_for_callbacks).to eq []
      end

      it "stores the details of the last soft bounce" do
        cc = communication_channel_model(path: "foo@bar.edu")
        CommunicationChannel.bounce_for_path(
          path: "foo@bar.edu",
          timestamp: nil,
          details: { "some" => "details", "foo" => "bar" },
          permanent_bounce: false,
          suppression_bounce: false
        )

        cc.reload
        expect(cc.last_transient_bounce_details).to eq("some" => "details", "foo" => "bar")
        expect(cc.last_bounce_details).to be_nil
      end

      it "does not store the details of the last suppression bounce" do
        cc = communication_channel_model(
          path: "foo@bar.edu",
          last_bounce_details: { "existing" => "details" }
        )
        CommunicationChannel.bounce_for_path(
          path: "foo@bar.edu",
          timestamp: nil,
          details: { "some" => "details", "foo" => "bar" },
          permanent_bounce: true,
          suppression_bounce: true
        )

        cc.reload
        expect(cc.last_bounce_details).to eq("existing" => "details")
        expect(cc.last_transient_bounce_details).to be_nil
      end
    end

    context "sharding" do
      specs_require_sharding

      describe "set_root_account_ids" do
        subject { communication_channel.root_account_ids }

        let(:path) { "test@instructure.com" }
        let(:communication_channel) { CommunicationChannel.create!(user:, path:) }

        before { user.update_columns(root_account_ids:) }

        let(:user) { User.create! }

        context "is associated with root accounts on a foreign shard" do
          let(:globalized_ids) { [Shard.global_id_for(1, @shard2), Shard.global_id_for(2, @shard2)] }
          let(:root_account_ids) { globalized_ids }

          it "keeps the root account IDs global" do
            expect(subject).to match_array globalized_ids
          end
        end

        context "is associated with root accounts on the local shard" do
          let(:localized_ids) { [1, 2] }
          let(:root_account_ids) { localized_ids }

          it "keeps the root account IDs local" do
            expect(subject).to match_array localized_ids
          end
        end
      end

      it "finds a match on another shard" do
        allow(Enrollment).to receive(:cross_shard_invitations?).and_return(true)
        @shard1.activate do
          @user2 = User.create!
          communication_channel(@user2, { username: "jt@instructure.com", active_cc: true })
          account = Account.create!
          account.pseudonyms.create!(user: @user2, unique_id: "user2")
        end

        skip if CommunicationChannel.associated_shards("jt@instructure.com") == [Shard.default]

        expect(cc1.merge_candidates).to eq [@user2]
        expect(cc1.has_merge_candidates?).to be_truthy
      end

      it "searches a non-default shard *only*" do
        allow(Enrollment).to receive(:cross_shard_invitations?).and_return(false)
        cc1.confirm!
        Account.default.pseudonyms.create!(user: user1, unique_id: "user1")

        @shard1.activate do
          @user2 = User.create!
          @cc2 = communication_channel(@user2, { username: "jt@instructure.com", active_cc: true })
          account = Account.create!
          account.pseudonyms.create!(user: @user2, unique_id: "user2")
        end

        expect(cc1.merge_candidates).to eq []
        expect(@cc2.merge_candidates).to eq []
      end

      describe ".bounce_for_path" do
        it "flags paths with too many bounces" do
          stub_const("CommunicationChannel::RETIRE_THRESHOLD", 3)
          @cc1 = communication_channel_model(path: "not_as_bouncy@example.edu")
          @shard1.activate do
            @cc2 = communication_channel_model(path: "bouncy@example.edu")
          end

          skip if CommunicationChannel.associated_shards("bouncy@example.edu") == [Shard.default]

          @shard2.activate do
            @cc3 = communication_channel_model(path: "BOUNCY@example.edu")
          end

          %w[bouncy@example.edu Bouncy@example.edu bOuNcY@Example.edu bouncy@example.edu bouncy@example.edu].each do |path|
            CommunicationChannel.bounce_for_path(
              path:,
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
          expect(@cc2.bounce_count).to eq 3
          expect(@cc2.bouncing?).to be_truthy

          @cc3.reload
          expect(@cc3.bounce_count).to eq 3
          expect(@cc3.bouncing?).to be_truthy
        end
      end
    end
  end

  describe "flagging old microsoft sync user mappings" do
    context "when there is a root account with microsoft sync enabled" do
      let(:enrollment) { student_in_course(active_all: true) }
      let(:account) do
        ra = enrollment.root_account
        ra.settings[:microsoft_sync_enabled] = true
        ra.settings[:microsoft_sync_login_attribute] = "email"
        ra.save
        ra
      end
      let(:user) { enrollment.user }
      let(:cc) { communication_channel_model(user:) }
      let(:mapping) do
        MicrosoftSync::UserMapping.create!(root_account: account, user:, aad_id: "abc123")
      end

      describe "destroying the communication channel" do
        it "flags the user's mapping" do
          expect { cc.destroy_permanently! }.to change { mapping.reload.needs_updating }
            .from(false).to(true)
        end
      end

      describe "updating the communication channel" do
        it "flags the user's mapping" do
          expect do
            cc.update(workflow_state: :retired)
          end.to change { mapping.reload.needs_updating }.from(false).to(true)
        end
      end
    end

    context "when destroying a communication channel" do
      it "flags old mappings when destroying a communication channel" do
        cc = communication_channel_model
        expect(MicrosoftSync::UserMapping).to receive(:flag_as_needs_updating_if_using_email)
          .with(cc.user)
        cc.destroy_permanently!
      end
    end

    describe "#after_save_flag_old_microsoft_sync_user_mappings" do
      let!(:cc) { communication_channel_model(path_type: described_class::TYPE_EMAIL) }

      it "flags old mappings if path/path_type/position/workflow_state is changed" do
        expect(MicrosoftSync::UserMapping).to receive(:flag_as_needs_updating_if_using_email)
          .with(cc.user)
          .exactly(5).times
        cc.update!(path: "foo" + cc.path)
        cc.update!(position: cc.position + 1)
        expect(cc.workflow_state).to_not eq("active")
        cc.update!(workflow_state: "active")
        cc.update!(path_type: described_class::TYPE_PUSH)
        cc.update!(path_type: described_class::TYPE_EMAIL)
      end

      it "doesn't flag old mappings if path type is not email" do
        cc.update!(path_type: described_class::TYPE_SMS, path: "8005551212")
        expect(MicrosoftSync::UserMapping).to_not receive(:flag_as_needs_updating_if_using_email)
        cc.update!(path_type: described_class::TYPE_TWITTER)
        cc.update!(path: "instructure")
      end

      it "doesn't flag old mappings if nothing relevant has changed" do
        expect(MicrosoftSync::UserMapping).to_not receive(:flag_as_needs_updating_if_using_email)
        cc.update!(updated_at: cc.updated_at + 1, last_bounce_at: Time.now)
      end
    end
  end

  describe "#otp_impaired?" do
    let(:us_cc) do
      communication_channel(user_model, { username: "8015555555@txt.att.net", path_type: CommunicationChannel::TYPE_SMS })
    end
    let(:eu_cc) do
      communication_channel(user_model, { username: "+353872337277", path_type: CommunicationChannel::TYPE_SMS })
    end

    context "no impaired channels" do
      it "returns false for US channels" do
        expect(us_cc.otp_impaired?).to be false
      end

      it "returns false for EU channels" do
        expect(eu_cc.otp_impaired?).to be false
      end
    end

    context "only US impaired channels" do
      before do
        allow(Setting).to receive(:get).and_call_original
        allow(Setting).to receive(:get).with("otp_impaired_country_codes", "").and_return("1")
      end

      it "returns true for US channels" do
        expect(us_cc.otp_impaired?).to be true
      end

      it "returns false for EU channels" do
        expect(eu_cc.otp_impaired?).to be false
      end
    end
  end

  describe "#send_otp!" do
    let(:user) do
      user_model
    end
    let(:cc) do
      communication_channel(user, { username: "8015555555@txt.att.net", path_type: CommunicationChannel::TYPE_SMS })
    end

    it "sends directly via SMS if configured" do
      expect(cc.e164_path).to eq "+18015555555"
      allow(InstStatsd::Statsd).to receive(:increment)
      account = double
      allow(account).to receive_messages(feature_enabled?: true, global_id: "totes_an_ID")
      expect(Services::NotificationService).to receive(:process).with(
        "otp:#{cc.global_id}",
        anything,
        "sms",
        cc.e164_path,
        true
      )
      expect(cc).not_to receive(:send_otp_via_sms_gateway!)
      cc.send_otp!("123456", account)
      expect(InstStatsd::Statsd).to have_received(:increment).with(
        "message.deliver.sms.one_time_password",
        {
          short_stat: "message.deliver",
          tags: { path_type: "sms", notification_name: "one_time_password" }
        }
      )

      expect(InstStatsd::Statsd).to have_received(:increment).with(
        "message.deliver.sms.totes_an_ID",
        {
          short_stat: "message.deliver_per_account",
          tags: { path_type: "sms", root_account_id: "totes_an_ID" }
        }
      )
    end

    it "sends via email if not configured" do
      expect(Services::NotificationService).not_to receive(:process)
      expect(cc).to receive(:send_otp_via_sms_gateway!).once
      cc.send_otp!("123456")
    end

    context "with email channel" do
      let(:cc) do
        communication_channel(user, { username: "test@example.com", path_type: CommunicationChannel::TYPE_EMAIL })
      end

      it "sends actual email if using email channel" do
        expect(cc).not_to receive(:send_otp_via_sms_gateway!)
        expect(Mailer).to receive(:deliver).once
        cc.send_otp!("123456")
      end
    end
  end

  describe "#user_can_have_more_channels?" do
    subject { CommunicationChannel.user_can_have_more_channels?(@user, @domain_root_account) }

    before do
      @domain_root_account = Account.default
      @user = User.create!
    end

    it "returns true if :max_communication_channels settings is not set" do
      expect(subject).to be_truthy
    end

    describe "when :max_communication_channels is set" do
      before do
        @domain_root_account.settings[:max_communication_channels] = 2
        @domain_root_account.save!
      end

      it "returns true if the current number of CCs is less then the setting" do
        communication_channel(@user, { username: "cc1@test.com" })
        expect(subject).to be_truthy
      end

      describe "when there are more CCs then the setting" do
        before do
          @cc1 = communication_channel(@user, { username: "cc1@test.com" })
          @cc2 = communication_channel(@user, { username: "cc2@test.com" })
        end

        it "returns false if the CCs are active" do
          expect(subject).to be_falsey
        end

        it "returns false if the CCs are retired and were recently created" do
          @cc1.destroy!
          @cc2.destroy!
          expect(subject).to be_falsey
        end

        it "returns true if the CCs are retired and not recently created" do
          @cc1.update_columns(created_at: 1.day.ago)
          @cc1.destroy!
          expect(subject).to be_truthy
        end
      end
    end
  end

  describe ".supported" do
    let(:user) { User.create! }
    let!(:sms_channel) { communication_channel(user, { username: "sms", path_type: CommunicationChannel::TYPE_SMS }) }

    it "filters sms channels" do
      expect(CommunicationChannel.supported).to be_empty
    end
  end
end
