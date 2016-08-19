require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "QTI 2.1 zip" do
  before(:once) do
    archive_file_path = File.join(BASE_FIXTURE_DIR, 'qti', 'qti_2_1.zip')
    unzipped_file_path = create_temp_dir!
    export_folder = create_temp_dir!
    exporter = Qti::Converter.new(:export_archive_path=>archive_file_path, :base_download_dir=>unzipped_file_path)
    exporter.export
    @course_data = exporter.course.with_indifferent_access
  end

  it "should convert the questions" do
    expect(@course_data[:assessment_questions][:assessment_questions].length).to eq 4
  end

  it "should have file paths" do
    expect(@course_data[:overview_file_path].index("overview.json")).not_to be_nil
    expect(@course_data[:full_export_file_path].index('course_export.json')).not_to be_nil
  end

  it "should properly detect whether a package is QTI 2.1" do
    qti1 = File.join(BASE_FIXTURE_DIR, 'qti', 'manifest_qti_1_2.xml')
    qti2 = File.join(BASE_FIXTURE_DIR, 'qti', 'manifest_qti_2_1.xml')
    expect(Qti::Converter.is_qti_2(qti1)).to be_falsey
    expect(Qti::Converter.is_qti_2(qti2)).to be_truthy

    qti2_ns = File.join(BASE_FIXTURE_DIR, 'qti', 'manifest_qti_2_ns.xml')
    expect(Qti::Converter.is_qti_2(qti2_ns)).to be_truthy
  end


end
end
