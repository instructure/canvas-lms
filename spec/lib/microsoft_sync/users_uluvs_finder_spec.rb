# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe MicrosoftSync::UsersUluvsFinder do
  let(:course) { course_model(name: "sync test course") }
  let(:group) { MicrosoftSync::Group.create(course:) }
  let(:root_account) { group.root_account }

  describe "#call" do
    subject { described_class.new(user_ids, root_account).call }

    context "when microsoft sync is not configured" do
      let(:user_ids) { [1] }

      it "raises a descriptive GracefulCancelError" do
        klass = MicrosoftSync::InvalidOrMissingLoginAttributeConfig
        public_message = 'Invalid or missing "login attribute" config in account'

        expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, public_message)
      end
    end

    context "when microsoft sync is configured" do
      before do
        root_account.settings[:microsoft_sync_enabled] = true
        root_account.settings[:microsoft_sync_tenant] = "tenant.example.com"
      end

      context "when the login_attribute=email" do
        let(:email_address) { "email@example.com" }
        let(:communication_channel) do
          communication_channel_model(workflow_state: :active, path: email_address)
        end
        let(:user_ids) { [communication_channel.user_id] }

        before do
          (1..3).each do |i|
            communication_channel_model(workflow_state: :active,
                                        path: "email_#{i}@example.com",
                                        user_id: communication_channel.user_id)
          end

          root_account.settings[:microsoft_sync_login_attribute] = "email"
          root_account.save!
        end

        it "returns an array mapping the user id with uluv" do
          users_uluvs = subject.to_h

          expect(users_uluvs.size).to eq 1
          expect(users_uluvs[communication_channel.user_id]).to eq email_address
        end

        context "inactive communication channels" do
          let(:second_user) { user_model }
          let(:second_channel) do
            communication_channel_model(workflow_state: :inactive, path: "a_email@example.com", user_id: second_user.id)
          end
          let(:user_ids) { [communication_channel.user_id, second_user.id] }

          it "only returns the confirmed email address uluv" do
            users_uluvs = subject.to_h

            expect(users_uluvs.size).to eq 1
            expect(users_uluvs[communication_channel.user_id]).to eq email_address
          end
        end
      end

      context "when login_attribute=email and there are cross-shard users" do
        specs_require_sharding

        let(:root_account) { @shard1.activate { account_model } }
        let(:course) { @shard1.activate { course_model(account: root_account) } }

        let(:shard1_users) { @shard1.activate { Array.new(3) { user_model } } }
        let(:shard2_users) { @shard2.activate { Array.new(2) { user_model } } }

        before do
          @shard1.activate do
            root_account.settings[:microsoft_sync_enabled] = true
            root_account.settings[:microsoft_sync_login_attribute] = "email"
            root_account.save!
          end

          @shard1.activate do
            shard1_users[0].communication_channels.create(path: "s1u0@instructure.com").confirm!
            shard1_users[1].communication_channels.create(path: "s1u1@instructure.com").confirm!
          end

          @shard2.activate do
            shard2_users[1].communication_channels.create(path: "s2u1@instructure.com").confirm!
          end

          @shard1.activate do
            [*shard1_users, *shard2_users].each { |user| course.enroll_user(user) }
          end
        end

        it "finds CommunuicationChannels on other shards" do
          @shard1.activate do
            shard1_users.each { |u| expect(u.id).to be < Shard::IDS_PER_SHARD }
            shard2_users.each { |u| expect(u.id).to be >= (@shard2.id * Shard::IDS_PER_SHARD) }
            result = described_class.new(course.enrollments.pluck(:user_id), root_account).call
            expect(result).to contain_exactly(
              [shard1_users[0].id, "s1u0@instructure.com"],
              [shard1_users[1].id, "s1u1@instructure.com"],
              [shard2_users[1].id, "s2u1@instructure.com"]
            )
          end
        end

        it "groups lookups by shard to minimize SQL queries" do
          @shard1.activate do
            uuf = described_class.new(course.enrollments.pluck(:user_id), root_account)
            expect(uuf).to receive(:find_by_email_local).twice.and_call_original
            uuf.call
          end
        end
      end

      shared_examples_for "when the login attribute is set" do |login_attribute, description|
        let(:user_ids) { [user.id] }

        before do
          root_account.settings[:microsoft_sync_login_attribute] = login_attribute
          root_account.save!
        end

        it "returns an array mapping #{description} to uluv" do
          users_uluvs = subject.to_h

          expect(users_uluvs.size).to eq 1
          expect(users_uluvs[user.id]).to eq expected_uluv
        end
      end

      context "when the login_attribute=preferred_username" do
        let(:expected_uluv) { "preferred_username@example.com" }
        let(:user) { user_with_pseudonym(username: expected_uluv) }

        before { 3.times { pseudonym(user) } }

        it_behaves_like "when the login attribute is set", "preferred_username", "login name"
      end

      context "when the login_attribute=sis_user_id" do
        let(:expected_uluv) { "1021616" }
        let(:user) { user_with_pseudonym(sis_user_id: expected_uluv) }

        before { (1..3).each { |i| pseudonym(user, sis_user_id: "#{expected_uluv}#{i}") } }

        it_behaves_like "when the login attribute is set", "sis_user_id", "SIS id"
      end

      context "when the login_attribute=integration_id" do
        let(:expected_uluv) { "abcdef" }
        let(:user) { user_with_pseudonym(integration_id: expected_uluv) }

        before { (1..3).each { |i| pseudonym(user, integration_id: "#{expected_uluv}#{i}") } }

        it_behaves_like "when the login attribute is set", "integration_id", "integration id"
      end

      context "when the login_attribute=invalid" do
        let(:user_ids) { [1] }

        before do
          root_account.settings[:microsoft_sync_login_attribute] = "invalid"
          root_account.save!
        end

        it "raises an error" do
          expect { subject }.to raise_error(MicrosoftSync::InvalidOrMissingLoginAttributeConfig)
        end
      end

      context "when pseudonyms have a null value for the lookup field" do
        let(:user1) { user_with_pseudonym(sis_user_id: "somesisid") }
        let(:user2) { user_with_pseudonym }
        let(:user_ids) { [user1.id, user2.id] }

        it "skips those pseudonyms" do
          root_account.settings[:microsoft_sync_login_attribute] = "sis_user_id"
          root_account.save!
          expect(subject).to eq([[user1.id, "somesisid"]])
        end
      end

      context "with a cross-shard user" do
        specs_require_sharding
        subject { @shard1.activate { described_class.new(user_ids, root_account).call } }

        let(:root_account) { @shard1.activate { account_model } }
        let(:course) { @shard1.activate { course_model(account: root_account) } }
        let(:other_root_account) { @shard1.activate { account_model } }
        let(:shard2_root_account) { @shard2.activate { account_model } }

        let(:shard1_lookup_value) { "somesisid" }
        let(:other_shard1_lookup_value) { "someothersisid" }
        let(:shard2_lookup_value) { "fromthehomeshard" }
        let(:cross_shard_user) { @shard2.activate { user_with_pseudonym(sis_user_id: shard2_lookup_value, account: shard2_root_account) } }
        let(:user_ids) { [cross_shard_user.id] }

        before do
          @shard1.activate do
            root_account.settings[:microsoft_sync_enabled] = true
            root_account.settings[:microsoft_sync_login_attribute] = "sis_user_id"
            root_account.save!

            course.enroll_user(cross_shard_user)
          end
        end

        context "when user has pseudonym on course shard with lookup value present" do
          before do
            @shard1.activate do
              pseudonym(cross_shard_user, sis_user_id: shard1_lookup_value, account: root_account)
            end
          end

          it "uses the course-shard pseudonym" do
            expect(subject).to eq([[cross_shard_user.id, shard1_lookup_value]])
          end

          context "when user also has pseudonym in different root account on course shard" do
            before do
              @shard1.activate do
                # put the wrong pseudonym first to confirm the sort works
                Pseudonym.where(user: cross_shard_user).delete_all
                pseudonym(cross_shard_user, sis_user_id: other_shard1_lookup_value, account: other_root_account).update!(position: 1)
                pseudonym(cross_shard_user, sis_user_id: shard1_lookup_value, account: root_account)
              end
            end

            it "prefers the pseudonym in the same root account as the course" do
              expect(subject).to eq([[cross_shard_user.id, shard1_lookup_value]])
            end
          end
        end

        context "when user has pseudonym on course shard with null lookup value" do
          before do
            @shard1.activate do
              pseudonym(cross_shard_user, sis_user_id: nil)
            end
          end

          it "uses the user-shard pseudonym" do
            expect(subject).to eq([[cross_shard_user.id, shard2_lookup_value]])
          end
        end

        context "when user has pseudonym in different root account on course shard" do
          before do
            @shard1.activate do
              pseudonym(cross_shard_user, sis_user_id: other_shard1_lookup_value, account: other_root_account)
            end
          end

          it "uses the other course-shard pseudonym" do
            expect(subject).to eq([[cross_shard_user.id, other_shard1_lookup_value]])
          end
        end

        context "when user only has pseudonym on home shard" do
          it "uses the user-shard pseudonym" do
            expect(subject).to eq([[cross_shard_user.id, shard2_lookup_value]])
          end
        end
      end
    end
  end
end
