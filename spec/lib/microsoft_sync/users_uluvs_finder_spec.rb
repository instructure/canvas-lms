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
  let(:course) { course_model(name: 'sync test course') }
  let(:group) { MicrosoftSync::Group.create(course: course) }
  let(:root_account) { group.root_account }

  describe '#call' do
    subject { described_class.new(user_ids, root_account).call }

    context 'when microsoft sync is not configured' do
      let(:user_ids) { [1] }

      it 'raises a descriptive GracefulCancelError' do
        klass = MicrosoftSync::InvalidOrMissingLoginAttributeConfig
        public_message = 'Invalid or missing "login attribute" config in account'

        expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, public_message)
      end
    end

    context 'when microsoft sync is configured' do
      before do
        root_account.settings[:microsoft_sync_enabled] = true
        root_account.settings[:microsoft_sync_tenant] = 'tenant.example.com'
      end

      context 'when the login_attribute=email' do
        let(:email_address) { 'email@example.com' }
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

          root_account.settings[:microsoft_sync_login_attribute] = 'email'
          root_account.save!
        end

        it 'returns an array mapping the user id with uluv' do
          users_uluvs = subject.to_h

          expect(users_uluvs.size).to eq 1
          expect(users_uluvs[communication_channel.user_id]).to eq email_address
        end

        context 'inactive communication channels' do
          let(:second_user) { user_model }
          let(:second_channel) do
            communication_channel_model(workflow_state: :inactive, path: "a_email@example.com", user_id: second_user.id)
          end
          let(:user_ids) { [communication_channel.user_id, second_user.id] }

          it 'only returns the confirmed email address uluv' do
            users_uluvs = subject.to_h

            expect(users_uluvs.size).to eq 1
            expect(users_uluvs[communication_channel.user_id]).to eq email_address
          end
        end
      end

      shared_examples_for 'when the login attribute is set' do |login_attribute, description|
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

      context 'when the login_attribute=preferred_username' do
        let(:expected_uluv) { 'preferred_username@example.com' }
        let(:user) { user_with_pseudonym(username: expected_uluv) }

        before { 3.times { pseudonym(user) } }

        it_behaves_like 'when the login attribute is set', 'preferred_username', 'login name'
      end

      context 'when the login_attribute=sis_user_id' do
        let(:expected_uluv) { '1021616' }
        let(:user) { user_with_pseudonym(sis_user_id: expected_uluv) }

        before { (1..3).each { |i| pseudonym(user, sis_user_id: "#{expected_uluv}#{i}") } }

        it_behaves_like 'when the login attribute is set', 'sis_user_id', 'SIS id'
      end

      context 'when the login_attribute=integration_id' do
        let(:expected_uluv) { 'abcdef' }
        let(:user) { user_with_pseudonym(integration_id: expected_uluv) }

        before { (1..3).each { |i| pseudonym(user, integration_id: "#{expected_uluv}#{i}") } }

        it_behaves_like 'when the login attribute is set', 'integration_id', 'integration id'
      end

      context 'when the login_attribute=invalid' do
        let(:user_ids) { [1] }

        before do
          root_account.settings[:microsoft_sync_login_attribute] = 'invalid'
          root_account.save!
        end

        it 'raises an error' do
          expect { subject }.to raise_error(MicrosoftSync::InvalidOrMissingLoginAttributeConfig)
        end
      end

      context "when pseudonyms have a null value for the lookup field" do
        let(:user1) { user_with_pseudonym(sis_user_id: 'somesisid') }
        let(:user2) { user_with_pseudonym }
        let(:user_ids) { [user1.id, user2.id] }

        it "skips those pseudonyms" do
          root_account.settings[:microsoft_sync_login_attribute] = 'sis_user_id'
          root_account.save!
          expect(subject).to eq([[user1.id, 'somesisid']])
        end
      end
    end
  end
end
