require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Moodle::Converter do

  before(:once) do
    fixture_dir = File.dirname(__FILE__) + '/fixtures'
    archive_file_path = File.join(fixture_dir, 'moodle_backup_2.zip')
    unzipped_file_path = File.join(File.dirname(archive_file_path), "moodle_#{File.basename(archive_file_path, '.zip')}", 'oi')
    converter = Moodle::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
    converter.export
    @base_course_data = converter.course.with_indifferent_access
    converter.delete_unzipped_archive
    if File.exists?(unzipped_file_path)
      FileUtils::rm_rf(unzipped_file_path)
    end

    @course_data = Marshal.load(Marshal.dump(@base_course_data))
    @course = Course.create(:name => "test course")
    @cm = ContentMigration.create(:context => @course)
    Importers::CourseContentImporter.import_content(@course, @course_data, nil, @cm)
  end

  it "should successfully import the course" do
    allowed_warnings = ["Multiple Dropdowns question may have been imported incorrectly",
                        "There are 3 Formula questions in this bank that will need to have their possible answers regenerated",
                        "Missing links found in imported content"]
    expect(@cm.old_warnings_format.all?{|w| allowed_warnings.find{|aw| w[0].start_with?(aw)}}).to eq true
  end

  context "discussion topics" do
    it "should convert discussion topics" do
      expect(@course.discussion_topics.count).to eq 2

      dt = @course.discussion_topics.first
      expect(dt.title).to eq "Hidden Forum"
      expect(dt.message).to eq "<p>Description of hidden forum</p>"
      expect(dt.unpublished?).to eq true

      dt2 = @course.discussion_topics.last
      expect(dt2.title).to eq "News forum"
      expect(dt2.message).to eq "<p>General news and announcements</p>"
    end
  end

  context "assignments" do
    it "should convert assignments" do
      expect(@course.assignments.count).to eq 2

      assignment2 = @course.assignments.find_by_title 'Hidden Assignmnet'
      expect(assignment2.description).to eq "<p>This is a hidden assignment</p>"
      expect(assignment2.unpublished?).to eq true
    end
  end

  context "wiki pages" do
    it "should convert wikis" do
      wiki = @course.wiki
      expect(wiki).not_to be_nil
      expect(wiki.wiki_pages.count).to eq 12

      page1 = wiki.wiki_pages.find_by_title 'Hidden Section'
      expect(page1.body).to eq '<p>This is a Hidden Section, with hidden items</p>'
      expect(page1.unpublished?).to eq true
    end
  end

  context "quizzes" do
    before(:each) do
      skip if !Qti.qti_enabled?
    end

    it "should convert quizzes" do
      expect(@course.quizzes.count).to eq 2
    end

    it "should convert Moodle Quiz module to a quiz" do
      quiz = @course.quizzes.find_by_title "Quiz Name"
      expect(quiz.description).to match /Quiz Description/
      expect(quiz.quiz_questions.count).to eq 11
    end

    it "should convert Moodle Questionnaire module to a quiz" do
      quiz = @course.quizzes.find_by_title "Questionnaire Name"
      expect(quiz.description).to match /Sumary/
      expect(quiz.quiz_type).to eq 'survey'
      expect(quiz.quiz_questions.count).to eq 10
    end
  end
end
