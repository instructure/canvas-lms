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
    @cm.old_warnings_format.all?{|w| allowed_warnings.find{|aw| w[0].start_with?(aw)}}.should == true
  end

  context "discussion topics" do
    it "should convert discussion topics" do
      @course.discussion_topics.count.should == 2

      dt = @course.discussion_topics.first
      dt.title.should == "Hidden Forum"
      dt.message.should == "<p>Description of hidden forum</p>"
      dt.unpublished?.should == true

      dt2 = @course.discussion_topics.last
      dt2.title.should == "News forum"
      dt2.message.should == "<p>General news and announcements</p>"
    end
  end

  context "assignments" do
    it "should convert assignments" do
      @course.assignments.count.should == 2

      assignment2 = @course.assignments.find_by_title 'Hidden Assignmnet'
      assignment2.description.should == "<p>This is a hidden assignment</p>"
      assignment2.unpublished?.should == true
    end
  end

  context "wiki pages" do
    it "should convert wikis" do
      wiki = @course.wiki
      wiki.should_not be_nil
      wiki.wiki_pages.count.should == 12

      page1 = wiki.wiki_pages.find_by_title 'Hidden Section'
      page1.body.should == '<p>This is a Hidden Section, with hidden items</p>'
      page1.unpublished?.should == true
    end
  end

  context "quizzes" do
    before(:each) do
      pending if !Qti.qti_enabled?
    end

    it "should convert quizzes" do
      @course.quizzes.count.should == 2
    end

    it "should convert Moodle Quiz module to a quiz" do
      quiz = @course.quizzes.find_by_title "Quiz Name"
      quiz.description.should match /Quiz Description/
      quiz.quiz_questions.count.should == 11
    end

    it "should convert Moodle Questionnaire module to a quiz" do
      quiz = @course.quizzes.find_by_title "Questionnaire Name"
      quiz.description.should match /Sumary/
      quiz.quiz_type.should == 'survey'
      quiz.quiz_questions.count.should == 10
    end
  end
end
