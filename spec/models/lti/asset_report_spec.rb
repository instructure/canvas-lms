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

RSpec.describe Lti::AssetReport do
  describe "validations" do
    subject { lti_asset_report_model }

    it { is_expected.to be_valid }

    describe "associations" do
      it "validates the compatibity of the asset with the processor" do
        model = lti_asset_report_model
        expect(model.asset).to receive(:compatible_with_processor?).with(model.asset_processor).and_return(false)
        expect { model.save! }.to raise_error(ActiveRecord::RecordInvalid, /internal error.*compatible with processor/)
      end
    end

    describe "1EdTech spec fields" do
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

  describe ".info_for_display_by_submission" do
    subject do
      # Ensure the factory objects are created
      [rep1aIi, rep1aIii, rep1bIi, rep2aIi, rep2aIIi]
      Lti::AssetReport.info_for_display_by_submission(submission_ids: [sub1.id, sub2.id])
    end

    let(:course) { course_factory }
    let(:assignment) { assignment_model(course:) }
    let(:processorI) { lti_asset_processor_model(assignment:) }
    let(:processorII) { lti_asset_processor_model(assignment:) }

    # Student 1
    let(:student1) { student_in_course(course:).user }
    let(:sub1) { assignment.submissions.find_by(user: student1) }
    let(:att1a) { attachment_model(context: student1) }
    let(:asset1a) { lti_asset_model(submission: sub1, attachment: att1a) }
    let(:att1b) { attachment_model(context: student1) }
    let(:asset1b) { lti_asset_model(submission: sub1, attachment: att1b) }

    # Student 2
    let(:student2) { student_in_course(course:).user }
    let(:sub2) { assignment.submissions.find_by(user: student2) }
    let(:att2a) { attachment_model(context: student2) }
    let(:asset2a) { lti_asset_model(submission: sub2, attachment: att2a) }

    # Student 1 (submission 1) reports:
    # Student 1, attachment a (1a), processor I, report type i
    let(:rep1aIi) { lti_asset_report_model(asset: asset1a, asset_processor: processorI, report_type: "type_i") }
    let(:rep1aIii) { lti_asset_report_model(asset: asset1a, asset_processor: processorI, report_type: "type_ii") }
    let(:rep1bIi) { lti_asset_report_model(asset: asset1b, asset_processor: processorI) }

    # Student 2 (submission 2) reports:
    let(:rep2aIi) { lti_asset_report_model(asset: asset2a, asset_processor: processorI) }
    let(:rep2aIIi) { lti_asset_report_model(asset: asset2a, asset_processor: processorII) }

    let(:by_submission) { subject[:reports_by_submission] }

    it "includes the asset processor ID in the asset_processor_ids set" do
      expect(subject[:asset_processor_ids]).to match_array([processorI.id, processorII.id])
    end

    it "organizes reports by submission and attachment" do
      expect(by_submission.keys).to match_array([sub1.id, sub2.id])
      expect(by_submission[sub1.id]).to \
        match({
                by_attachment: {
                  att1a.id => { processorI.id => an_instance_of(Array) },
                  att1b.id => { processorI.id => an_instance_of(Array) },
                }
              })
      expect(by_submission[sub2.id]).to \
        match({
                by_attachment: {
                  att2a.id => {
                    processorI.id => an_instance_of(Array),
                    processorII.id => an_instance_of(Array)
                  }
                }
              })

      sub1_reports = by_submission[sub1.id][:by_attachment]
      sub2_reports = by_submission[sub2.id][:by_attachment]

      expect(sub1_reports[att1a.id][processorI.id].map { _1[:id] }).to \
        match_array([rep1aIi.id, rep1aIii.id])
      expect(sub1_reports[att1b.id][processorI.id].map { _1[:id] }).to \
        match_array([rep1bIi.id])
      expect(sub2_reports[att2a.id][processorI.id].map { _1[:id] }).to \
        match_array([rep2aIi.id])
      expect(sub2_reports[att2a.id][processorII.id].map { _1[:id] }).to \
        match_array([rep2aIIi.id])
    end

    it "includes report details in the result" do
      r = by_submission[sub1.id][:by_attachment][att1a.id][processorI.id].find do |r|
        r[:id] == rep1aIi.id
      end
      expect(r).to eq(rep1aIi.info_for_display)
    end

    context "when some reports are deleted" do
      before { rep2aIIi.destroy! }

      it "does not include the reports or their processor ids" do
        expect(subject[:asset_processor_ids]).not_to include(processorII.id)
        expect(subject[:reports_by_submission][sub2.id][:by_attachment][att2a.id].keys).not_to \
          include(processorII.id)
      end
    end

    context "when a processor is deleted" do
      before { processorII.destroy! }

      it "does not include the reports or their processor ids" do
        expect(subject[:asset_processor_ids]).not_to include(processorII.id)
        expect(subject[:reports_by_submission][sub2.id][:by_attachment][att2a.id].keys).not_to \
          include(processorII.id)
      end
    end

    it "returns empty results when no matching reports exist" do
      rep1aIi
      result = Lti::AssetReport.info_for_display_by_submission(submission_ids: Submission.last.id + 1)
      expect(result[:asset_processor_ids]).to be_empty
      expect(result[:reports_by_submission]).to be_empty
    end

    context "when submission_ids is nil" do
      it "returns empty results" do
        rep1aIi
        result = Lti::AssetReport.info_for_display_by_submission(submission_ids: nil)
        expect(result[:asset_processor_ids]).to be_empty
        expect(result[:reports_by_submission]).to be_empty
      end
    end

    context "when submission_ids is empty" do
      it "returns empty results" do
        rep1aIi
        result = Lti::AssetReport.info_for_display_by_submission(submission_ids: [])
        expect(result[:asset_processor_ids]).to be_empty
        expect(result[:reports_by_submission]).to be_empty
      end
    end
  end

  describe "#info_for_display" do
    subject { report.info_for_display }

    let(:report) do
      lti_asset_report_model(
        title: "My cool report",
        comment: "What a great report",
        indication_color: "#008800",
        indication_alt: "WOW",
        result: "8/10",
        error_code: "MYERRORCODE",
        processing_progress: "Processed"
      )
    end

    it "returns a hash with the report's details" do
      expect(subject[:id]).to eq(report.id)
      expect(subject[:title]).to eq("My cool report")
      expect(subject[:comment]).to eq("What a great report")
      expect(subject[:result]).to eq("8/10")
      expect(subject).to_not have_key(:result_truncated)
      expect(subject[:indication_color]).to eq("#008800")
      expect(subject[:indication_alt]).to eq("WOW")
      expect(subject[:error_code]).to eq("MYERRORCODE")
      expect(subject[:processing_progress]).to eq("Processed")
    end

    it "truncates result_truncated to 16 characters" do
      report.update!(result: "12345678901234567890")
      expect(subject[:result_truncated]).to eq("123456789012345…")
      expect(subject[:result]).to eq("12345678901234567890")
    end

    it "includes launch_url_path for processed reports" do
      expect(subject[:launch_url_path]).to \
        eq "/asset_processors/#{report.lti_asset_processor_id}/reports/#{report.id}/launch"
    end
  end

  describe "#resubmit_url_path" do
    let(:processing_progress) { "Failed" }
    let(:error_code) { "MYERRORCODE" }
    let(:standard_report) { lti_asset_report_model(processing_progress:, error_code:) }

    context "when processing_progress is Failed" do
      ["EULA_NOT_ACCEPTED", "DOWNLOAD_FAILED"].each do |error_code|
        context "when error_code is #{error_code}" do
          let(:error_code) { error_code }

          it "returns a resubmit URL path" do
            expect(standard_report.resubmit_url_path).to eq(
              "/api/lti/asset_processors/#{standard_report.lti_asset_processor_id}/notices/#{standard_report.asset.submission.user_id}"
            )
          end
        end
      end

      context "when error_code does not need action" do
        it "resubmit_url_path is nil" do
          expect(standard_report.resubmit_url_path).to be_nil
        end
      end
    end

    context "when processing_progress is PendingManual" do
      let(:processing_progress) { "PendingManual" }

      it "returns a resubmit URL path" do
        expect(standard_report.resubmit_url_path).to eq(
          "/api/lti/asset_processors/#{standard_report.lti_asset_processor_id}/notices/#{standard_report.asset.submission.user_id}"
        )
      end
    end

    context "when processing_progress is not Failed or PendingManual" do
      let(:processing_progress) { "Processed" }

      it "returns nil" do
        expect(standard_report.resubmit_url_path).to be_nil
      end
    end
  end
end
