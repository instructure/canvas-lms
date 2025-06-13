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

RSpec.describe ContentExportApiHelper do
  let(:context) { double("Context", content_exports:, quizzes:) }
  let(:content_exports) { double("ContentExports", build: export) }
  let(:quizzes) { double("Quizzes", exists?: true) }
  let(:course) { Course.build }
  let(:export) { ContentExport.build(course:) }
  let(:current_user) { User.build }
  let(:params) { ActionController::Parameters.new({ export_type: "zip", select: { assignments: [1] } }) }

  let(:processed_params) { "processed_content" }

  let(:job_progress) { Progress.build }

  before do
    allow(helper).to receive_messages(value_to_boolean: true, authorized_action: true, render: nil)
    allow(ContentMigration).to receive(:process_copy_params).and_return(processed_params)

    allow(Progress).to receive(:new).and_return(job_progress)

    allow(export).to receive_messages(
      save: true,
      save!: true,
      can_use_global_identifiers?: true,
      new_quizzes_page_enabled?: true,
      initialize_job_progress: true,
      quizzes2_build_assignment: true,
      export: true
    )
  end

  RSpec.shared_examples "export calling" do
    context "when export is waiting for external tool" do
      before do
        allow(export).to receive(:waiting_for_external_tool?).and_return(true)
      end

      it "initializes job progress" do
        expect(export).to receive(:initialize_job_progress)
        subject
      end

      it "does not call export" do
        expect(export).not_to receive(:export)
        subject
      end
    end

    context "when export is not waiting for external tool" do
      before do
        allow(export).to receive(:waiting_for_external_tool?).and_return(false)
      end

      it "initializes job progress" do
        expect(export).to receive(:initialize_job_progress)
        subject
      end

      it "calls export" do
        expect(export).to receive(:export)
        subject
      end
    end
  end

  describe "#create_content_export_from_api" do
    subject { helper.create_content_export_from_api(params, context, current_user) }

    context "when export_type is qti" do
      before do
        params[:export_type] = "qti"
      end

      it "creates a QTI export" do
        expect(subject.export_type).to eq(ContentExport::QTI)
      end

      context "when selective" do
        it "sets selected_content to the processed params" do
          expect(subject.selected_content).to eq(processed_params)
        end
      end

      context "when full" do
        before do
          params.delete(:select)
        end

        it "sets selected_content to all_quizzes if select is not present" do
          expect(subject.selected_content.deep_symbolize_keys).to eq({ all_quizzes: true })
        end
      end

      it_behaves_like "export calling"
    end

    context "when export_type is zip" do
      before do
        params[:export_type] = "zip"
      end

      it "creates a ZIP export" do
        result = subject
        expect(result.export_type).to eq(ContentExport::ZIP)
      end

      context "when selective" do
        it "sets selected_content to the processed params" do
          expect(subject.selected_content).to eq(processed_params)
        end
      end

      context "when full" do
        before { params.delete(:select) }

        it "sets selected_content to all_attachments if select is not present" do
          expect(subject.selected_content.deep_symbolize_keys).to eq({ all_attachments: true })
        end
      end

      it_behaves_like "export calling"
    end

    context "when export_type is quizzes2" do
      before do
        params[:export_type] = "quizzes2"
        params[:quiz_id] = "1"
      end

      it "creates a Quizzes2 export" do
        result = subject

        expect(result.export_type).to eq(ContentExport::QUIZZES2)
        expect(result.selected_content).to eq("1")
      end

      it "returns bad request if quiz_id is invalid" do
        params[:quiz_id] = nil

        expect(helper).to receive(:render).with(json: { message: "quiz_id required and must be a valid ID" }, status: :bad_request)

        subject
      end

      it "returns not found if quiz does not exist" do
        allow(context).to receive(:quizzes).and_return(quizzes)
        allow(quizzes).to receive(:exists?).and_return(false)
        expect(helper).to receive(:render).with(json: { message: "Quiz could not be found" }, status: :bad_request)

        subject
      end

      it_behaves_like "export calling"
    end

    context "when export_type is common_cartridge" do
      before do
        params[:export_type] = "common_cartridge"
      end

      it "creates a Common Cartridge export" do
        result = subject
        expect(result.export_type).to eq(ContentExport::COMMON_CARTRIDGE)
        expect(result.selected_content).to eq(processed_params)
      end

      context "when selective" do
        it "sets selected_content to the processed params" do
          expect(subject.selected_content).to eq(processed_params)
        end

        it "calls content export's #prepare_new_quizzes_export with selected assignments" do
          expect(export).to receive(:prepare_new_quizzes_export).with([1])
          subject
        end
      end

      context "when full" do
        before do
          params.delete(:select)
        end

        it "sets selected_content to all_attachments if select is not present" do
          expect(subject.selected_content.deep_symbolize_keys).to eq({ everything: true })
        end

        it "calls content export's #prepare_new_quizzes_export with nil" do
          expect(export).to receive(:prepare_new_quizzes_export).with(nil)
          subject
        end
      end

      it_behaves_like "export calling"
    end

    context "when authorized_action returns false" do
      before do
        allow(helper).to receive(:authorized_action).and_return(false)
      end

      it "does not proceed with export creation" do
        expect(subject).to be_nil
      end
    end
  end
end
