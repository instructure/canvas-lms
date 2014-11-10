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
      expect(@course.assignments.count).to eq 1
      a = @course.assignments.first
      expect(a.title).to eq 'Cool Assignment'
      expect(a.points_possible).to eq 11
      att = @course.attachments.where(migration_id: "extensionresource1").first
      expect(a.description.gsub("\n", '')).to eq "<p>You should turn this in for points.</p><ul><li><a href=\"/courses/#{@course.id}/files/#{att.id}/preview\">common.html</a></li></ul>"
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
      expect(@course.assignments.count).to eq 1
      a = @course.assignments.first
      expect(a.title).to eq 'Cool Assignment'
    end

    it "should import links into the module" do
      m = @course.context_modules.first
      url = m.content_tags[2]
      expect(url).not_to be_nil
      expect(url.url).to eq "http://www.open2.net/sciencetechnologynature/"
    end

    it "should import external tools" do
      expect(@course.context_external_tools.count).to eq 1

      m = @course.context_modules.first
      url = m.content_tags[3]
      expect(url).not_to be_nil
      expect(url.url).to eq "http://www.imsglobal.org/developers/BLTI/tool.php"
    end

  end

  context 'variant support' do
    before(:all) do
      archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/flat_imsmanifest_with_variants.xml")
      unzipped_file_path = File.join(File.dirname(archive_file_path), "cc_#{File.basename(archive_file_path, '.xml')}", 'oi')
      @export_folder = File.join(File.dirname(archive_file_path), "cc_flat_imsmanifest_with_variants")
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

    it "should import supported variant" do
      expect(@course.assignments.where(migration_id: 'Resource1')).to be_exists
      expect(@course.assignments.count).to eq 1
    end

    it "should ignore non-preferred variant" do
      expect(@course.discussion_topics.where(migration_id: 'Resource2')).not_to be_exists
      expect(@course.discussion_topics.where(migration_id: 'Resource10')).not_to be_exists
      expect(@course.discussion_topics.count).to eq 2
    end

    it "should reference preferred variant in module" do
      m = @course.context_modules.first
      expect(m.content_tags[0].content.migration_id).to eq 'Resource1'
      expect(m.content_tags[1].content.migration_id).to eq 'Resource3' # also tests "should follow variant chain to end"
      expect(m.content_tags[2].url).to eq "https://example.com/3" # also tests "should ignore not-supported preferred variant"
      expect(m.content_tags[3].content.migration_id).to eq 'Resource8'
    end

    it "should not loop on circular references" do
      m = @course.context_modules.first
      expect(m.content_tags[4].url).to match /loop(1|2)/
      # also, the import finished executing. :)
    end

  end

  context 'flat manifest with qti' do
    before(:all) do
      if Qti.qti_enabled?
        archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/cc_inline_qti.zip")
        unzipped_file_path = File.join(File.dirname(archive_file_path), "cc_#{File.basename(archive_file_path, '.zip')}", 'oi')
        @export_folder = File.join(File.dirname(archive_file_path), "cc_cc_inline_qti")
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
      skip unless Qti.qti_enabled?

      expect(@migration.migration_issues.count).to eq 0

      expect(@course.quizzes.count).to eq 1
      q = @course.quizzes.first
      expect(q.title).to eq "Pretest"
      expect(q.quiz_questions.count).to eq 11
    end
  end
end
