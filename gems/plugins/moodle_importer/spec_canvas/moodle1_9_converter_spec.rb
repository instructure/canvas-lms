# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require "nokogiri"

describe MoodleImporter::Converter do
  before :once do
    fixture_dir = File.dirname(__FILE__) + "/fixtures"
    archive_file_path = File.join(fixture_dir, "moodle_backup_1_9.zip")
    unzipped_file_path = create_temp_dir!
    converter = MoodleImporter::Converter.new(export_archive_path: archive_file_path, course_name: "oi", base_download_dir: unzipped_file_path)
    converter.export

    @course_data = converter.course.with_indifferent_access
    @course = Course.create(name: "test course")
    @cm = ContentMigration.create(context: @course)
    Importers::CourseContentImporter.import_content(@course, @course_data, nil, @cm)
  end

  it "imports the course successfully" do
    allowed_warnings = ["Multiple Dropdowns question may have been imported incorrectly",
                        "Possible answers will need to be regenerated for Formula question",
                        "Missing links found in imported content",
                        "There was an error exporting an assessment question - No question type used",
                        "The importer couldn't determine the correct answers for this question."]
    expect(@cm.warnings.all? { |w| allowed_warnings.find { |aw| w.start_with?(aw) } }).to be true
  end

  it "imports files" do
    expect(@course.attachments.count).to eq 1
    expect(@course.attachments.first.full_display_path).to eq "course files/images/facepalm.png"
  end

  it "adds at most 2 warnings per bank for problematic questions" do
    converter = MoodleImporter::Converter.new({ no_archive_file: true })
    test_course = { assessment_questions: { assessment_questions: [
      { "question_type" => "multiple_dropdowns_question", "question_bank_id" => "1" },
      { "question_type" => "calculated_question", "question_bank_id" => "1" },
      { "question_type" => "multiple_dropdowns_question", "question_bank_id" => "2" },
      { "question_type" => "calculated_question", "question_bank_id" => "2" },

      { "question_type" => "multiple_dropdowns_question", "question_bank_id" => "1" },
      { "question_type" => "multiple_dropdowns_question", "question_bank_id" => "1" },
      { "question_type" => "calculated_question", "question_bank_id" => "2" },
      { "question_type" => "calculated_question", "question_bank_id" => "2" },
      { "question_type" => "calculated_question", "question_bank_id" => "2" },

    ] } }.with_indifferent_access

    converter.instance_variable_set(:@course, test_course)
    converter.add_question_warnings
    converted_course = converter.instance_variable_get(:@course)
    questions = converted_course[:assessment_questions][:assessment_questions]
    expect(questions[0]["import_warnings"]).to eq ["There are 3 Multiple Dropdowns questions in this bank that may have been imported incorrectly"]
    expect(questions[1]["import_warnings"]).to eq ["Possible answers will need to be regenerated for Formula question"]
    expect(questions[2]["import_warnings"]).to eq ["Multiple Dropdowns question may have been imported incorrectly"]
    expect(questions[3]["import_warnings"]).to eq ["There are 4 Formula questions in this bank that will need to have their possible answers regenerated"]

    [4, 5, 6, 7, 8].each do |idx|
      expect(questions[idx]["import_warnings"]).to be_nil
    end
  end

  context "discussion topics" do
    it "converts discussion topics" do
      expect(@course.discussion_topics.count).to eq 2

      dt = @course.discussion_topics.first
      expect(dt.title).to eq "General Forum"
      expect(dt.message).to eq "General Forum Introduction"

      dt = @course.discussion_topics.last
      expect(dt.title).to eq "News forum"
      expect(dt.message).to eq "General news and announcements"
    end
  end

  context "assignments" do
    it "converts assignments" do
      expect(@course.assignments.where.not(migration_id: nil).count).to eq 6

      assignment = @course.assignments.where(title: "Create a Rails site").first
      expect(assignment).not_to be_nil
      expect(assignment.description).to eq "Use `rails new` to create your first Rails site"
    end

    it "converts Moodle Workshop to peer reviewed assignment" do
      assignment = @course.assignments.where(title: "My Workshop").first
      expect(assignment).not_to be_nil
      expect(assignment.description).to eq "My Workshop Description"
      expect(assignment.peer_reviews).to be_truthy
      expect(assignment.automatic_peer_reviews).to be_truthy
      # assignment.anonymous_peer_reviews.should be_false
      expect(assignment.peer_review_count).to eq 5
    end
  end

  context "wiki pages" do
    it "converts wikis" do
      wiki = @course.wiki
      expect(wiki).not_to be_nil
      expect(wiki.wiki_pages.count).to eq 3

      page = wiki.wiki_pages.where(title: "My Wiki").first
      expect(page).not_to be_nil
      expect(page.url).to eq "my-wiki-my-wiki"
      html = Nokogiri::HTML5(page.body)
      href = html.search("a").first.attributes["href"].value
      expect(href).to eq "/courses/#{@course.id}/#{@course.wiki.path}/my-wiki-link"

      page = wiki.wiki_pages.where(title: "link").first
      expect(page).not_to be_nil
      expect(page.url).to eq "my-wiki-link"

      page = wiki.wiki_pages.where(title: "New Wiki").first
      expect(page).not_to be_nil
      expect(page.url).to eq "new-wiki-new-wiki"
    end
  end

  context "quizzes" do
    before do
      skip unless Qti.qti_enabled?
    end

    it "converts quizzes" do
      expect(@course.quizzes.count).to eq 3
    end

    it "converts Moodle Quiz module to a quiz" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      expect(quiz).not_to be_nil
      expect(quiz.description).to match(/Pop quiz hot shot/)
      expect(quiz.quiz_questions.count).to eq 9
    end

    it "converts Moodle Calculated Question to Canvas calculated_question" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      question = quiz.quiz_questions[0]
      expect(question.question_data[:question_name]).to eq "Calculated Question"
      expect(question.question_data[:question_text]).to eq "How much is [a] + [b] ?"
      expect(question.question_data[:question_type]).to eq "calculated_question"
      expect(question.question_data[:neutral_comments]).to eq "Calculated Question General Feedback"

      # add warnings because these question types seem to be ambiguously structured in moodle
      warnings = @cm.migration_issues.select do |w|
        w.description == "Possible answers will need to be regenerated for Formula question" &&
          w.fix_issue_html_url.include?("question_#{question.assessment_question_id}_question_text")
      end
      expect(warnings.count).to eq 1
    end

    it "converts Moodle Description Question to Canvas text_only_question" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      question = quiz.quiz_questions[1]
      expect(question.question_data[:question_name]).to eq "Description Question"
      expect(question.question_data[:question_text]).to eq "Description Question Text"
      expect(question.question_data[:question_type]).to eq "text_only_question"
    end

    it "converts Moodle Essay Question to Canvas essay_question" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      question = quiz.quiz_questions[2]
      expect(question.question_data[:question_name]).to eq "Essay Question"
      expect(question.question_data[:question_text]).to eq "Essay Question Text"
      expect(question.question_data[:question_type]).to eq "essay_question"
      expect(question.question_data[:neutral_comments]).to eq "Essay Question General Feedback"
    end

    it "converts Moodle Matching Question to Canvas matching_question" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      question = quiz.quiz_questions[3]
      expect(question.question_data[:question_name]).to eq "Matching Question"
      expect(question.question_data[:question_text]).to eq "Matching Question Text"
      expect(question.question_data[:question_type]).to eq "matching_question"
      expect(question.question_data[:neutral_comments]).to eq "Matching Question General Feedback"
    end

    it "converts Moodle Embedded Answers Question to Canvas essay_question" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      question = quiz.quiz_questions[4]
      expect(question.question_data[:question_name]).to eq "Embedded Answers Question"
      expect(question.question_data[:question_text]).to match(/Embedded Answers Question Text/)
      expect(question.question_data[:question_type]).to eq "essay_question"
      expect(question.question_data[:neutral_comments]).to eq "Embedded Answers Question General Feedback"
    end

    it "converts Moodle Multiple Choice Question to Canvas multiple_choice_question" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      question = quiz.quiz_questions[5]
      expect(question.question_data[:question_name]).to eq "Multiple Choice Question"
      expect(question.question_data[:question_text]).to eq "Multiple Choice Question Text"
      expect(question.question_data[:question_type]).to eq "multiple_choice_question"
      expect(question.question_data[:neutral_comments]).to eq "Multiple Choice Question General Feedback"
    end

    it "converts Moodle Numerical Question to Canvas numerical_question" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      question = quiz.quiz_questions[6]
      expect(question.question_data[:question_name]).to eq "Numerical Question"
      expect(question.question_data[:question_text]).to eq "Numerical Question Text"
      expect(question.question_data[:question_type]).to eq "numerical_question"
      expect(question.question_data[:neutral_comments]).to eq "Numerical Question General Feedback"
    end

    it "converts Moodle Short Answer Question to Canvas short_answer_question" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      question = quiz.quiz_questions[7]
      expect(question.question_data[:question_name]).to eq "Short Answer Question"
      expect(question.question_data[:question_text]).to eq "Short Answer Question Text"
      expect(question.question_data[:question_type]).to eq "short_answer_question"
      expect(question.question_data[:neutral_comments]).to eq "Short Answer Question General Feedback"
    end

    it "converts Moodle True/False Question to Canvas true_false_question" do
      quiz = @course.quizzes.where(title: "First Quiz").first
      question = quiz.quiz_questions[8]
      expect(question.question_data[:question_name]).to eq "True or False Question"
      expect(question.question_data[:question_text]).to eq "True or False Question Text"
      expect(question.question_data[:question_type]).to eq "true_false_question"
      expect(question.question_data[:neutral_comments]).to eq "True or False Question General Feedback"
    end

    it "converts Moodle Questionnaire module to a quiz" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      expect(quiz).not_to be_nil
      expect(quiz.description).to match(/Questionnaire Summary/)
      expect(quiz.quiz_type).to eq "survey"
      expect(quiz.quiz_questions.count).to eq 10
    end

    it "converts Moodle Questionnaire Check Boxes Question to Canvas multiple_answers_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[0]
      expect(question.question_data[:question_name]).to eq "Check Boxes Question"
      expect(question.question_data[:question_text]).to eq "Check Boxes Question Text"
      expect(question.question_data[:question_type]).to eq "multiple_answers_question"
    end

    it "converts Moodle Questionnaire Date Question to Canvas essay_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[1]
      expect(question.question_data[:question_name]).to eq "Date Question"
      expect(question.question_data[:question_text]).to eq "Date Question Text"
      expect(question.question_data[:question_type]).to eq "essay_question"
    end

    it "converts Moodle Questionnaire Dropdown Box Question to Canvas multiple_choice_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[2]
      expect(question.question_data[:question_name]).to eq "Dropdown Box Question"
      expect(question.question_data[:question_text]).to eq "Dropdown Box Question Text"
      expect(question.question_data[:question_type]).to eq "multiple_choice_question"
    end

    it "converts Moodle Questionnaire Essay Box Question to Canvas essay_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[3]
      expect(question.question_data[:question_name]).to eq "Essay Box Question"
      expect(question.question_data[:question_text]).to eq "Essay Box Question Text"
      expect(question.question_data[:question_type]).to eq "essay_question"
    end

    it "converts Moodle Questionnaire Label to Canvas text_only_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[4]
      expect(question.question_data[:question_name]).to eq ""
      expect(question.question_data[:question_text]).to eq "Label Text"
      expect(question.question_data[:question_type]).to eq "text_only_question"
    end

    it "converts Moodle Questionnaire Numeric Question to Canvas numerical_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[5]
      expect(question.question_data[:question_name]).to eq "Numeric Question"
      expect(question.question_data[:question_text]).to eq "Numeric Question Text"
      expect(question.question_data[:question_type]).to eq "numerical_question"
    end

    it "converts Moodle Questionnaire Radio Buttons Question to Canvas multiple_choice_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[6]
      expect(question.question_data[:question_name]).to eq "Radio Buttons Question"
      expect(question.question_data[:question_text]).to eq "Radio Buttons Question Text"
      expect(question.question_data[:question_type]).to eq "multiple_choice_question"
    end

    it "converts Moodle Questionnaire Rate Scale 1..5 Question to Canvas multiple_dropdowns_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[7]
      expect(question.question_data[:question_name]).to eq "Rate Scale 1..5 Question"
      expect(question.question_data[:question_text]).to eq "Rate Scale 1..5 Question Text\nquestion1 [response1]\nquestion2 [response2]\nquestion3 [response3]"
      expect(question.question_data[:question_type]).to eq "multiple_dropdowns_question"

      # add warnings because these question types seem to be ambiguously structured in moodle
      warnings = @cm.migration_issues.select do |w|
        w.description == "Multiple Dropdowns question may have been imported incorrectly" &&
          w.fix_issue_html_url.include?("question_#{question.assessment_question_id}")
      end
      expect(warnings.count).to eq 1
    end

    it "converts Moodle Questionnaire Text Box Question to Canvas essay_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[8]
      expect(question.question_data[:question_name]).to eq "Text Box Question"
      expect(question.question_data[:question_text]).to eq "Text Box Question Text"
      expect(question.question_data[:question_type]).to eq "essay_question"
    end

    it "converts Moodle Questionnaire Yes/No Question to Canvas true_false_question" do
      quiz = @course.quizzes.where(title: "My Questionnaire").first
      question = quiz.quiz_questions[9]
      expect(question.question_data[:question_name]).to eq "Yes No Question"
      expect(question.question_data[:question_text]).to eq "Yes No Question Text"
      expect(question.question_data[:question_type]).to eq "multiple_choice_question"
    end

    it "converts Moodle Choice module to a quiz" do
      quiz = @course.quizzes.where(title: "My Choice").first
      expect(quiz).not_to be_nil
      expect(quiz.description).to match(/Which one will you choose\?/)
      expect(quiz.quiz_type).to eq "survey"
      expect(quiz.quiz_questions.count).to eq 1
      question = quiz.quiz_questions.first
      expect(question.question_data[:question_name]).to eq "My Choice"
      expect(question.question_data[:question_text]).to eq "Which one will you choose?"
    end
  end
end
