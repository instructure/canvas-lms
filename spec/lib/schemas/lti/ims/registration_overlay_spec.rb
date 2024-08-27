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
#

describe Schemas::Lti::IMS::RegistrationOverlay do
  let(:valid) do
    {
      title: "foo",
      disabledScopes: ["https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly",],
      disabledSubs: ["foo"], # not sure what these are actually, we can make more stringent later if needed
      icon_url: "https://example.com/icon.png",
      launch_height: "100%",
      launch_width: "100%",
      disabledPlacements: ["course_navigation"],
      placements: [
        {
          type: "account_navigation",
          icon_url: "https://example.com/icon.png",
          label: "foo",
          launch_height: "100%",
          launch_width: "100%",
          default: "enabled",
        },
      ],
      description: "foo",
      privacy_level: "public",
    }
  end

  let(:top_level_fields) do
    %i[title icon_url launch_height launch_width description privacy_level]
  end

  def errs(**overrides)
    described_class.simple_validation_errors(valid.merge(overrides))
  end

  describe ".simple_validation_errors" do
    it "accepts a valid registration overlay" do
      expect(errs).to be_nil
    end

    it "accepts an empty hash (all fields are optional)" do
      expect(described_class.simple_validation_errors({})).to be_nil
    end

    it "allows all top-level fields to be null" do
      expect(errs(**top_level_fields.index_with { nil })).to be_nil
    end

    it "checks invalid types of all top-level fields" do
      top_level_fields.each do |field|
        expect(errs(field => true).first).to match a_string_matching(/#{field}/)
      end
    end

    it "checks invalid disabledScopes" do
      expect(errs(disabledScopes: ["foo"])).to match([a_string_matching(/disabledScopes/)])
    end

    it "checks invalid disabledPlacements" do
      expect(errs(disabledPlacements: ["foo"])).to match([a_string_matching(/disabledPlacements/)])
    end

    describe "placements field" do
      let(:placement_optional_fields) do
        %i[icon_url label launch_height launch_width default]
      end

      it "allows missing optional fields" do
        expect(errs(placements: [{ type: "account_navigation" }])).to be_nil
      end

      it "checks invalid placement types" do
        expect(errs(placements: [{ type: "foo" }])).to match([a_string_matching(/placements/)])
      end

      it "allows all optional fields to be null" do
        placements = [
          { type: "account_navigation" }.merge(placement_optional_fields.index_with { nil }),
        ]
        expect(errs(placements:)).to be_nil
      end

      it "checks invalid types of all placement fields" do
        base_placement = { type: "account_navigation" }
        placement_optional_fields.each do |field|
          placements = [base_placement.merge(field => true)]
          first_err = errs(placements:).first
          expect(first_err).to match a_string_matching(/#{field}/)
        end
      end
    end
  end
end
