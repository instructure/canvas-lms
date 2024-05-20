# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "QTI Generator" do
  def qti_generator
    quiz_with_question_group_pointing_to_question_bank
    @rn = Object.new
    allow(@rn).to receive_messages(user: {}, course: @course, export_dir: {})
    allow(@rn).to receive(:export_object?).with(anything).and_return(true)
    @qg = CC::Qti::QtiGenerator.new @rn, nil, nil
  end

  describe ".generate_banks" do
    it "calls generate_question_bank for every account bank" do
      qti_generator
      allow(@qg).to receive(:generate_question_bank) do |bank|
        expect(bank.class.to_s).to eq "AssessmentQuestionBank"
      end
      @result = @qg.generate_banks [@bank.id]
    end
  end

  describe ".generate_bank" do
    before do
      qti_generator
      allow(NewQuizzesFeaturesHelper).to receive(:new_quizzes_bank_migrations_enabled?).and_return(true)
    end

    it "generates qti xml with the correct metadata" do
      doc = Builder::XmlMarkup.new(target: +"", indent: 2)
      course = course_model(name: "Test Course", uuid: "course_uuid")
      bank = course.assessment_question_banks.create!(title: "Test Bank")

      expected_xml =
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">
            <objectbank ident="somemigrationid">
              <qtimetadata>
                <qtimetadatafield>
                  <fieldlabel>bank_title</fieldlabel>
                  <fieldentry>Test Bank</fieldentry>
                </qtimetadatafield>
                <qtimetadatafield>
                  <fieldlabel>bank_type</fieldlabel>
                  <fieldentry>Course</fieldentry>
                </qtimetadatafield>
                <qtimetadatafield>
                  <fieldlabel>bank_context_uuid</fieldlabel>
                  <fieldentry>course_uuid</fieldentry>
                </qtimetadatafield>
              </qtimetadata>
            </objectbank>
          </questestinterop>
        XML

      expect(@qg.generate_bank(doc, bank, "somemigrationid")).to eq expected_xml
    end
  end

  describe "generate new quizzes" do
    subject do
      doc = Builder::XmlMarkup.new(target: +"", indent: 2)
      doc.manifest do |manifest_node|
        manifest_node.resources do |resource_node|
          CC::Qti::QtiGenerator.generate_qti(@manifest, resource_node, @html_exporter)
        end
      end
    end

    before do
      @copy_from = course_model
      @from_teacher = @user
      @copy_to = course_model
      @content_export = @copy_from.content_exports.build
      @content_export.export_type = ContentExport::COMMON_CARTRIDGE
      @content_export.user = @from_teacher

      @exporter = CC::CCExporter.new(@content_export, course: @copy_from, user: @from_teacher)
      @exporter.send(:create_export_dir)
      @doc = Builder::XmlMarkup.new(target: +"", indent: 2)
      @manifest = CC::Manifest.new(@exporter)
      @html_exporter = CC::CCHelper::HtmlContentExporter.new(@copy_from, @from_teacher)
    end

    context "when the FF's quizzes_next and new_quizzes_common_cartridge are not enabled" do
      before do
        allow(@course).to receive(:feature_enabled?).and_call_original
        allow_any_instance_of(Course).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
        Account.site_admin.disable_feature!(:new_quizzes_common_cartridge)
      end

      it "does not load new quizzes into the Common Cartridge package" do
        expect_any_instance_of(CC::Qti::NewQuizzesGenerator).not_to receive(:write_new_quizzes_content)
        subject
      end
    end

    context "when the FF's new_quizzes_common_cartridge is not enabled" do
      before do
        allow(@course).to receive(:feature_enabled?).and_call_original
        allow_any_instance_of(Course).to receive(:feature_enabled?).with(:quizzes_next).and_return(false)
        Account.site_admin.disable_feature!(:new_quizzes_common_cartridge)
      end

      it "does not load new quizzes into the Common Cartridge package" do
        expect_any_instance_of(CC::Qti::NewQuizzesGenerator).not_to receive(:write_new_quizzes_content)
        subject
      end
    end

    context "when the FF's quizzes_next and new_quizzes_common_cartridge are enabled" do
      before do
        allow(@course).to receive(:feature_enabled?).and_call_original
        allow_any_instance_of(Course).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
        Account.site_admin.enable_feature!(:new_quizzes_common_cartridge)
      end

      context "and the content export requires content from New Quizzes" do
        before do
          @content_export.settings[:new_quizzes_export_state] = "completed"
          @content_export.settings[:new_quizzes_export_url] =
            Rails.root.join("spec/lib/cc/qti/fixtures/nq_common_cartridge_export.zip").to_s
          @content_export.save!
        end

        it "loads new quizzes into the Common Cartridge package" do
          expect_any_instance_of(CC::Qti::NewQuizzesGenerator).to receive(:write_new_quizzes_content)
          subject
        end
      end

      context "and the content export does not require content from New Quizzes" do
        it "does not load new quizzes into the Common Cartridge package" do
          expect_any_instance_of(CC::Qti::NewQuizzesGenerator).not_to receive(:write_new_quizzes_content)
          subject
        end
      end

      context "and the content export is not of the type 'common_cartridge'" do
        before do
          @content_export.export_type = ContentExport::COURSE_COPY
          @content_export.save!
        end

        it "does not load new quizzes into the Common Cartridge package" do
          expect_any_instance_of(CC::Qti::NewQuizzesGenerator).not_to receive(:write_new_quizzes_content)
          subject
        end
      end
    end
  end
end
