require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Moodle::Converter do

  before :once do
    fixture_dir = File.dirname(__FILE__) + '/fixtures'
    archive_file_path = File.join(fixture_dir, 'moodle_backup_1_9.zip')
    unzipped_file_path = File.join(File.dirname(archive_file_path), "moodle_#{File.basename(archive_file_path, '.zip')}", 'oi')
    converter = Moodle::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
    converter.export

    @course_data = converter.course.with_indifferent_access
    @course = Course.create(:name => "test course")
    @cm = ContentMigration.create(:context => @course)
    Importers::CourseContentImporter.import_content(@course, @course_data, nil, @cm)

    converter.delete_unzipped_archive
    if File.exists?(unzipped_file_path)
      FileUtils::rm_rf(unzipped_file_path)
    end
  end

  it "should successfully import the course" do
    allowed_warnings = ["Multiple Dropdowns question may have been imported incorrectly",
                        "Possible answers will need to be regenerated for Formula question",
                        "Missing links found in imported content"]
    @cm.old_warnings_format.all?{|w| allowed_warnings.find{|aw| w[0].start_with?(aw)}}.should == true
  end

  it "should import files" do
    @course.attachments.count.should == 1
    @course.attachments.first.full_display_path.should == "course files/images/facepalm.png"
  end

  it "should add at most 2 warnings per bank for problematic questions" do
    converter = Moodle::Converter.new({:no_archive_file => true})
    test_course = {:assessment_questions => {:assessment_questions => [
      {'question_type' => 'multiple_dropdowns_question', 'question_bank_id' => '1'},
      {'question_type' => 'calculated_question', 'question_bank_id' => '1'},
      {'question_type' => 'multiple_dropdowns_question', 'question_bank_id' => '2'},
      {'question_type' => 'calculated_question', 'question_bank_id' => '2'},

      {'question_type' => 'multiple_dropdowns_question', 'question_bank_id' => '1'},
      {'question_type' => 'multiple_dropdowns_question', 'question_bank_id' => '1'},
      {'question_type' => 'calculated_question', 'question_bank_id' => '2'},
      {'question_type' => 'calculated_question', 'question_bank_id' => '2'},
      {'question_type' => 'calculated_question', 'question_bank_id' => '2'},

    ]}}.with_indifferent_access

    converter.instance_variable_set(:@course, test_course)
    converter.add_question_warnings
    converted_course = converter.instance_variable_get(:@course)
    questions = converted_course[:assessment_questions][:assessment_questions]
    questions[0]['import_warnings'].should == ["There are 3 Multiple Dropdowns questions in this bank that may have been imported incorrectly"]
    questions[1]['import_warnings'].should == ["Possible answers will need to be regenerated for Formula question"]
    questions[2]['import_warnings'].should == ["Multiple Dropdowns question may have been imported incorrectly"]
    questions[3]['import_warnings'].should == ["There are 4 Formula questions in this bank that will need to have their possible answers regenerated"]

    [4, 5, 6, 7, 8].each do |idx|
      questions[idx]['import_warnings'].should be_nil
    end
  end

  context "discussion topics" do
    it "should convert discussion topics" do
      @course.discussion_topics.count.should == 2

      dt = @course.discussion_topics.first
      dt.title.should == "General Forum"
      dt.message.should == "<p>General Forum Introduction</p>"

      dt = @course.discussion_topics.last
      dt.title.should == "News forum"
      dt.message.should == "<p>General news and announcements</p>"
    end
  end

  context "assignments" do
    it "should convert assignments" do
      @course.assignments.count.should == 6

      assignment = @course.assignments.find_by_title 'Create a Rails site'
      assignment.should_not be_nil
      assignment.description.should == "<p>Use `rails new` to create your first Rails site</p>"
    end

    it "should convert Moodle Workshop to peer reviewed assignment" do
      assignment = @course.assignments.find_by_title 'My Workshop'
      assignment.should_not be_nil
      assignment.description.should == "<p>My Workshop Description</p>"
      assignment.peer_reviews.should be_true
      assignment.automatic_peer_reviews.should be_true
      #assignment.anonymous_peer_reviews.should be_false
      assignment.peer_review_count.should == 5
    end
  end

  context "wiki pages" do
    it "should convert wikis" do
      wiki = @course.wiki
      wiki.should_not be_nil
      wiki.wiki_pages.count.should == 3

      page = wiki.wiki_pages.find_by_title 'My Wiki'
      page.should_not be_nil
      page.url.should == 'my-wiki-my-wiki'
      html = Nokogiri::HTML(page.body)
      href = html.search('a').first.attributes['href'].value
      href.should == "/courses/#{@course.id}/wiki/my-wiki-link"

      page = wiki.wiki_pages.find_by_title 'link'
      page.should_not be_nil
      page.url.should == 'my-wiki-link'

      page = wiki.wiki_pages.find_by_title 'New Wiki'
      page.should_not be_nil
      page.url.should == 'new-wiki-new-wiki'
    end
  end

  context "quizzes" do
    before(:each) do
      pending if !Qti.qti_enabled?
    end

    it "should convert quizzes" do
      @course.quizzes.count.should == 3
    end

    it "should convert Moodle Quiz module to a quiz" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      quiz.should_not be_nil
      quiz.description.should match /Pop quiz hot shot/
      quiz.quiz_questions.count.should == 9
    end

    it "should convert Moodle Calculated Question to Canvas calculated_question" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      question = quiz.quiz_questions[0]
      question.question_data[:question_name].should == "Calculated Question"
      question.question_data[:question_text].should == "How much is [a] + [b] ?"
      question.question_data[:question_type].should == 'calculated_question'
      question.question_data[:neutral_comments].should == 'Calculated Question General Feedback'

      # add warnings because these question types seem to be ambiguously structured in moodle
      warnings = @cm.migration_issues.select{|w|
        w.description == "Possible answers will need to be regenerated for Formula question" &&
            w.fix_issue_html_url.include?("question_#{question.assessment_question_id}")
      }
      warnings.count.should == 1
    end

    it "should convert Moodle Description Question to Canvas text_only_question" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      question = quiz.quiz_questions[1]
      question.question_data[:question_name].should == "Description Question"
      question.question_data[:question_text].should == "Description Question Text"
      question.question_data[:question_type].should == 'text_only_question'
    end

    it "should convert Moodle Essay Question to Canvas essay_question" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      question = quiz.quiz_questions[2]
      question.question_data[:question_name].should == "Essay Question"
      question.question_data[:question_text].should == "Essay Question Text"
      question.question_data[:question_type].should == 'essay_question'
      question.question_data[:neutral_comments].should == 'Essay Question General Feedback'
    end

    it "should convert Moodle Matching Question to Canvas matching_question" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      question = quiz.quiz_questions[3]
      question.question_data[:question_name].should == "Matching Question"
      question.question_data[:question_text].should == "Matching Question Text"
      question.question_data[:question_type].should == 'matching_question'
      question.question_data[:neutral_comments].should == 'Matching Question General Feedback'
    end

    it "should convert Moodle Embedded Answers Question to Canvas essay_question" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      question = quiz.quiz_questions[4]
      question.question_data[:question_name].should == "Embedded Answers Question"
      question.question_data[:question_text].should match /Embedded Answers Question Text/
      question.question_data[:question_type].should == 'essay_question'
      question.question_data[:neutral_comments].should == 'Embedded Answers Question General Feedback'
    end

    it "should convert Moodle Multiple Choice Question to Canvas multiple_choice_question" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      question = quiz.quiz_questions[5]
      question.question_data[:question_name].should == "Multiple Choice Question"
      question.question_data[:question_text].should == "Multiple Choice Question Text"
      question.question_data[:question_type].should == 'multiple_choice_question'
      question.question_data[:neutral_comments].should == 'Multiple Choice Question General Feedback'
    end

    it "should convert Moodle Numerical Question to Canvas numerical_question" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      question = quiz.quiz_questions[6]
      question.question_data[:question_name].should == "Numerical Question"
      question.question_data[:question_text].should == "Numerical Question Text"
      question.question_data[:question_type].should == 'numerical_question'
      question.question_data[:neutral_comments].should == 'Numerical Question General Feedback'
    end

    it "should convert Moodle Short Answer Question to Canvas short_answer_question" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      question = quiz.quiz_questions[7]
      question.question_data[:question_name].should == "Short Answer Question"
      question.question_data[:question_text].should == "Short Answer Question Text"
      question.question_data[:question_type].should == 'short_answer_question'
      question.question_data[:neutral_comments].should == 'Short Answer Question General Feedback'
    end

    it "should convert Moodle True/False Question to Canvas true_false_question" do
      quiz = @course.quizzes.find_by_title "First Quiz"
      question = quiz.quiz_questions[8]
      question.question_data[:question_name].should == "True or False Question"
      question.question_data[:question_text].should == "True or False Question Text"
      question.question_data[:question_type].should == 'true_false_question'
      question.question_data[:neutral_comments].should == 'True or False Question General Feedback'
    end

    it "should convert Moodle Questionnaire module to a quiz" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      quiz.should_not be_nil
      quiz.description.should match /Questionnaire Summary/
      quiz.quiz_type.should == 'survey'
      quiz.quiz_questions.count.should == 10
    end

    it "should convert Moodle Questionnaire Check Boxes Question to Canvas multiple_answers_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[0]
      question.question_data[:question_name].should == "Check Boxes Question"
      question.question_data[:question_text].should == "Check Boxes Question Text"
      question.question_data[:question_type].should == 'multiple_answers_question'
    end

    it "should convert Moodle Questionnaire Date Question to Canvas essay_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[1]
      question.question_data[:question_name].should == "Date Question"
      question.question_data[:question_text].should == "Date Question Text"
      question.question_data[:question_type].should == 'essay_question'
    end

    it "should convert Moodle Questionnaire Dropdown Box Question to Canvas multiple_choice_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[2]
      question.question_data[:question_name].should == "Dropdown Box Question"
      question.question_data[:question_text].should == "Dropdown Box Question Text"
      question.question_data[:question_type].should == 'multiple_choice_question'
    end

    it "should convert Moodle Questionnaire Essay Box Question to Canvas essay_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[3]
      question.question_data[:question_name].should == "Essay Box Question"
      question.question_data[:question_text].should == "Essay Box Question Text"
      question.question_data[:question_type].should == 'essay_question'
    end

    it "should convert Moodle Questionnaire Label to Canvas text_only_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[4]
      question.question_data[:question_name].should == ""
      question.question_data[:question_text].should == "Label Text"
      question.question_data[:question_type].should == 'text_only_question'
    end

    it "should convert Moodle Questionnaire Numeric Question to Canvas numerical_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[5]
      question.question_data[:question_name].should == "Numeric Question"
      question.question_data[:question_text].should == "Numeric Question Text"
      question.question_data[:question_type].should == 'numerical_question'
    end

    it "should convert Moodle Questionnaire Radio Buttons Question to Canvas multiple_choice_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[6]
      question.question_data[:question_name].should == "Radio Buttons Question"
      question.question_data[:question_text].should == "Radio Buttons Question Text"
      question.question_data[:question_type].should == 'multiple_choice_question'
    end

    it "should convert Moodle Questionnaire Rate Scale 1..5 Question to Canvas multiple_dropdowns_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[7]
      question.question_data[:question_name].should == "Rate Scale 1..5 Question"
      question.question_data[:question_text].should == "Rate Scale 1..5 Question Text\nquestion1 [response1]\nquestion2 [response2]\nquestion3 [response3]"
      question.question_data[:question_type].should == 'multiple_dropdowns_question'

      # add warnings because these question types seem to be ambiguously structured in moodle
      warnings = @cm.migration_issues.select{|w|
        w.description == "Multiple Dropdowns question may have been imported incorrectly" &&
          w.fix_issue_html_url.include?("question_#{question.assessment_question_id}")
      }
      warnings.count.should == 1
    end

    it "should convert Moodle Questionnaire Text Box Question to Canvas essay_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[8]
      question.question_data[:question_name].should == "Text Box Question"
      question.question_data[:question_text].should == "Text Box Question Text"
      question.question_data[:question_type].should == 'essay_question'
    end

    it "should convert Moodle Questionnaire Yes/No Question to Canvas true_false_question" do
      quiz = @course.quizzes.find_by_title "My Questionnaire"
      question = quiz.quiz_questions[9]
      question.question_data[:question_name].should == "Yes No Question"
      question.question_data[:question_text].should == "Yes No Question Text"
      question.question_data[:question_type].should == 'true_false_question'
    end

    it "should convert Moodle Choice module to a quiz" do
      quiz = @course.quizzes.find_by_title "My Choice"
      quiz.should_not be_nil
      quiz.description.should match /Which one will you choose\?/
      quiz.quiz_type.should == 'survey'
      quiz.quiz_questions.count.should == 1
      question = quiz.quiz_questions.first
      question.question_data[:question_name].should == "My Choice"
      question.question_data[:question_text].should == "Which one will you choose?"
    end
  end
end
