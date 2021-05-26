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

require 'spec_helper'

describe MicrosoftSync::UsersUpnsFinder do
  let(:course) { course_model(name: 'sync test course') }
  let(:group) { MicrosoftSync::Group.create(course: course) }
  let(:root_account) { group.root_account }

  describe '#call' do
    subject { described_class.new(user_ids, root_account).call }

    context 'when microsoft sync is not configured' do
      let(:user_ids) { [1] }

      it 'raise an error' do
        expect { subject }.to raise_error(MicrosoftSync::InvalidOrMissingLoginAttributeConfig)
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

        it 'returns an array mapping the user id with upn' do
          users_upns = subject.to_h

          expect(users_upns.size).to eq 1
          expect(users_upns[communication_channel.user_id]).to eq email_address
        end

        context 'inactive communication channels' do
          let(:second_user) { user_model }
          let(:second_channel) do
            communication_channel_model(workflow_state: :inactive, path: "a_email@example.com", user_id: second_user.id)
          end
          let(:user_ids) { [communication_channel.user_id, second_user.id]}

          it 'only returns the confirmed email address upn' do
            users_upns = subject.to_h

            expect(users_upns.size).to eq 1
            expect(users_upns[communication_channel.user_id]).to eq email_address
          end
        end
      end

      context 'when the login_attribute=preferred_username' do
        let(:preferred_username) { 'preferred_username@example.com' }
        let(:user) do
          user_with_pseudonym(username: preferred_username)
        end
        let(:user_ids) { [user.id] }

        before do
          3.times.each { pseudonym(user) }

          root_account.settings[:microsoft_sync_login_attribute] = 'preferred_username'
          root_account.save!
        end

        it 'returns an array mapping the user id with upn' do
          users_upns = subject.to_h

          expect(users_upns.size).to eq 1
          expect(users_upns[user.id]).to eq preferred_username
        end
      end

      context 'when the login_attribute=sis_user_id' do
        let(:sis_user_id) { '1021616' }
        let(:user) do
          user_with_pseudonym(sis_user_id: sis_user_id)
        end
        let(:user_ids) { [user.id] }

        before do
          (1..3).each { |i| pseudonym(user, sis_user_id: "#{sis_user_id}#{i}") }

          root_account.settings[:microsoft_sync_login_attribute] = 'sis_user_id'
          root_account.save!
        end

        it 'returns an array mapping the user id with upn' do
          users_upns = subject.to_h

          expect(users_upns.size).to eq 1
          expect(users_upns[user.id]).to eq sis_user_id
        end
      end

      context 'when the login_attribute=invalid' do
        let(:user_ids) { [1] }

        before do
          root_account.settings[:microsoft_sync_login_attribute] = 'invalid'
          root_account.save!
        end

        it 'raise an error' do
          expect { subject }.to raise_error(MicrosoftSync::InvalidOrMissingLoginAttributeConfig)
        end
      end
    end
  end
end
