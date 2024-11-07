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
  let(:account) { account_model }
  let(:updated_by) { user_model }
  let(:registration) { lti_registration_model(account:) }
  let(:data) { { "title" => "Hello World!" } }

  describe "create_version callback" do
    let(:overlay) { Lti::Overlay.create!(account:, registration:, updated_by:, data:) }

    it "doesn't create a new version if data hasn't changed" do
      expect { overlay.update!(data:) }.not_to change { overlay.lti_overlay_versions.count }
      expect { overlay.update!(updated_by: user_model) }.not_to change { overlay.lti_overlay_versions.count }
    end

    it "creates a new version if data is modified" do
      expect { overlay.update!(data: { "description" => "a description" }) }.to change { overlay.lti_overlay_versions.count }.by(1)
    end

    it "stores a diff of the old and new data" do
      overlay.update!(data: { "description" => "a description" })

      expect(Lti::OverlayVersion.last.diff).to eq([
                                                    ["-", "title", "Hello World!"],
                                                    ["+", "description", "a description"]
                                                  ])
    end

    it "doesn't care about ordering in arrays" do
      expect do
        overlay.update!(data: overlay.data.merge({ "disabled_placements" => ["course_navigation", "account_navigation"] }))
      end.to change { overlay.lti_overlay_versions.count }.by(1)

      expect { overlay.update!(data: overlay.data.merge({ "disabled_placements" => ["account_navigation", "course_navigation"] })) }.not_to change { overlay.lti_overlay_versions.count }
    end

    it "doesn't create a new version if updated_by is updated but data isn't" do
      expect { overlay.update!(updated_by: user_model) }.not_to change { overlay.lti_overlay_versions.count }
    end
  end

  describe "create!" do
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

    context "with invalid data" do
      let(:data) do
        {
          disabled_placements: ["invalid_placement"]
        }.deep_stringify_keys
      end

      it "fails" do
        expect { Lti::Overlay.create!(registration:, account:, updated_by:, data:) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "returns the schema errors" do
        overlay = Lti::Overlay.build(registration:, account:, updated_by:, data:)
        overlay.save

        expect(JSON.parse(overlay.errors[:data].first).first).to include "is not one of"
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
