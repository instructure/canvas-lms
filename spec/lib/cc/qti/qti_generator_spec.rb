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
end
