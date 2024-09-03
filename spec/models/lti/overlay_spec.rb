# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Lti::Overlay do
  describe "create!" do
    let(:account) { account_model }
    let(:updated_by) { user_model }
    let(:registration) { lti_registration_model(account:) }
    let(:data) { { "hello" => "world" } }

    context "without account" do
      it "fails" do
        expect { Lti::Overlay.create!(registration:, updated_by:, data:) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "without registration" do
      it "fails" do
        expect { Lti::Overlay.create!(account:, updated_by:, data:) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "without updated_by" do
      it "fails" do
        expect { Lti::Overlay.create!(registration:, account:, data:) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "with all valid attributes" do
      it "succeeds" do
        expect { Lti::Overlay.create!(registration:, account:, updated_by:, data:) }.not_to raise_error
      end
    end

    context "with cross-shard registration" do
      specs_require_sharding

      let(:account) { @shard2.activate { account_model } }
      let(:registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin) } }
      let(:updated_by) { @shard2.activate { user_model } }

      it "succeeds" do
        expect { @shard2.activate { Lti::Overlay.create!(registration:, account:, updated_by:) } }.not_to raise_error
      end
    end
  end
end
