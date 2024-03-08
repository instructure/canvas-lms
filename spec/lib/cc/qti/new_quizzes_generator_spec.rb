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
  subject { CC::Qti::NewQuizzesGenerator.new(manifest) }

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
  end

  let(:manifest) { CC::Manifest.new(@exporter) }

  describe "#export_dir" do
    it "obtains the export directory through the manifest" do
      expect(manifest.export_dir).to_not be_nil
      expect(subject.export_dir).to eq(manifest.export_dir)
    end
  end

  describe "#new_quizzes_export_file" do
    it "returns the file referenced by new_quizzes_export_file_url" do
      expected_files = %w[
        g7a6297c8c5fe5c3dabc42d0ee182dcb8
        gdbb1b3860016ed4d2392d017a493f0ec
        imsmanifest.xml
        non_cc_assessments
      ]

      export_file = subject.new_quizzes_export_file
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

  describe "#write_new_quizzes_content" do
    it "loads new quizes qti files into the new quizzes content dir" do
      expected_files = %w[
        g7a6297c8c5fe5c3dabc42d0ee182dcb8/assessment_meta.xml
        g7a6297c8c5fe5c3dabc42d0ee182dcb8/assessment_qti.xml
        gdbb1b3860016ed4d2392d017a493f0ec/assessment_meta.xml
        gdbb1b3860016ed4d2392d017a493f0ec/assessment_qti.xml
        non_cc_assessments/g7a6297c8c5fe5c3dabc42d0ee182dcb8.xml.qti
        non_cc_assessments/gdbb1b3860016ed4d2392d017a493f0ec.xml.qti
      ]

      subject.write_new_quizzes_content

      extracted_files = Dir.glob(File.join(subject.export_dir, "*", "**")).map do |f|
        f.sub("#{subject.export_dir}/", "")
      end.sort

      expect(extracted_files).to eq(expected_files)
    end

    context "when the new quizzes export package contains media files" do
      before do
        @content_export.settings[:new_quizzes_export_url] =
          Rails.root.join("spec/lib/cc/qti/fixtures/nq_common_cartridge_export_with_images.zip").to_s
        @content_export.save!
      end

      it "loads new quizes qti files into the new quizzes content dir" do
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

        subject.write_new_quizzes_content

        extracted_files = Dir.glob(File.join(subject.export_dir, "*", "**")).map do |f|
          f.sub("#{subject.export_dir}/", "")
        end.sort

        expect(extracted_files).to eq(expected_files)
      end
    end
  end
end
