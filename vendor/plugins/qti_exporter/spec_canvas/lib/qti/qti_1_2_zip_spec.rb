require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
  describe "QTI 1.2 zip with id prepender value" do
    before(:all) do
      @archive_file_path = File.join(BASE_FIXTURE_DIR, 'qti', 'plain_qti.zip')
      unzipped_file_path = File.join(File.dirname(@archive_file_path), "qti_#{File.basename(@archive_file_path, '.zip')}", 'oi')
      @dir = File.join(File.dirname(@archive_file_path), "qti_plain_qti")
      
      @course = Course.create!(:name => 'tester')
      @migration = ContentMigration.create(:context => @course)
      
      @converter = Qti::Converter.new(:export_archive_path=>@archive_file_path, :base_download_dir=>unzipped_file_path, :id_prepender=>'prepend_test', :content_migration => @migration)
      @converter.export
      @course_data = @converter.course.with_indifferent_access
      @course_data['all_files_export'] ||= {}
      @course_data['all_files_export']['file_path'] = @course_data['all_files_zip']

      @migration.migration_settings[:migration_ids_to_import] = {:copy=>{}}
      @migration.migration_settings[:files_import_root_path] = @course_data[:files_import_root_path]
      Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
    end

    after(:all) do
      truncate_all_tables
      @converter.delete_unzipped_archive
      if File.exists?(@dir)
        FileUtils::rm_rf(@dir)
      end
    end

    it "should convert the assessments" do
      @converter.course[:assessments].should == QTI_EXPORT_ASSESSMENT
      @course.quizzes.count.should == 1
      quiz = @course.quizzes.first
      quiz.title.should == 'Quiz'
      quiz.quiz_questions.count.should == 10
    end

    it "should convert the questions" do
      @course_data[:assessment_questions][:assessment_questions].length.should == 10
      @course.assessment_questions.count.should == 10
    end

    it "should create an assessment question bank for the quiz" do
      @course.assessment_question_banks.count.should == 1
      bank = @course.assessment_question_banks.first
      bank.title.should == 'Quiz'
      bank.assessment_questions.count.should == 10
    end

    it "should have file paths" do
      @course_data[:overview_file_path].index("oi/overview.json").should_not be_nil
      @course_data[:export_folder_path].index('spec_canvas/fixtures/qti/qti_plain_qti/oi').should_not be_nil
      @course_data[:full_export_file_path].index('spec_canvas/fixtures/qti/qti_plain_qti/oi/course_export.json').should_not be_nil
    end

    it "should import the included files" do
      @course.attachments.count.should == 4

      dir = Canvas::Migration::MigratorHelper::QUIZ_FILE_DIRECTORY
      @course.attachments.find_by_migration_id("prepend_test_f3e5ead7f6e1b25a46a4145100566821").full_path.should == "course files/#{dir}/#{@migration.id}/exam1/my_files/org1/images/image.png"
      @course.attachments.find_by_migration_id("prepend_test_c16566de1661613ef9e5517ec69c25a1").full_path.should == "course files/#{dir}/#{@migration.id}/contact info.png"
      @course.attachments.find_by_migration_id("prepend_test_4d348a246af616c7d9a7d403367c1a30").full_path.should == "course files/#{dir}/#{@migration.id}/exam1/my_files/org0/images/image.png"
      @course.attachments.find_by_migration_id("prepend_test_d2b5ca33bd970f64a6301fa75ae2eb22").full_path.should == "course files/#{dir}/#{@migration.id}/image.png"
    end

    it "should use expected file links in questions" do
      aq = @course.assessment_questions.find_by_migration_id("prepend_test_QUE_1003")
      c_att = @course.attachments.find_by_migration_id("prepend_test_4d348a246af616c7d9a7d403367c1a30")
      att = aq.attachments.find_by_migration_id(CC::CCHelper.create_key(c_att))
      aq.question_data["question_text"].should =~ %r{files/#{att.id}/download}
      
      aq = @course.assessment_questions.find_by_migration_id("prepend_test_QUE_1007")
      c_att = @course.attachments.find_by_migration_id("prepend_test_f3e5ead7f6e1b25a46a4145100566821")
      att = aq.attachments.find_by_migration_id(CC::CCHelper.create_key(c_att))
      aq.question_data["question_text"].should =~ %r{files/#{att.id}/download}
      
      aq = @course.assessment_questions.find_by_migration_id("prepend_test_QUE_1014")
      c_att = @course.attachments.find_by_migration_id("prepend_test_d2b5ca33bd970f64a6301fa75ae2eb22")
      att = aq.attachments.find_by_migration_id(CC::CCHelper.create_key(c_att))
      aq.question_data["question_text"].should =~ %r{files/#{att.id}/download}
      
      aq = @course.assessment_questions.find_by_migration_id("prepend_test_QUE_1053")
      c_att = @course.attachments.find_by_migration_id("prepend_test_c16566de1661613ef9e5517ec69c25a1")
      att = aq.attachments.find_by_migration_id(CC::CCHelper.create_key(c_att))
      aq.question_data["question_text"].should =~ %r{files/#{att.id}/download}
    end
    
    it "should hide the quiz directory" do
      folder = @course.folders.find_by_name(Canvas::Migration::MigratorHelper::QUIZ_FILE_DIRECTORY)
      folder.hidden?.should be_true
    end
    
    it "should use new attachments for imports with same file names" do
      # run a second migration and check that there are different attachments on the questions
      migration = ContentMigration.create(:context => @course)
      converter = Qti::Converter.new(:export_archive_path=>@archive_file_path, :id_prepender=>'test2', :content_migration => migration)
      converter.export
      course_data = converter.course.with_indifferent_access
      course_data['all_files_export'] ||= {}
      course_data['all_files_export']['file_path'] = course_data['all_files_zip']
      migration.migration_settings[:migration_ids_to_import] = {:copy=>{}}
      migration.migration_settings[:files_import_root_path] = course_data[:files_import_root_path]
      Importers::CourseContentImporter.import_content(@course, course_data, nil, migration)
      
      # Check the first import
      aq = @course.assessment_questions.find_by_migration_id("prepend_test_QUE_1003")
      c_att = @course.attachments.find_by_migration_id("prepend_test_4d348a246af616c7d9a7d403367c1a30")
      att = aq.attachments.find_by_migration_id(CC::CCHelper.create_key(c_att))
      aq.question_data["question_text"].should =~ %r{files/#{att.id}/download}
      
      # check the second import
      aq = @course.assessment_questions.find_by_migration_id("test2_QUE_1003")
      c_att = @course.attachments.find_by_migration_id("test2_4d348a246af616c7d9a7d403367c1a30")
      att = aq.attachments.find_by_migration_id(CC::CCHelper.create_key(c_att))
      aq.question_data["question_text"].should =~ %r{files/#{att.id}/download}
    end

  end


  QTI_EXPORT_ASSESSMENT = {
          :assessments=>
                  [{:migration_id=>"prepend_test_A1001",
                    :questions=>
                            [{:migration_id=>"prepend_test_QUE_1003", :question_type=>"question_reference"},
                             {:migration_id=>"prepend_test_QUE_1007", :question_type=>"question_reference"},
                             {:migration_id=>"prepend_test_QUE_1014", :question_type=>"question_reference"},
                             {:migration_id=>"prepend_test_QUE_1018", :question_type=>"question_reference"},
                             {:migration_id=>"prepend_test_QUE_1022", :question_type=>"question_reference"},
                             {:migration_id=>"prepend_test_QUE_1031", :question_type=>"question_reference"},
                             {:migration_id=>"prepend_test_QUE_1037", :question_type=>"question_reference"},
                             {:migration_id=>"prepend_test_QUE_1043", :question_type=>"question_reference"},
                             {:migration_id=>"prepend_test_QUE_1049", :question_type=>"question_reference"},
                             {:migration_id=>"prepend_test_QUE_1053", :question_type=>"question_reference"}],
                    :question_count=>10,
                    :quiz_type=>nil,
                    :quiz_name=>"Quiz",
                    :title=>"Quiz"}]}.with_indifferent_access
end
