# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../cc_spec_helper')

describe "Standard Common Cartridge importing" do
  context 'in a cartridge' do
    before(:all) do
      archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/asmnt_example.zip")
      unzipped_file_path = File.join(File.dirname(archive_file_path), "cc_#{File.basename(archive_file_path, '.zip')}", 'oi')
      @export_folder = File.join(File.dirname(archive_file_path), "cc_asmnt_example")
      @converter = CC::Importer::Standard::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
      @converter.export
      @course_data = @converter.course.with_indifferent_access
      @course_data['all_files_export'] ||= {}
      @course_data['all_files_export']['file_path'] = @course_data['all_files_zip']

      @course = course
      @migration = ContentMigration.create(:context => @course)
      @migration.migration_settings[:migration_ids_to_import] = {:copy => {}}
      Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
    end

    after(:all) do
      @converter.delete_unzipped_archive
      if File.exists?(@export_folder)
        FileUtils::rm_rf(@export_folder)
      end
      truncate_all_tables
    end

    it "should import assignments" do
      @course.assignments.count.should == 1
      a = @course.assignments.first
      a.title.should == 'Cool Assignment'
      a.points_possible.should == 11
      att = @course.attachments.find_by_migration_id("extensionresource1")
      a.description.gsub("\n", '').should == "<p>You should turn this in for points.</p><ul><li><a href=\"/courses/#{@course.id}/files/#{att.id}/preview\">common.html</a></li></ul>"
      a.submission_types = "online_upload,online_text_entry,online_url"
    end

    it "should import multiple question banks"
  end

  context 'in a flat file' do
    before(:all) do
      archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/flat_imsmanifest.xml")
      unzipped_file_path = File.join(File.dirname(archive_file_path), "cc_#{File.basename(archive_file_path, '.xml')}", 'oi')
      @export_folder = File.join(File.dirname(archive_file_path), "cc_flat_imsmanifest")
      @converter = CC::Importer::Standard::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
      @converter.convert
      @course_data = @converter.course.with_indifferent_access

      @course = course
      @migration = ContentMigration.create(:context => @course)
      @migration.migration_settings[:migration_ids_to_import] = {:copy => {}}
      Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
    end

    after(:all) do
      @converter.delete_unzipped_archive
      if File.exists?(@export_folder)
        FileUtils::rm_rf(@export_folder)
      end
      truncate_all_tables
    end

    it "should import assignments" do
      @course.assignments.count.should == 1
      a = @course.assignments.first
      a.title.should == 'Cool Assignment'
    end

    it "should import links into the module" do
      m = @course.context_modules.first
      url = m.content_tags[2]
      url.should_not be_nil
      url.url.should == "http://www.open2.net/sciencetechnologynature/"
    end

    it "should import external tools" do
      @course.context_external_tools.count.should == 1

      m = @course.context_modules.first
      url = m.content_tags[3]
      url.should_not be_nil
      url.url.should == "http://www.imsglobal.org/developers/BLTI/tool.php"
    end

    it "should reference preferred variant in module"
    it "should reference preferred variant in html content"
    it "should not import non-preferred variant"
    it "should ignore not-supported preferred variant"
    it "should follow variant chain to end"

  end

  context 'flat manifest with qti' do
    before(:all) do
      if Qti.qti_enabled?
        archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/cc_inline_qti.zip")
        unzipped_file_path = File.join(File.dirname(archive_file_path), "cc_#{File.basename(archive_file_path, '.zip')}", 'oi')
        @export_folder = File.join(File.dirname(archive_file_path), "cc_inline_qti")
        @converter = CC::Importer::Standard::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
        @converter.export
        @course_data = @converter.course.with_indifferent_access
        @course_data['all_files_export'] ||= {}
        @course_data['all_files_export']['file_path'] = @course_data['all_files_zip']

        @course = course
        @migration = ContentMigration.create(:context => @course)
        @migration.migration_settings[:migration_ids_to_import] = {:copy => {}}
        Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
      end
    end

    after(:all) do
      if @converter
        @converter.delete_unzipped_archive
        if File.exists?(@export_folder)
          FileUtils::rm_rf(@export_folder)
        end
        truncate_all_tables
      end
    end

    it "should import assessments from qti inside the manifest" do
      pending unless Qti.qti_enabled?

      @migration.migration_issues.count.should == 0

      @course.quizzes.count.should == 1
      q = @course.quizzes.first
      q.title.should == "Pretest"
      q.quiz_questions.count.should == 11
    end
  end
end
