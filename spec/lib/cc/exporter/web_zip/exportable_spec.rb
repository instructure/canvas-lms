# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe "Exportable" do
  # this class is only necessary until we get our package into a public repo
  # (canvas_offline_course_viewer npm package)
  before do
    stub_const("ZipPackageTest",
               Class.new(CC::Exporter::WebZip::ZipPackage) do
                 def initialize(exporter, course, user, progress_key)
                   super(exporter, course, user, progress_key)
                   @index_file = "dist/index.html"
                   @bundle_file = "dist/viewer/bundle.js"
                   @dist_dir = "dist"
                   @viewer_dir = "dist/viewer"
                 end

                 def dist_package_path
                   FileUtils.mkdir_p(@dist_dir)
                   FileUtils.mkdir_p(@viewer_dir)
                   index_file = File.new(@index_file, "w+")
                   index_file.write("<html></html>")
                   index_file.close
                   bundle_file = File.new(@bundle_file, "w+")
                   bundle_file.write("{}")
                   bundle_file.close
                   @dist_dir
                 end

                 def cleanup_files
                   super
                   FileUtils.rm_f(@index_file)
                   FileUtils.rm_f(@bundle_file)
                   FileUtils.rm_f(@viewer_dir)
                   FileUtils.rm_f(@dist_dir)
                 end
               end)

    stub_const("ExportableTest",
               Class.new do
                 include CC::Exporter::WebZip::Exportable

                 def initialize(course, user, cartridge_path)
                   @course = course
                   @user = user
                   @cartridge_path = cartridge_path
                 end

                 def attachment
                   @attachment ||= Attachment.create({
                                                       context: Course.create,
                                                       filename: "exportable-test-file",
                                                       uploaded_data: File.open(@cartridge_path)
                                                     })
                 end

                 def cartridge_path
                   File.join(File.dirname(__FILE__), "/../../../../fixtures/migration/unicode-filename-test-export.imscc")
                 end

                 def create_zip(exporter, progress_key)
                   ZipPackageTest.new(exporter, @course, @user, progress_key)
                 end

                 def content_export
                   @content_export ||= @course.content_exports.create!(export_type: ContentExport::COURSE_COPY)
                 end
               end)
  end

  context "#convert_to_web_zip" do
    before do
      @create_date = 1.minute.ago
      course_with_teacher(active_all: true)
      student_in_course(active_all: true, user_name: "a student")
      @course.web_zip_exports.create!(created_at: @create_date, user: @student)
      cartridge_path = "spec/fixtures/migration/unicode-filename-test-export.imscc"
      @web_zip_export = ExportableTest.new(@course, @student, cartridge_path).convert_to_offline_web_zip("cache_key")
    end

    let(:zip_path) do
      @web_zip_export
    end

    let(:zip) do
      File.open(zip_path)
    end

    it "creates a zip file" do
      expect(zip).not_to be_nil
    end

    it "exports zip file if there are no files in the course" do
      cartridge_path = "spec/fixtures/migration/canvas_announcement.zip"
      zip_path = ExportableTest.new(@course, @student, cartridge_path).convert_to_offline_web_zip("cache_key")
      expect(zip_path).not_to be_nil
    end

    context "course-data.js file" do
      it "creates a course-data.js file" do
        Zip::File.open(zip_path) do |zip_file|
          file = zip_file.glob("**/viewer/course-data.js").first
          expect(file).not_to be_nil
          contents = file.get_input_stream.read
          expect(contents.start_with?("window.COURSE_DATA =")).to be true
        end
      end

      it "creates a 'files' key in the course-data.js file" do
        Zip::File.open(zip_path) do |zip_file|
          file = zip_file.glob("**/viewer/course-data.js").first
          expect(file).not_to be_nil
          contents = JSON.parse(file.get_input_stream.read.sub("window.COURSE_DATA =", ""))
          expect(contents["files"]).not_to be_nil
        end
      end

      it "creates the right structure in the 'files' key" do
        Zip::File.open(zip_path) do |zip_file|
          file = zip_file.glob("**/viewer/course-data.js").first
          expect(file).not_to be_nil
          contents = JSON.parse(file.get_input_stream.read.sub("window.COURSE_DATA =", ""))
          expect(contents["files"].length).to eq(3)
          expect(contents["files"][0]["type"]).to eq("file")
          expect(contents["files"][0]["name"]).not_to be_nil
          expect(contents["files"][0]["size"]).not_to be_nil
          expect(contents["files"][0]["files"]).to be_nil
        end
      end

      it "adds course data to the course-data.js file" do
        Zip::File.open(zip_path) do |zip_file|
          file = zip_file.glob("**/viewer/course-data.js").first
          expect(file).not_to be_nil
          contents = JSON.parse(file.get_input_stream.read.sub("window.COURSE_DATA =", ""))
          expect(contents["language"]).to eq "en"
          expect(contents["lastDownload"]).to eq @create_date.in_time_zone(@student.time_zone).iso8601
          expect(contents["title"]).to eq @course.name
        end
      end
    end

    context "canvas_offline_course_viewer files" do
      it "inserts the index.html file" do
        Zip::File.open(zip_path) do |zip_file|
          file = zip_file.glob("**/index.html").first
          expect(file.name).not_to include "//"
          expect(file).not_to be_nil
          contents = file.get_input_stream.read
          expect(contents).not_to be_nil
        end
      end

      it "inserts the viewer/bundle.js file" do
        Zip::File.open(zip_path) do |zip_file|
          file = zip_file.glob("**/viewer/bundle.js").first
          expect(file.name).not_to include "//"
          expect(file).not_to be_nil
          contents = file.get_input_stream.read
          expect(contents).not_to be_nil
        end
      end
    end

    it "creates a zip file whose name includes the cartridge's name" do
      expect(zip_path).to include("unicode-filename-test")
    end

    after do
      FileUtils.rm_f(zip_path)
    end
  end
end
