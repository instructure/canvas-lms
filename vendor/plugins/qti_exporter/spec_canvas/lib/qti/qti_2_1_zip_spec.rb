require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "QTI 2.1 zip" do
  before(:all) do
    archive_file_path = File.join(BASE_FIXTURE_DIR, 'qti', 'qti_2_1.zip')
    unzipped_file_path = File.join(File.dirname(archive_file_path), "qti_#{File.basename(archive_file_path, '.zip')}", 'oi')
    export_folder = File.join(File.dirname(archive_file_path), "qti_qti_2_1")
    @exporter = Qti::Converter.new(:export_archive_path=>archive_file_path, :base_download_dir=>unzipped_file_path)
    @exporter.export
    @exporter.delete_unzipped_archive
    if File.exists?(export_folder)
      FileUtils::rm_rf(export_folder)
    end
  end

  it "should convert the questions" do
    expect(@exporter.course[:assessment_questions][:assessment_questions].length).to eq 4
  end

  it "should have file paths" do
    expect(@exporter.course[:overview_file_path].index("oi/overview.json")).not_to be_nil
    expect(@exporter.course[:export_folder_path].index('spec_canvas/fixtures/qti/qti_qti_2_1/oi')).not_to be_nil
    expect(@exporter.course[:full_export_file_path].index('spec_canvas/fixtures/qti/qti_qti_2_1/oi/course_export.json')).not_to be_nil
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
