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

require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
  describe "QTI 1.2 zip" do
    before(:once) do
      @archive_file_path = File.join(BASE_FIXTURE_DIR, 'qti', 'plain_qti.zip')
      unzipped_file_path = create_temp_dir!
      @dir = create_temp_dir!

      @course = Course.create!(:name => 'tester')
      @migration = ContentMigration.create(:context => @course)

      converter = Qti::Converter.new(:export_archive_path=>@archive_file_path, :base_download_dir=>unzipped_file_path, :content_migration => @migration)
      converter.export
      @course_data = converter.course.with_indifferent_access
      @course_data['all_files_export'] ||= {}
      @course_data['all_files_export']['file_path'] = @course_data['all_files_zip']

      @migration.set_default_settings
      @migration.migration_settings[:migration_ids_to_import] = {:copy=>{}}
      @migration.migration_settings[:files_import_root_path] = @course_data[:files_import_root_path]
      Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
    end

    it "should convert the assessments" do
      expect(@course_data[:assessments]).to eq QTI_EXPORT_ASSESSMENT
      expect(@course.quizzes.count).to eq 1
      quiz = @course.quizzes.first
      expect(quiz.title).to eq 'Quiz'
      expect(quiz.quiz_questions.count).to eq 10
    end

    it "should convert the questions" do
      expect(@course_data[:assessment_questions][:assessment_questions].length).to eq 10
      expect(@course.assessment_questions.count).to eq 10
    end

    it "should create an assessment question bank for the quiz" do
      expect(@course.assessment_question_banks.count).to eq 1
      bank = @course.assessment_question_banks.first
      expect(bank.title).to eq 'Quiz'
      expect(bank.assessment_questions.count).to eq 10
    end

    it "should have file paths" do
      expect(@course_data[:overview_file_path].index("/overview.json")).not_to be_nil
      expect(@course_data[:full_export_file_path].index('course_export.json')).not_to be_nil
    end

    it "should import the included files" do
      expect(@course.attachments.count).to eq 4

      dir = Canvas::Migration::MigratorHelper::QUIZ_FILE_DIRECTORY
      expect(@course.attachments.where(migration_id: "f3e5ead7f6e1b25a46a4145100566821").first.full_display_path).to eq "course files/#{dir}/#{@migration.id}/exam1/my_files/org1/images/image.png"
      expect(@course.attachments.where(migration_id: "c16566de1661613ef9e5517ec69c25a1").first.full_display_path).to eq "course files/#{dir}/#{@migration.id}/contact info.png"
      expect(@course.attachments.where(migration_id: "4d348a246af616c7d9a7d403367c1a30").first.full_display_path).to eq "course files/#{dir}/#{@migration.id}/exam1/my_files/org0/images/image.png"
      expect(@course.attachments.where(migration_id: "d2b5ca33bd970f64a6301fa75ae2eb22").first.full_display_path).to eq "course files/#{dir}/#{@migration.id}/image.png"
    end

    it "should use expected file links in questions" do
      aq = @course.assessment_questions.where(migration_id: "QUE_1003").first
      c_att = @course.attachments.where(migration_id: "4d348a246af616c7d9a7d403367c1a30").first
      att = aq.attachments.where(migration_id: CC::CCHelper.create_key(c_att)).first
      expect(aq.question_data["question_text"]).to match %r{files/#{att.id}/download}

      aq = @course.assessment_questions.where(migration_id: "QUE_1007").first
      c_att = @course.attachments.where(migration_id: "f3e5ead7f6e1b25a46a4145100566821").first
      att = aq.attachments.where(migration_id: CC::CCHelper.create_key(c_att)).first
      expect(aq.question_data["question_text"]).to match %r{files/#{att.id}/download}

      aq = @course.assessment_questions.where(migration_id: "QUE_1014").first
      c_att = @course.attachments.where(migration_id: "d2b5ca33bd970f64a6301fa75ae2eb22").first
      att = aq.attachments.where(migration_id: CC::CCHelper.create_key(c_att)).first
      expect(aq.question_data["question_text"]).to match %r{files/#{att.id}/download}

      aq = @course.assessment_questions.where(migration_id: "QUE_1053").first
      c_att = @course.attachments.where(migration_id: "c16566de1661613ef9e5517ec69c25a1").first
      att = aq.attachments.where(migration_id: CC::CCHelper.create_key(c_att)).first
      expect(aq.question_data["question_text"]).to match %r{files/#{att.id}/download}
    end

    it "should hide the quiz directory" do
      folder = @course.folders.where(name: Canvas::Migration::MigratorHelper::QUIZ_FILE_DIRECTORY).first
      expect(folder.hidden?).to be_truthy
    end

    it "should use new attachments for imports with same file names" do
      # run a second migration and check that there are different attachments on the questions
      migration = ContentMigration.create(:context => @course)
      converter = Qti::Converter.new(:export_archive_path=>@archive_file_path, :content_migration => migration, :id_prepender => 'test2')
      converter.export
      course_data = converter.course.with_indifferent_access
      course_data['all_files_export'] ||= {}
      course_data['all_files_export']['file_path'] = course_data['all_files_zip']
      migration.migration_settings[:migration_ids_to_import] = {:copy=>{}}
      migration.migration_settings[:files_import_root_path] = course_data[:files_import_root_path]
      migration.migration_settings[:id_prepender] = 'test2'
      Importers::CourseContentImporter.import_content(@course, course_data, nil, migration)

      # Check the first import
      aq = @course.assessment_questions.where(migration_id: "QUE_1003").first
      c_att = @course.attachments.where(migration_id: "4d348a246af616c7d9a7d403367c1a30").first
      att = aq.attachments.where(migration_id: CC::CCHelper.create_key(c_att)).first
      expect(aq.question_data["question_text"]).to match %r{files/#{att.id}/download}

      # check the second import
      aq = @course.assessment_questions.where(migration_id: "test2_QUE_1003").first
      c_att = @course.attachments.where(migration_id: "test2_4d348a246af616c7d9a7d403367c1a30").first
      att = aq.attachments.where(migration_id: CC::CCHelper.create_key(c_att)).first
      expect(aq.question_data["question_text"]).to match %r{files/#{att.id}/download}
    end

  end


  QTI_EXPORT_ASSESSMENT = {
          :assessments=>
                  [{:migration_id=>"A1001",
                    :questions=>
                            [{:migration_id=>"QUE_1003", :question_type=>"question_reference"},
                             {:migration_id=>"QUE_1007", :question_type=>"question_reference"},
                             {:migration_id=>"QUE_1014", :question_type=>"question_reference"},
                             {:migration_id=>"QUE_1018", :question_type=>"question_reference"},
                             {:migration_id=>"QUE_1022", :question_type=>"question_reference"},
                             {:migration_id=>"QUE_1031", :question_type=>"question_reference"},
                             {:migration_id=>"QUE_1037", :question_type=>"question_reference"},
                             {:migration_id=>"QUE_1043", :question_type=>"question_reference"},
                             {:migration_id=>"QUE_1049", :question_type=>"question_reference"},
                             {:migration_id=>"QUE_1053", :question_type=>"question_reference"}],
                    :question_count=>10,
                    :quiz_type=>nil,
                    :quiz_name=>"Quiz",
                    :title=>"Quiz"}]}.with_indifferent_access
end
