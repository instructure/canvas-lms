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

describe CC::Qti::NewQuizzesGenerator do
  before do
    @copy_from = course_model
    @from_teacher = @user
    @copy_to = course_model
    @content_export = @copy_from.content_exports.build
    @content_export.export_type = ContentExport::COMMON_CARTRIDGE
    @content_export.user = @from_teacher
    @content_export.settings[:new_quizzes_export_url] =
      Rails.root.join("spec/lib/cc/qti/fixtures/nq_common_cartridge_export.zip").to_s
    @exporter = CC::CCExporter.new(@content_export, course: @copy_from, user: @from_teacher)
    @exporter.send(:create_export_dir)
    @manifest = CC::Manifest.new(@exporter)
    @doc = Builder::XmlMarkup.new(target: +"", indent: 2)
  end

  let(:manifest) { CC::Manifest.new(@exporter) }

  describe "#export_dir" do
    it "obtains the export directory through the manifest" do
      @doc.resources do |resource_node|
        new_quizzes_generator = CC::Qti::NewQuizzesGenerator.new(@manifest, resource_node)

        expect(@manifest.export_dir).to_not be_nil
        expect(new_quizzes_generator.export_dir).to eq(@manifest.export_dir)
      end
    end
  end

  describe "#new_quizzes_export_file" do
    it "returns the file referenced by new_quizzes_export_file_url" do
      @doc.resources do |resource_node|
        new_quizzes_generator = CC::Qti::NewQuizzesGenerator.new(@manifest, resource_node)

        expected_files = %w[
          g7a6297c8c5fe5c3dabc42d0ee182dcb8
          gdbb1b3860016ed4d2392d017a493f0ec
          imsmanifest.xml
          non_cc_assessments
        ]

        export_file = new_quizzes_generator.new_quizzes_export_file
        tmp_file = Tempfile.new
        tmp_file.binmode
        tmp_file.write(export_file.read)
        tmp_file.flush

        Dir.mktmpdir do |tmpdir|
          CanvasUnzip.extract_archive(tmp_file.path, tmpdir)
          extracted_files = Dir.glob(File.join(tmpdir, "*")).map do |f|
            f.split("/").last
          end.sort

          expect(extracted_files).to eq(expected_files)
        end
      end
    end
  end

  describe "#write_new_quizzes_content" do
    it "loads new quizes qti files in the new quizzes content dir" do
      @doc.resources do |resource_node|
        new_quizzes_generator = CC::Qti::NewQuizzesGenerator.new(@manifest, resource_node)

        expected_files = %w[
          g7a6297c8c5fe5c3dabc42d0ee182dcb8/assessment_meta.xml
          g7a6297c8c5fe5c3dabc42d0ee182dcb8/assessment_qti.xml
          gdbb1b3860016ed4d2392d017a493f0ec/assessment_meta.xml
          gdbb1b3860016ed4d2392d017a493f0ec/assessment_qti.xml
          non_cc_assessments/g7a6297c8c5fe5c3dabc42d0ee182dcb8.xml.qti
          non_cc_assessments/gdbb1b3860016ed4d2392d017a493f0ec.xml.qti
        ]

        new_quizzes_generator.write_new_quizzes_content

        extracted_files = Dir.glob(File.join(new_quizzes_generator.export_dir, "*", "**")).map do |f|
          f.sub("#{new_quizzes_generator.export_dir}/", "")
        end.sort

        expect(extracted_files).to eq(expected_files)
      end
    end

    context "when the new quizzes export package contains media files" do
      before do
        @content_export.settings[:new_quizzes_export_url] =
          Rails.root.join("spec/lib/cc/qti/fixtures/nq_common_cartridge_export_with_images.zip").to_s
        @content_export.save!
      end

      it "loads new quizes qti files into the new quizzes content dir" do
        @doc.resources do |resource_node|
          new_quizzes_generator = CC::Qti::NewQuizzesGenerator.new(@manifest, resource_node)

          expected_files = [
            "Uploaded Media/someuuid1",
            "Uploaded Media/someuuid2",
            "g7a6297c8c5fe5c3dabc42d0ee182dcb8/assessment_meta.xml",
            "g7a6297c8c5fe5c3dabc42d0ee182dcb8/assessment_qti.xml",
            "gdbb1b3860016ed4d2392d017a493f0ec/assessment_meta.xml",
            "gdbb1b3860016ed4d2392d017a493f0ec/assessment_qti.xml",
            "non_cc_assessments/g7a6297c8c5fe5c3dabc42d0ee182dcb8.xml.qti",
            "non_cc_assessments/gdbb1b3860016ed4d2392d017a493f0ec.xml.qti"
          ]

          new_quizzes_generator.write_new_quizzes_content

          extracted_files = Dir.glob(File.join(new_quizzes_generator.export_dir, "*", "**")).map do |f|
            f.sub("#{new_quizzes_generator.export_dir}/", "")
          end.sort

          expect(extracted_files).to eq(expected_files)
        end
      end
    end

    context "when the new quizzes export package contains a migration IDs map" do
      before do
        @content_export.settings[:new_quizzes_export_url] =
          Rails.root.join("spec/lib/cc/qti/fixtures/nq_common_cartridge_with_mig_ids_map.zip").to_s
        @content_export.save!
        @new_quiz_1 = @copy_from.assignments.create!(title: "New Quiz 1", submission_types: "external_tool")
        @new_quiz_2 = @copy_from.assignments.create!(title: "New Quiz 2", submission_types: "external_tool")
        allow(Assignment).to receive(:find_by).and_call_original
        allow(Assignment).to receive(:find_by).with(id: "44").and_return(@new_quiz_1)
        allow(Assignment).to receive(:find_by).with(id: "45").and_return(@new_quiz_2)
      end

      it "loads new quizes qti files into the new quizzes content dir" do
        @doc.resources do |resource_node|
          new_quizzes_generator = CC::Qti::NewQuizzesGenerator.new(@manifest, resource_node)

          expected_files = [
            "#{CC::CCHelper.create_key(@new_quiz_1, global: true)}/assessment_meta.xml",
            "#{CC::CCHelper.create_key(@new_quiz_1, global: true)}/assessment_qti.xml",
            "#{CC::CCHelper.create_key(@new_quiz_2, global: true)}/assessment_meta.xml",
            "#{CC::CCHelper.create_key(@new_quiz_2, global: true)}/assessment_qti.xml",
            "non_cc_assessments/#{CC::CCHelper.create_key(@new_quiz_1, global: true)}.xml.qti",
            "non_cc_assessments/#{CC::CCHelper.create_key(@new_quiz_2, global: true)}.xml.qti"
          ]

          new_quizzes_generator.write_new_quizzes_content

          extracted_files = Dir.glob(File.join(new_quizzes_generator.export_dir, "*", "**")).map do |f|
            f.sub("#{new_quizzes_generator.export_dir}/", "")
          end.sort

          expect(extracted_files.sort).to eq(expected_files.sort)
        end
      end
    end
  end

  describe "#generate_qti" do
    before do
      allow(CC::CCHelper).to receive(:create_key).and_call_original
      allow(CC::CCHelper).to receive(:create_key).with("gdbb1b3860016ed4d2392d017a493f0ec")
                                                 .and_return("ifa97a69bc35caaad4b1b3e22c29ff9c0")
      allow(CC::CCHelper).to receive(:create_key).with("g7a6297c8c5fe5c3dabc42d0ee182dcb8")
                                                 .and_return("if659b73a48b08b4d0f23d47a36278073")
    end

    it "includes quizzes in the manifest" do
      @doc.resources do |resource_node|
        new_quizzes_generator = CC::Qti::NewQuizzesGenerator.new(@manifest, resource_node)
        new_quizzes_generator.generate_qti
      end

      expected_manifest_resources = <<~XML
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

      expect(@doc.target!).to eq(expected_manifest_resources)
    end

    context "when the new quizzes export package contains a migration IDs map" do
      before do
        @content_export.settings[:new_quizzes_export_url] =
          Rails.root.join("spec/lib/cc/qti/fixtures/nq_common_cartridge_with_mig_ids_map.zip").to_s
        @content_export.save!
        @new_quiz_1 = @copy_from.assignments.create!(title: "New Quiz 1", submission_types: "external_tool")
        @new_quiz_2 = @copy_from.assignments.create!(title: "New Quiz 2", submission_types: "external_tool")
        allow(Assignment).to receive(:find_by).and_call_original
        allow(Assignment).to receive(:find_by).with(id: "44").and_return(@new_quiz_1)
        allow(Assignment).to receive(:find_by).with(id: "45").and_return(@new_quiz_2)
        @nq_1_mig_id = CC::CCHelper.create_key(@new_quiz_1, global: true)
        @nq_2_mig_id = CC::CCHelper.create_key(@new_quiz_2, global: true)
      end

      it "includes quizzes in the manifest" do
        @doc.resources do |resource_node|
          new_quizzes_generator = CC::Qti::NewQuizzesGenerator.new(@manifest, resource_node)
          new_quizzes_generator.generate_qti
        end

        expected_manifest_resources = <<~XML
          <resources>
            <resource identifier="#{@nq_1_mig_id}" type="imsqti_xmlv1p2/imscc_xmlv1p1/assessment">
              <file href="#{@nq_1_mig_id}/assessment_qti.xml"/>
              <dependency identifierref="#{CC::CCHelper.create_key(@nq_1_mig_id)}"/>
            </resource>
            <resource identifier="#{CC::CCHelper.create_key(@nq_1_mig_id)}" type="associatedcontent/imscc_xmlv1p1/learning-application-resource" href="#{@nq_1_mig_id}/assessment_meta.xml">
              <file href="#{@nq_1_mig_id}/assessment_meta.xml"/>
              <file href="non_cc_assessments/#{@nq_1_mig_id}.xml.qti"/>
            </resource>
            <resource identifier="#{@nq_2_mig_id}" type="imsqti_xmlv1p2/imscc_xmlv1p1/assessment">
              <file href="#{@nq_2_mig_id}/assessment_qti.xml"/>
              <dependency identifierref="#{CC::CCHelper.create_key(@nq_2_mig_id)}"/>
            </resource>
            <resource identifier="#{CC::CCHelper.create_key(@nq_2_mig_id)}" type="associatedcontent/imscc_xmlv1p1/learning-application-resource" href="#{@nq_2_mig_id}/assessment_meta.xml">
              <file href="#{@nq_2_mig_id}/assessment_meta.xml"/>
              <file href="non_cc_assessments/#{@nq_2_mig_id}.xml.qti"/>
            </resource>
          </resources>
        XML

        expect(@doc.target!).to eq(expected_manifest_resources)
      end
    end

    context "when the Common Cartridge export contains uploaded media" do
      before do
        @content_export.settings[:new_quizzes_export_url] =
          Rails.root.join("spec/lib/cc/qti/fixtures/nq_common_cartridge_export_with_images.zip").to_s
        @content_export.save!
      end

      it "includes quizzes and uploaded media in the manifest" do
        @doc.resources do |resource_node|
          new_quizzes_generator = CC::Qti::NewQuizzesGenerator.new(@manifest, resource_node)
          new_quizzes_generator.generate_qti
        end

        expected_manifest_resources = <<~XML
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
            <resource identifier="i931e933d0a559fbb7319e5b3c5d3be8e" type="webcontent" href="Uploaded Media/someuuid1">
              <file href="Uploaded Media/someuuid1"/>
            </resource>
            <resource identifier="ic1f6093310b4f2923606824ecd90811f" type="webcontent" href="Uploaded Media/someuuid2">
              <file href="Uploaded Media/someuuid2"/>
            </resource>
          </resources>
        XML

        expect(@doc.target!).to eq(expected_manifest_resources)
      end
    end

    context "when the Common Cartridge export contains item banks" do
      before do
        @content_export.settings[:new_quizzes_export_url] =
          Rails.root.join("spec/lib/cc/qti/fixtures/nq_common_cartridge_export_with_bank.zip").to_s
        @content_export.save!
      end

      it "includes quizzes and item banks into the manifest" do
        @doc.resources do |resource_node|
          new_quizzes_generator = CC::Qti::NewQuizzesGenerator.new(@manifest, resource_node)
          new_quizzes_generator.generate_qti
        end

        expected_manifest_resources = <<~XML
          <resources>
            <resource identifier="g14307719f2cd62b89736dc1f5500c420" type="associatedcontent/imscc_xmlv1p1/learning-application-resource" href="non_cc_assessments/g14307719f2cd62b89736dc1f5500c420.xml.qti">
              <file href="non_cc_assessments/g14307719f2cd62b89736dc1f5500c420.xml.qti"/>
            </resource>
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

        expect(@doc.target!).to eq(expected_manifest_resources)
      end
    end
  end
end
