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

describe CC::Qti::MigrationIdsReplacer do
  subject { described_class.new(manifest, new_quizzes_migration_ids_map) }

  before do
    @copy_from = course_model
    @from_teacher = @user
    @copy_to = course_model
    @content_export = @copy_from.content_exports.build
    @content_export.global_identifiers = true
    @content_export.export_type = ContentExport::COMMON_CARTRIDGE
    @content_export.user = @from_teacher
    @content_export.settings[:new_quizzes_export_url] =
      Rails.root.join("spec/lib/cc/qti/fixtures/nq_common_cartridge_export.zip").to_s
    @exporter = CC::CCExporter.new(@content_export, course: @copy_from, user: @from_teacher)
    @exporter.send(:create_export_dir)
    @manifest = CC::Manifest.new(@exporter)
    @doc = Builder::XmlMarkup.new(target: +"", indent: 2)
    @new_quiz_1 = @course.assignments.create!(title: "New Quiz 1", submission_types: "external_tool")
    @new_quiz_2 = @course.assignments.create!(title: "New Quiz 2", submission_types: "external_tool")
  end

  let(:manifest) { CC::Manifest.new(@exporter) }
  let(:new_quizzes_migration_ids_map) do
    {
      "g7a6297c8c5fe5c3dabc42d0ee182dcb8" => { "external_assignment_id" => @new_quiz_1.id },
      "gdbb1b3860016ed4d2392d017a493f0ec" => { "external_assignment_id" => @new_quiz_2.id }

    }
  end

  describe "#replace_in_xml" do
    context "when the xml is an IMS manifest" do
      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <resources>
            <resource identifier="g7a6297c8c5fe5c3dabc42d0ee182dcb8" type="imsqti_xmlv1p2/imscc_xmlv1p1/assessment">
              <file href="g7a6297c8c5fe5c3dabc42d0ee182dcb8/assessment_qti.xml"/>
              <dependency identifierref="if659b73a48b08b4d0f23d47a36278073"/>
            </resource>
            <resource identifier="if659b73a48b08b4d0f23d47a36278073" type="associatedcontent/imscc_xmlv1p1/learning-application-resource" href="g7a6297c8c5fe5c3dabc42d0ee182dcb8/assessment_meta.xml">
              <file href="g7a6297c8c5fe5c3dabc42d0ee182dcb8/assessment_meta.xml"/>
              <file href="non_cc_assessments/g7a6297c8c5fe5c3dabc42d0ee182dcb8.xml.qti"/>
            </resource>
            <resource identifier="gdbb1b3860016ed4d2392d017a493f0ec" type="imsqti_xmlv1p2/imscc_xmlv1p1/assessment">
              <file href="gdbb1b3860016ed4d2392d017a493f0ec/assessment_qti.xml"/>
              <dependency identifierref="ifa97a69bc35caaad4b1b3e22c29ff9c0"/>
            </resource>
            <resource identifier="ifa97a69bc35caaad4b1b3e22c29ff9c0" type="associatedcontent/imscc_xmlv1p1/learning-application-resource" href="gdbb1b3860016ed4d2392d017a493f0ec/assessment_meta.xml">
              <file href="gdbb1b3860016ed4d2392d017a493f0ec/assessment_meta.xml"/>
              <file href="non_cc_assessments/gdbb1b3860016ed4d2392d017a493f0ec.xml.qti"/>
            </resource>
          </resources>
        XML
      end

      it "replaces migration IDs appropriately" do
        expected_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <resources>
            <resource identifier="#{CC::CCHelper.create_key(@new_quiz_1, global: true)}" type="imsqti_xmlv1p2/imscc_xmlv1p1/assessment">
              <file href="#{CC::CCHelper.create_key(@new_quiz_1, global: true)}/assessment_qti.xml"/>
              <dependency identifierref="if659b73a48b08b4d0f23d47a36278073"/>
            </resource>
            <resource identifier="if659b73a48b08b4d0f23d47a36278073" type="associatedcontent/imscc_xmlv1p1/learning-application-resource" href="#{CC::CCHelper.create_key(@new_quiz_1, global: true)}/assessment_meta.xml">
              <file href="#{CC::CCHelper.create_key(@new_quiz_1, global: true)}/assessment_meta.xml"/>
              <file href="non_cc_assessments/#{CC::CCHelper.create_key(@new_quiz_1, global: true)}.xml.qti"/>
            </resource>
            <resource identifier="#{CC::CCHelper.create_key(@new_quiz_2, global: true)}" type="imsqti_xmlv1p2/imscc_xmlv1p1/assessment">
              <file href="#{CC::CCHelper.create_key(@new_quiz_2, global: true)}/assessment_qti.xml"/>
              <dependency identifierref="ifa97a69bc35caaad4b1b3e22c29ff9c0"/>
            </resource>
            <resource identifier="ifa97a69bc35caaad4b1b3e22c29ff9c0" type="associatedcontent/imscc_xmlv1p1/learning-application-resource" href="#{CC::CCHelper.create_key(@new_quiz_2, global: true)}/assessment_meta.xml">
              <file href="#{CC::CCHelper.create_key(@new_quiz_2, global: true)}/assessment_meta.xml"/>
              <file href="non_cc_assessments/#{CC::CCHelper.create_key(@new_quiz_2, global: true)}.xml.qti"/>
            </resource>
          </resources>
        XML

        expect(subject.replace_in_xml(xml)).to eq(expected_xml)
      end
    end

    context "when the xml contains a quiz object" do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <quiz xmlns="http://canvas.instructure.com/xsd/cccv1p0" xmlns:xsi="http://canvas.instructure.com/xsd/cccv1p0 https://canvas.instructure.com/xsd/cccv1p0.xsd" identifier="g7a6297c8c5fe5c3dabc42d0ee182dcb8">
            <title>my new quiz</title>
            <description/>
            <due_at/>
            <lock_at/>
            <unlock_at/>
            <shuffle_questions>false</shuffle_questions>
            <assignment identifier="b6aa97bfb1c6543f2560ab12f4e28a47">
              <title>my new quiz</title>
              <due_at/>
              <lock_at/>
              <unlock_at/>
              <quiz_identifierref>g7a6297c8c5fe5c3dabc42d0ee182dcb8</quiz_identifierref>
              <post_policy>
                <post_manually>false</post_manually>
              </post_policy>
              <assignment_group_identifierref>6a557cfa6d3cbf67840002e9b445abbb</assignment_group_identifierref>
              <assignment_overrides/>
            </assignment>
          </quiz>
        XML
      end

      it "replaces migration IDs appropriately" do
        expected_xml = <<~XML
          <?xml version="1.0"?>
          <quiz xmlns="http://canvas.instructure.com/xsd/cccv1p0" xmlns:xsi="http://canvas.instructure.com/xsd/cccv1p0 https://canvas.instructure.com/xsd/cccv1p0.xsd" identifier="#{CC::CCHelper.create_key(@new_quiz_1, global: true)}">
            <title>my new quiz</title>
            <description/>
            <due_at/>
            <lock_at/>
            <unlock_at/>
            <shuffle_questions>false</shuffle_questions>
            <assignment identifier="b6aa97bfb1c6543f2560ab12f4e28a47">
              <title>my new quiz</title>
              <due_at/>
              <lock_at/>
              <unlock_at/>
              <quiz_identifierref>#{CC::CCHelper.create_key(@new_quiz_1, global: true)}</quiz_identifierref>
              <post_policy>
                <post_manually>false</post_manually>
              </post_policy>
              <assignment_group_identifierref>6a557cfa6d3cbf67840002e9b445abbb</assignment_group_identifierref>
              <assignment_overrides/>
            </assignment>
          </quiz>
        XML

        expect(subject.replace_in_xml(xml)).to eq(expected_xml)
      end
    end

    context "when the xml contains an assessment object" do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">
            <assessment ident="gdbb1b3860016ed4d2392d017a493f0ec" title="my new quiz">
              <qtimetadata>
                <qtimetadatafield>
                  <fieldlabel>cc_maxattempts</fieldlabel>
                  <fieldentry>1</fieldentry>
                </qtimetadatafield>
              </qtimetadata>
            </assessment>
          </questestinterop>
        XML
      end

      it "replaces migration IDs appropriately" do
        expected_xml = <<~XML
          <?xml version="1.0"?>
          <questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">
            <assessment ident="#{CC::CCHelper.create_key(@new_quiz_2, global: true)}" title="my new quiz">
              <qtimetadata>
                <qtimetadatafield>
                  <fieldlabel>cc_maxattempts</fieldlabel>
                  <fieldentry>1</fieldentry>
                </qtimetadatafield>
              </qtimetadata>
            </assessment>
          </questestinterop>
        XML

        expect(subject.replace_in_xml(xml)).to eq(expected_xml)
      end
    end
  end
end
