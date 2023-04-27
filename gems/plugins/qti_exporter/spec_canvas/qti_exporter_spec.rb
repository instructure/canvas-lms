# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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

require "zip/filesystem"

if Qti.migration_executable

  describe Qti::Converter do
    before do
      course_with_teacher(active_all: true)
    end

    let(:respondus_questions) do
      [{ "position" => 1,
         "correct_comments" => "This is the correct answer feedback",
         "question_type" => "multiple_choice_question",
         "question_bank_name" => "Instructure Question Types",
         "assessment_question_id" => "18",
         "neutral_comments" => "This is some general feedback.",
         "incorrect_comments" => "This is the incorrect answer feedback",
         "migration_id" => "QUE_1006",
         "points_possible" => 1.5,
         "question_name" => "MC Question 1",
         "answers" =>
         [{ "comments" => "choice 1 feedback",
            "migration_id" => "QUE_1008_A1",
            "text" => "Answer choice 1",
            "weight" => 100,
            "id" => 304 },
          { "comments" => "choice 2 feedback",
            "migration_id" => "QUE_1009_A2",
            "text" => "Answer choice 2",
            "weight" => 0,
            "id" => 6301 },
          { "comments" => "choice 3 feedback",
            "migration_id" => "QUE_1010_A3",
            "text" => "Answer choice 3",
            "weight" => 0,
            "id" => 6546 },
          { "comments" => "choice 4 feedback",
            "migration_id" => "QUE_1011_A4",
            "text" => "Answer choice 4",
            "weight" => 0,
            "id" => 9001 }],
         "question_text" =>
         "This is the question text.<br>\nThese are some symbol font characters: <span style=\"font-size:12pt;\">∂♥∃Δƒ</span>" },
       { "position" => 2,
         "correct_comments" => "correct answer feedback",
         "question_type" => "true_false_question",
         "question_bank_name" => "Instructure Question Types",
         "assessment_question_id" => "19",
         "neutral_comments" => "general feedback",
         "incorrect_comments" => "incorrect answer feedback",
         "migration_id" => "QUE_1019",
         "points_possible" => 1,
         "question_name" => "TF Question 1",
         "answers" =>
         [{ "comments" => "true answer feedback",
            "migration_id" => "QUE_1021_A1",
            "text" => "True",
            "weight" => 100,
            "id" => 55 },
          { "comments" => "false answer feedback",
            "migration_id" => "QUE_1022_A2",
            "text" => "False",
            "weight" => 0,
            "id" => 3501 }],
         "question_text" => "This is the question wording." },
       { "position" => 3,
         "correct_comments" => "correct feed",
         "question_type" => "short_answer_question",
         "question_bank_name" => "Instructure Question Types",
         "assessment_question_id" => "20",
         "neutral_comments" => "general feed",
         "incorrect_comments" => "incorrect feed",
         "migration_id" => "QUE_1028",
         "points_possible" => 1,
         "question_name" => "FIB Question 1",
         "answers" =>
         [{ "comments" => "", "text" => "correct answer 1", "weight" => 100, "id" => 4954 },
          { "comments" => "", "text" => "correct answer 2", "weight" => 100, "id" => 6688 }],
         "question_text" => "This is the question text." },
       { "position" => 4,
         "correct_comments" => "correct feed",
         "question_type" => "fill_in_multiple_blanks_question",
         "question_bank_name" => "Instructure Question Types",
         "assessment_question_id" => "21",
         "neutral_comments" => "general feed",
         "incorrect_comments" => "incorrect feed",
         "migration_id" => "QUE_1034",
         "points_possible" => 2,
         "question_name" => "FIMB Question 1",
         "answers" =>
         [{ "text" => "question", "weight" => 100, "id" => 346, "blank_id" => "a" },
          { "text" => "interrogative", "weight" => 100, "id" => 7169, "blank_id" => "a" },
          { "text" => "Fill in Multiple Blanks",
            "weight" => 100,
            "id" => 1578,
            "blank_id" => "b" }],
         "question_text" => "This is the [a] wording for a [b] question." },
       { "position" => 5,
         "correct_comments" => "correct feed",
         "question_type" => "multiple_answers_question",
         "question_bank_name" => "Instructure Question Types",
         "assessment_question_id" => "22",
         "neutral_comments" => "general feed",
         "incorrect_comments" => "incorrect feed",
         "migration_id" => "QUE_1038",
         "points_possible" => 2,
         "question_name" => "MA Question 1",
         "answers" =>
         [{ "comments" => "choice feed 1",
            "migration_id" => "QUE_1040_A1",
            "text" => "This is incorrect answer 1",
            "weight" => 0,
            "id" => 1897 },
          { "comments" => "choice feed 2",
            "migration_id" => "QUE_1041_A2",
            "text" => "This is correct answer 1",
            "weight" => 100,
            "id" => 1865 },
          { "comments" => "choice feed 3",
            "migration_id" => "QUE_1042_A3",
            "text" => "This is incorrect answer 2",
            "weight" => 0,
            "id" => 8381 },
          { "comments" => "choice feed 4",
            "migration_id" => "QUE_1043_A4",
            "text" => "This is correct answer 2",
            "weight" => 100,
            "id" => 9111 }],
         "question_text" => "This is the question text." },
       { "position" => 6,
         "correct_comments" => "correct feed",
         "question_type" => "numerical_question",
         "question_bank_name" => "Instructure Question Types",
         "assessment_question_id" => "23",
         "neutral_comments" => "general feed",
         "incorrect_comments" => "incorrect feed",
         "migration_id" => "QUE_1051",
         "points_possible" => 1,
         "question_name" => "NA Question 1",
         "answers" =>
         [{ "comments" => "",
            "numerical_answer_type" => "range_answer",
            "weight" => 100,
            "end" => 1.3,
            "id" => 9082,
            "start" => 1.2 }],
         "question_text" => "This is the question wording." },
       { "position" => 7,
         "correct_comments" => "",
         "question_type" => "text_only_question",
         "question_bank_name" => "Instructure Question Types",
         "assessment_question_id" => "24",
         "incorrect_comments" => "",
         "migration_id" => "QUE_1053",
         "points_possible" => 1,
         "question_name" => "TX Question 1",
         "answers" => [],
         "question_text" => "This is the question wording." },
       { "position" => 8,
         "correct_comments" => "",
         "question_type" => "essay_question",
         "question_bank_name" => "Instructure Question Types",
         "assessment_question_id" => "25",
         "neutral_comments" => "correct answer feedback",
         "incorrect_comments" => "",
         "migration_id" => "QUE_1054",
         "points_possible" => 1,
         "question_name" => "ES Question 1",
         "answers" => [],
         "question_text" => "This is the question text." },
       { "position" => 9,
         "correct_comments" => "correct feed",
         "question_type" => "matching_question",
         "question_bank_name" => "Instructure Question Types",
         "assessment_question_id" => "26",
         "neutral_comments" => "general feed",
         "incorrect_comments" => "incorrect feed",
         "migration_id" => "QUE_1061",
         "points_possible" => 1,
         "question_name" => "MT Question 1",
         "answers" =>
         [{ "comments" => "",
            "match_id" => 342,
            "text" => "Matching left side 1",
            "left" => "Matching left side 1",
            "id" => 2740,
            "right" => "Matching right side 1" },
          { "comments" => "",
            "match_id" => 8808,
            "text" => "Matching L2",
            "left" => "Matching L2",
            "id" => 6479,
            "right" => "Matching right side 2" },
          { "comments" => "",
            "match_id" => 9565,
            "text" => "Matching left side 3",
            "left" => "Matching left side 3",
            "id" => 3074,
            "right" => "Matching right side 3" },
          { "comments" => "",
            "match_id" => 1142,
            "text" => "Matching left side 4",
            "left" => "Matching left side 4",
            "id" => 7696,
            "right" => "Matching right side 4" }],
         "matches" =>
         [{ "match_id" => 342, "text" => "Matching right side 1" },
          { "match_id" => 8808, "text" => "Matching right side 2" },
          { "match_id" => 9565, "text" => "Matching right side 3" },
          { "match_id" => 1142, "text" => "Matching right side 4" },
          { "match_id" => 5875, "text" => "Distractor 1" },
          { "match_id" => 2330, "text" => "Distractor 2" }],
         "question_text" => "This is the question text." }]
    end

    it "imports duplicate files once, without munging" do
      setup_migration
      do_migration

      expect(@course.attachments.count).to eq 2
      expect(@course.attachments.map(&:filename).sort).to eq ["header-logo.png", "smiley.jpg"]
      attachment = @course.attachments.detect { |a| a.filename == "header-logo.png" }
      quiz = @course.quizzes.last
      expect(quiz).to be_present
      expect(quiz.quiz_questions.count).to eq 2
      quiz.quiz_questions.each do |q|
        text = Nokogiri::HTML5.fragment(q.question_data["question_text"])
        expect(text.css("img").first["src"]).to eq "/courses/#{@course.id}/files/#{attachment.id}/preview"

        # verify that the associated assessment_question got links translated
        aq = q.assessment_question
        text = Nokogiri::HTML5.fragment(aq.question_data["question_text"])
        expect(text.css("img").first["src"]).to match %r{/assessment_questions/#{aq.id}/files/\d+/download\?verifier=\w+}

        if aq.question_data["answers"][1]["comments_html"]&.include?("<img")
          text = Nokogiri::HTML5.fragment(aq.question_data["answers"][1]["comments_html"])
          expect(text.css("img").first["src"]).to match %r{/assessment_questions/#{aq.id}/files/\d+/download\?verifier=\w+}
        end
      end
      expect(quiz.assignment).to_not be_nil
    end

    it "brings in canvas meta data" do
      setup_migration(File.expand_path("fixtures/qti/canvas_qti.zip", __dir__))
      do_migration
      expect(@course.quizzes.count).to eq 1
      expect(@course.quizzes.first.description).to eq "<p>Quiz Description</p>"
    end

    describe "applying respondus settings" do
      before do
        @copy = Tempfile.new(["spec-canvas", ".zip"])
        FileUtils.cp(fname, @copy.path)
        Zip::File.open(@copy.path) do |zf|
          zf.file.open("settings.xml", +"w") do |f|
            f.write <<~XML
              <settings>
                <setting name='hasSettings'>true</setting>
                <setting name='publishNow'>true</setting>
              </settings>
            XML
          end
        end
        setup_migration(@copy.path)
        @migration.update_migration_settings(apply_respondus_settings_file: true)
        @migration.save!
      end

      it "publishes as assignment on import if specified" do
        do_migration

        quiz = @course.quizzes.last
        expect(quiz).to be_present
        expect(quiz.assignment).not_to be_nil
        expect(quiz.assignment.title).to eq quiz.title
        expect(quiz.assignment).to be_published
      end

      it "re-uses the same assignment on update" do
        do_migration

        setup_migration(@copy.path)
        @migration.update_migration_settings(apply_respondus_settings_file: true, quiz_id_to_update: @course.quizzes.last.id)
        @migration.save!
        do_migration

        expect(@course.quizzes.size).to eq 1
        expect(@course.assignments.size).to eq 1
        quiz = @course.quizzes.last
        expect(quiz).to be_present
        expect(quiz.assignment).not_to be_nil
        expect(quiz.assignment.title).to eq quiz.title
        expect(quiz.assignment).to be_published
      end

      it "sets the assignment submission_type correctly" do
        do_migration
        assign = @course.assignments.last
        expect(assign.submission_types).to eq "online_quiz"
        expect(assign.quiz).to be_for_assignment
      end
    end

    it "publishes spec-canvas-1 correctly" do
      setup_migration
      do_migration

      quiz = @course.quizzes.last
      expect(quiz).to be_present
      expect(quiz.quiz_questions.size).to eq 2
      # various checks on the data
      qq = quiz.quiz_questions.first
      d = qq.question_data
      expect(d["correct_comments"]).to eq "I can't believe you got that right. Awesome!"
      expect(d["correct_comments_html"]).to eq "I can't <i>believe </i>you got that right. <b>Awesome!</b>"
      expect(d["incorrect_comments_html"]).to eq "<b>Wrong. </b>That's a bummer."
      expect(d["points_possible"]).to eq 3
      expect(d["question_name"]).to eq "q1"
      expect(d["answers"].pluck("weight")).to eq [0, 100, 0]
      expect(d["answers"].pluck("comments")).to eq ["nope", "yes!", nil]
      attachment = @course.attachments.detect { |a| a.filename == "smiley.jpg" }
      expect(d["answers"].pluck("comments_html")).to eq [nil, %(yes! <img src="/courses/#{@course.id}/files/#{attachment.id}/preview" alt="">), nil]
    end

    it "imports respondus question types" do
      setup_migration(File.expand_path("fixtures/canvas_respondus_question_types.zip", __dir__))
      do_migration

      quiz = @course.quizzes.last
      expect(quiz).to be_present
      expect(quiz).not_to be_available
      expect(quiz.quiz_questions.size).to eq 9

      match_ignoring(quiz.quiz_questions.map(&:question_data), respondus_questions, %w[id assessment_question_id match_id prepped_for_import is_quiz_question_bank question_bank_migration_id quiz_question_id])
    end

    it "applies respondus settings" do
      setup_migration(File.expand_path("fixtures/canvas_respondus_question_types.zip", __dir__))
      @migration.update_migration_settings(apply_respondus_settings_file: true)
      @migration.save!
      do_migration

      quiz = @course.quizzes.last
      expect(quiz).to be_present
      expect(quiz).to be_available
    end

    it "is able to import directly into an assessment question bank" do
      setup_migration(File.expand_path("fixtures/canvas_respondus_question_types.zip", __dir__))
      @migration.update_migration_settings(migration_ids_to_import: { copy: { all_quizzes: false, all_assessment_question_banks: true } })
      @migration.save!
      do_migration

      expect(@course.quizzes.count).to eq 0
      qb = @course.assessment_question_banks.last
      expect(qb).to be_present
      expect(qb.assessment_questions.size).to eq 9
      data = qb.assessment_questions.map(&:question_data).sort_by! { |q| q["migration_id"] }
      match_ignoring(data, respondus_questions, %w[id assessment_question_id match_id missing_links position prepped_for_import is_quiz_question_bank question_bank_migration_id quiz_question_id])
    end

    def match_ignoring(a, b, ignoring = []) # rubocop:disable Naming/MethodParameterName
      case a
      when Hash
        a_ = a.except(*ignoring)
        b_ = b.except(*ignoring)
        expect(a_.keys.sort).to eq b_.keys.sort
        a_.each { |k, v| match_ignoring(v, b[k], ignoring) }
      when Array
        expect(a.size).to eq b.size
        a.each_with_index do |e, i|
          match_ignoring(e.to_hash, b[i], ignoring)
        end
      when Quizzes::QuizQuestion::QuestionData
        expect(a.to_hash).to eq b
      else
        expect(a).to eq b
      end
    end

    def fname
      File.expand_path("fixtures/spec-canvas-1.zip", __dir__)
    end

    def setup_migration(zip_path = fname)
      @migration = ContentMigration.new(context: @course,
                                        user: @user)
      @migration.update_migration_settings({
                                             migration_type: "qti_converter",
                                             flavor: Qti::Flavors::RESPONDUS
                                           })
      @migration.save!

      @attachment = Attachment.new
      @attachment.context = @migration
      @attachment.uploaded_data = File.open(zip_path, "rb")
      @attachment.filename = "qti_import_test1.zip"
      @attachment.save!

      @migration.attachment = @attachment
      @migration.save!
    end

    def do_migration
      Canvas::Migration::Worker::QtiWorker.new(@migration.id).perform
      @migration.reload
      expect(@migration).to be_imported
    end
  end

end
