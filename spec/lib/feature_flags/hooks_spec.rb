# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

describe FeatureFlags::Hooks do
  describe ".only_admins_can_enable_block_content_editor_during_eap" do
    let(:transitions) { {} }
    let(:user) { user_model }
    let(:course) { course_model }
    let(:account) { account_model }

    context "when context is a Course" do
      context "when block_content_editor feature is disabled" do
        before do
          allow(course.account).to receive(:feature_enabled?).with(:block_content_editor).and_return(false)
        end

        it "locks both on and off transitions regardless of user permissions" do
          allow(course).to receive(:account_membership_allows).with(user).and_return(true)

          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, course, nil, transitions)

          expect(transitions["on"]).to be_present
          expect(transitions["off"]).to be_present
          expect(transitions["on"]["locked"]).to be true
          expect(transitions["off"]["locked"]).to be true
        end
      end

      context "when block_content_editor feature is enabled" do
        before do
          allow(course.account).to receive(:feature_enabled?).with(:block_content_editor).and_return(true)
        end

        context "when user is admin" do
          before do
            allow(course).to receive(:account_membership_allows).with(user).and_return(true)
          end

          it "does not lock transitions" do
            FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, course, nil, transitions)

            expect(transitions).to be_empty
          end
        end

        context "when user is not admin" do
          before do
            allow(course).to receive(:account_membership_allows).with(user).and_return(false)
          end

          it "locks both on and off transitions" do
            FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, course, nil, transitions)

            expect(transitions["on"]).to be_present
            expect(transitions["off"]).to be_present
            expect(transitions["on"]["locked"]).to be true
            expect(transitions["off"]["locked"]).to be true
          end
        end
      end
    end

    context "when context is not a Course" do
      it "does not lock transitions for Account context" do
        allow(account).to receive(:account_membership_allows).with(user).and_return(false)
        allow(account).to receive(:feature_enabled?).with(:block_content_editor).and_return(false)

        FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, account, nil, transitions)

        expect(transitions).to be_empty
      end

      it "does not lock transitions for other context types" do
        user_context = user_model

        FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, user_context, nil, transitions)

        expect(transitions).to be_empty
      end
    end

    context "when context is nil" do
      it "does not lock transitions" do
        FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, nil, nil, transitions)

        expect(transitions).to be_empty
      end
    end

    context "edge cases" do
      it "handles nil user gracefully when feature is disabled" do
        allow(course).to receive(:account_membership_allows).with(nil).and_return(false)
        allow(course.account).to receive(:feature_enabled?).with(:block_content_editor).and_return(false)

        FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(nil, course, nil, transitions)

        expect(transitions["on"]["locked"]).to be true
        expect(transitions["off"]["locked"]).to be true
      end

      it "handles nil user gracefully when feature is enabled but user lacks permissions" do
        allow(course).to receive(:account_membership_allows).with(nil).and_return(false)
        allow(course.account).to receive(:feature_enabled?).with(:block_content_editor).and_return(true)

        FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(nil, course, nil, transitions)

        expect(transitions["on"]["locked"]).to be true
        expect(transitions["off"]["locked"]).to be true
      end
    end
  end
end
