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

RSpec.describe Lti::AssetReport, type: :model do
  describe "validations" do
    subject { lti_asset_report_model }

    it { is_expected.to be_valid }

    describe "associations" do
      it { is_expected.to validate_presence_of(:asset_processor) }
      it { is_expected.to validate_presence_of(:asset) }

      it "validates the compatibity of the asset with the processor" do
        model = lti_asset_report_model
        expect(model.asset).to receive(:compatible_with_processor?).with(model.asset_processor).and_return(false)
        expect { model.save! }.to raise_error(ActiveRecord::RecordInvalid, /internal error.*compatible with processor/)
      end
    end

    describe "1EdTech spec fields" do
      it { is_expected.to validate_presence_of(:timestamp) }
      it { is_expected.to validate_length_of(:report_type).is_at_most(1024) }
      it { is_expected.to validate_presence_of(:report_type) }
      it { is_expected.to validate_length_of(:title).is_at_most(1.kilobyte) }
      it { is_expected.to validate_length_of(:comment).is_at_most(64.kilobytes) }
      it { is_expected.to validate_numericality_of(:score_given).is_greater_than_or_equal_to(0).allow_nil }
      it { is_expected.to validate_numericality_of(:score_maximum).is_greater_than_or_equal_to(0).allow_nil }
      it { is_expected.to validate_inclusion_of(:priority).in_array(Lti::AssetReport::PRIORITIES) }
      it { is_expected.to validate_length_of(:error_code).is_at_most(1024) }
      it { is_expected.to validate_length_of(:indication_alt).is_at_most(1024) }

      it "rejects empty strings in all fields" do
        %i[report_type title comment indication_alt error_code].each do |field|
          expect do
            lti_asset_report_model(field => "")
          end.to raise_error(ActiveRecord::RecordInvalid, /#{field.to_s.humanize} can't be blank|#{field.to_s.humanize} is too short/)
        end
      end

      it "allows title, comment, indication_alt, and error_code to be nil" do
        %i[title comment indication_alt error_code].each do |field|
          expect(lti_asset_report_model(field => nil)).to be_valid
        end
      end

      it "is invalid if score_given is provided without score_maximum" do
        expect do
          lti_asset_report_model(score_given: 1, score_maximum: nil)
        end.to raise_error(ActiveRecord::RecordInvalid, /Score maximum must be present if score_given is present/)
        expect(lti_asset_report_model(score_given: nil, score_maximum: 1)).to be_valid
        expect(lti_asset_report_model(score_given: nil, score_maximum: nil)).to be_valid
        expect(lti_asset_report_model(score_given: 1, score_maximum: 1)).to be_valid
      end

      it "requires indication_color to be a hex code" do
        expect(lti_asset_report_model(indication_color: "#123456")).to be_valid
        %w[#1234567 123456 #12345 white].each do |color|
          expect do
            lti_asset_report_model(indication_color: color)
          end.to raise_error(ActiveRecord::RecordInvalid, /Indication color must be a valid hex code/)
        end
      end

      it "rejects fields in 'extensions' that do not have a url scheme" do
        expect(lti_asset_report_model(extensions: { "http://valid.url" => "value" })).to be_valid
        expect(lti_asset_report_model(extensions: { "https://valid.url" => "value" })).to be_valid
        expect do
          lti_asset_report_model(extensions: { "invalid.url" => "value" })
        end.to raise_error(ActiveRecord::RecordInvalid, /invalid.url.*extensions property keys must be namespaced \(URIs\)/)

        expect do
          lti_asset_report_model(extensions: { "invalid.url" => "value", "https://valid.url" => "value" })
        end.to raise_error(ActiveRecord::RecordInvalid, /extensions property keys must be namespaced \(URIs\)/)
      end
    end

    it "raises an error if multiple active asset reports are created for the same asset processor, lti_asset, and report type" do
      ar = lti_asset_report_model
      attrs = ar.slice("asset_processor", "asset", "report_type")

      expect { lti_asset_report_model(attrs) }.to \
        raise_error(ActiveRecord::RecordInvalid, /Report type has already been taken/)

      # make sure by changing one field the model can be created
      lti_asset_report_model(attrs.merge("report_type" => "new_report_type"))
      lti_asset_report_model(attrs.merge("workflow_state" => "deleted"))
      new_asset = lti_asset_model(submission: ar.asset.submission)
      lti_asset_report_model(attrs.merge("lti_asset_id" => new_asset.id))
    end

    it "allows an asset report to be created with the same report type if the previous one is deleted" do
      ar = lti_asset_report_model
      attrs = ar.slice("asset_processor", "asset", "report_type")
      ar.update!(workflow_state: "deleted")
      expect(lti_asset_report_model(attrs)).to be_valid
    end

    it "sets the default processing progress if the given progress is not recognized" do
      expect(lti_asset_report_model(processing_progress: "Unrecognized")).to have_attributes(processing_progress: "NotReady")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:asset_processor).required }
    it { is_expected.to belong_to(:asset).required }
  end

  describe "PRIORITIES" do
    it "enumerates all priorities" do
      expect(Lti::AssetReport::PRIORITIES).to eq((0..5).to_a)
    end
  end

  describe "PROGRESSES" do
    it "enumerates all progresses listed in the spec" do
      expect(Lti::AssetReport::PROGRESSES).to match_array(
        %w[Processed Processing Pending PendingManual Failed NotProcessed NotReady]
      )
    end
  end
end
