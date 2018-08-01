#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_dependency "users/creation_notify_policy"

module Users
  describe CreationNotifyPolicy do
    describe "#is_self_registration?" do
      it "is true when forced" do
        policy = CreationNotifyPolicy.new(false, {force_self_registration: '1'})
        expect(policy.is_self_registration?).to be(true)
      end

      it "is opposite the management ability provide" do
        policy = CreationNotifyPolicy.new(false, {})
        expect(policy.is_self_registration?).to be(true)
        policy = CreationNotifyPolicy.new(true, {})
        expect(policy.is_self_registration?).to be(false)
      end
    end

    describe "#dispatch!" do
      let(:user){ double() }
      let(:pseudonym) { double() }
      let(:channel){ double() }

      context "for self_registration" do
        let(:policy){ CreationNotifyPolicy.new(true, {force_self_registration: true}) }
        before{ allow(channel).to receive_messages(has_merge_candidates?: false) }

        it "sends confirmation notification" do
          expect(pseudonym).to receive(:send_confirmation!)
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(true)
        end
      end

      context "when the user isn't yet registered" do
        before do
          allow(user).to receive_messages(registered?: false)
          allow(channel).to receive_messages(has_merge_candidates?: false)
        end

        it "sends the registration notification if should notify" do
          policy = CreationNotifyPolicy.new(true, {send_confirmation: '1'})
          expect(pseudonym).to receive(:send_registration_notification!)
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(true)
        end

        it "doesnt send the registration notification if shouldnt notify" do
          policy = CreationNotifyPolicy.new(true, {send_confirmation: '0'})
          expect(pseudonym).to receive(:send_registration_notification!).never
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(false)
        end
      end

      context "when the user is registered" do
        before{ allow(user).to receive_messages(registered?: true) }
        let(:policy){ CreationNotifyPolicy.new(true, {}) }

        it "sends the merge notification if there are merge candidates" do
          allow(channel).to receive_messages(has_merge_candidates?: true)
          expect(channel).to receive(:send_merge_notification!)
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(false)
        end

        it "does nothing without merge candidates" do
          allow(channel).to receive_messages(has_merge_candidates?: false)
          expect(channel).to receive(:send_merge_notification!).never
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(false)
        end
      end

    end
  end
end
