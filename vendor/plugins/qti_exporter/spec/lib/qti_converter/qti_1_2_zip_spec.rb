require File.dirname(__FILE__) + '/../../qti_helper'

describe "QTI 1.2 zip with id prepender value" do
   before(:all) do
    require 'qti_exporter'
    archive_file_path = File.join(BASE_FIXTURE_DIR, 'qti','plain_qti.zip')
    unzipped_file_path = File.join(File.dirname(archive_file_path), "qti_#{File.basename(archive_file_path, '.zip')}", 'oi')
    export_folder = File.join(File.dirname(archive_file_path), "qti_plain_qti")
    @exporter = Qti::QtiExporter.new(:export_archive_path=>archive_file_path, :base_download_dir=>unzipped_file_path, :id_prepender=>'prepend_test')
    @exporter.export
    @exporter.delete_unzipped_archive
    if File.exists?(export_folder)
      FileUtils::rm_rf(export_folder)
    end
  end

  it "should convert the assessments" do
    @exporter.course[:assessments].should == QTI_EXPORT_ASSESSMENT.with_indifferent_access
  end

  it "should convert the questions" do
    @exporter.course[:assessment_questions][:assessment_questions].length.should == 10
  end

  it "should have file paths" do
    @exporter.course[:overview_file_path].index("oi/overview.json").should_not be_nil
    @exporter.course[:export_folder_path].index('spec/fixtures/qti/qti_plain_qti/oi').should_not be_nil
    @exporter.course[:full_export_file_path].index('spec/fixtures/qti/qti_plain_qti/oi/course_export.json').should_not be_nil
  end


end


QTI_EXPORT_ASSESSMENT = {
        :assessments=>
                [{:migration_id=>"prepend_test_quiz",
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
                  :title=>"Quiz"}]}