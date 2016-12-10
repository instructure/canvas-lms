# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../cc_spec_helper')

require 'tmpdir'

describe "Standard Common Cartridge importing" do

  context 'in a cartridge' do
    before(:once) do
      archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/asmnt_example.zip")
      unzipped_file_path = create_temp_dir!
      converter = CC::Importer::Standard::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
      converter.export
      @course_data = converter.course.with_indifferent_access
      @course_data['all_files_export'] ||= {}
      @course_data['all_files_export']['file_path'] = @course_data['all_files_zip']

      @course = course
      @migration = ContentMigration.create(:context => @course)
      @migration.migration_settings[:migration_ids_to_import] = {:copy => {}}
      Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
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

  def import_from_file(filename)
    archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/#{filename}")
    unzipped_file_path = create_temp_dir!
    @course = course
    @migration = ContentMigration.create(:context => @course)
    converter = CC::Importer::Standard::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi',
      :base_download_dir=>unzipped_file_path, :content_migration => @migration)
    converter.convert
    @course_data = converter.course.with_indifferent_access

    @migration.migration_settings[:migration_ids_to_import] = {:copy => {}}
    Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
  end

  context 'in a flat file' do
    before(:once) do
      import_from_file("flat_imsmanifest.xml")
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

    it "should mark teacher role content as unpublished" do
      m = @course.context_modules.first

      # assignment
      expect(m.content_tags[0].content.workflow_state).to eq 'unpublished'
      # discussion
      expect(m.content_tags[1].content.workflow_state).to eq 'unpublished'
      # weblink
      expect(m.content_tags[2].workflow_state).to eq 'unpublished'
      # lti launch
      expect(m.content_tags[3].workflow_state).to eq 'unpublished'
    end

    it "should mark teacher role webcontent as locked and hidden" do
      att = @course.attachments.where(migration_id: 'Resource5').first
      expect(att.locked?).to eq true
    end
  end

  context 'variant support' do
    before(:once) do
      import_from_file("flat_imsmanifest_with_variants.xml")
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

  context "flat manifest with curriculum standards" do
    it "should produce a warning" do
      import_from_file("flat_imsmanifest_with_curriculum.xml")
      issues = @migration.migration_issues.pluck(:description)
      expect(issues.any?{|i| i.include?("This package includes Curriculum Standards")}).to be_truthy
    end
  end

  context 'flat manifest with qti' do
    before(:once) do
      skip unless Qti.qti_enabled?

      archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/cc_inline_qti.zip")
      unzipped_file_path = create_temp_dir!
      converter = CC::Importer::Standard::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
      converter.export
      @course_data = converter.course.with_indifferent_access
      @course_data['all_files_export'] ||= {}
      @course_data['all_files_export']['file_path'] = @course_data['all_files_zip']

      @course = course
      @migration = ContentMigration.create(:context => @course)
      @migration.migration_settings[:migration_ids_to_import] = {:copy => {}}
      Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
    end

    it "should import assessments from qti inside the manifest" do
      expect(@migration.migration_issues.count).to eq 1
      expect(@migration.migration_issues.first.description).to include("This package includes the question type, Pattern Match")

      expect(@course.quizzes.count).to eq 1
      q = @course.quizzes.first
      expect(q.title).to eq "Pretest"
      expect(q.quiz_questions.count).to eq 11
    end
  end
end
