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

require "spec_helper"

describe DataFixup::ChangeImmersiveReaderAllowedOnToOn do
  describe ".run" do
    def set_immersive_reader_flag(account, state)
      FeatureFlag.find_or_create_by(
        context_id: account.id,
        context_type: "Account",
        feature: "immersive_reader_wiki_pages",
        state:
      )
    end

    context "when the account is the SiteAdmin account" do
      let(:account) { Account.site_admin }

      before do
        @flag = set_immersive_reader_flag(account, Feature::STATE_DEFAULT_ON)
      end

      it "leaves the feature flag in its current state" do
        expect do
          DataFixup::ChangeImmersiveReaderAllowedOnToOn.run
        end.not_to change {
          @flag.reload.state
        }
      end
    end

    context "when a root account has immersive_reader_wiki_pages allowed and off" do
      let(:account) { Account.create! }

      before do
        @flag = set_immersive_reader_flag(account, Feature::STATE_DEFAULT_OFF)
      end

      it "leaves the feature flag as disabled" do
        expect do
          DataFixup::ChangeImmersiveReaderAllowedOnToOn.run
        end.not_to change {
          @flag.reload.state
        }
      end
    end

    context "when a root account has immersive_reader_wiki_pages allowed and on" do
      let(:account) { Account.create! }

      before do
        @flag = set_immersive_reader_flag(account, Feature::STATE_DEFAULT_ON)
      end

      it "changes the feature flag to enabled" do
        expect do
          DataFixup::ChangeImmersiveReaderAllowedOnToOn.run
        end.to change {
          @flag.reload.state
        }.from(Feature::STATE_DEFAULT_ON).to(Feature::STATE_ON)
      end
    end

    context "when a root account has immersive_reader_wiki_pages off" do
      let(:account) { Account.create! }

      before do
        @flag = set_immersive_reader_flag(account, Feature::STATE_OFF)
      end

      it "leaves the feature flag as disabled" do
        expect do
          DataFixup::ChangeImmersiveReaderAllowedOnToOn.run
        end.not_to change {
          @flag.reload.state
        }
      end
    end

    context "when a root account has immersive_reader_wiki_pages on" do
      let(:account) { Account.create! }

      before do
        @flag = set_immersive_reader_flag(account, Feature::STATE_ON)
      end

      it "leaves the feature flag as enabled" do
        expect do
          DataFixup::ChangeImmersiveReaderAllowedOnToOn.run
        end.not_to change {
          @flag.reload.state
        }
      end
    end
  end
end
