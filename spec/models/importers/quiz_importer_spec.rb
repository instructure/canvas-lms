# frozen_string_literal: true

#
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
#

require_relative "../../import_helper"

describe "Importers::QuizImporter" do
  before(:once) do
    course_model
    @migration = @course.content_migrations.create!
  end

  it "gets the quiz properties" do
    context = course_model
    question_data = import_example_questions
    data = get_import_data ["vista", "quiz"], "simple_quiz_data"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
    quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first
    expect(quiz.title).to eq data[:title]
    expect(quiz.scoring_policy).to eq data[:which_attempt_to_keep]
    expect(quiz.migration_id).to eq data[:migration_id]
    expect(quiz.allowed_attempts).to eq data[:allowed_attempts]
    expect(quiz.time_limit).to eq data[:time_limit]
    expect(quiz.shuffle_answers).to eq data[:shuffle_answers]
    expect(quiz.show_correct_answers).to eq data[:show_correct_answers]
  end

  context "when importing to new quizzes" do
    before do
      allow(@migration).to receive(:quizzes_next_migration?).and_return(true)
    end

    it "does not set the description field for the classic quiz" do
      context = course_model
      question_data = import_example_questions
      data = get_import_data ["vista", "quiz"], "simple_quiz_data"
      Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
      quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first
      expect(data["description"]).to be_present
      expect(quiz.description).to be_nil
    end

    context "when the original quiz has points" do
      it "retains the points from the original quiz" do
        context = course_model
        question_data = import_example_questions
        data = get_import_data ["vista", "quiz"], "simple_quiz_data"

        Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
        quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

        expect(quiz.points_possible).to eq data[:points_possible]
        expect(quiz.points_possible).to be > 0
      end

      context "when the quiz is available" do
        it "retains the points from the original quiz regardless of the duplicated quiz points count" do
          allow(Quizzes::Quiz).to receive(:count_points_possible).and_return(0.0)

          context = course_model
          question_data = import_example_questions
          data = get_import_data ["vista", "quiz"], "simple_quiz_data"
          data[:available] = true

          Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
          quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

          expect(quiz.points_possible).to eq data[:points_possible]
          expect(quiz.points_possible).to be > 0
        end
      end
    end
  end

  it "completes a quiz question reference" do
    context = course_model
    question_data = import_example_questions
    data = get_import_data ["vista", "quiz"], "simple_quiz_data"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
    quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first
    expect(quiz.quiz_questions.active.count).to eq 1
    # Check if the expected question name is in there
    expect(quiz.quiz_questions.active.first.question_data[:question_name]).to eq "Rocket Bee!"
  end

  it "imports a text only question" do
    context = get_import_context
    question_data = import_example_questions
    data = get_import_data ["vista", "quiz"], "text_only_quiz_data"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
    quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first
    expect(quiz.unpublished_question_count).to eq 1 # text-only questions don't count
    expect(quiz.quiz_questions.active.count).to eq 2
    sorted_questions = quiz.quiz_questions.active.sort_by(&:id)
    expect(sorted_questions.first.question_data[:question_text]).to eq data[:questions].first[:question_text]
    expect(sorted_questions.first.question_data[:question_type]).to eq "text_only_question"
  end

  it "imports a question group" do
    context = get_import_context
    question_data = import_example_questions
    data = get_import_data ["vista", "quiz"], "group_quiz_data"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
    quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first
    expect(quiz.quiz_groups.count).to eq 1
    expect(quiz.quiz_groups.first.quiz_questions.active.count).to eq 3
    expect(quiz.quiz_groups.first.pick_count).to eq data[:questions].first[:pick_count]
    expect(quiz.quiz_groups.first.question_points).to eq data[:questions].first[:question_points]
  end

  it "is practice if it's not for an assignment" do
    context = get_import_context
    question_data = import_example_questions
    data = get_import_data ["vista", "quiz"], "text_only_quiz_data"
    data["quiz_type"] = "practice_quiz"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
    expect(Quizzes::Quiz.count).to eq 1
    quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first
    expect(quiz.assignment).to be_nil
  end

  it "does not build an assignment, instead set to unpublished for canvas imports" do
    context = get_import_context

    quiz_hash = get_import_data ["vista", "quiz"], "simple_quiz_data"
    data = { "assessments" => { "assessments" => [quiz_hash] } }
    migration = context.content_migrations.create!
    allow(migration).to receive(:canvas_import?).and_return(true)
    Importers::CourseContentImporter.import_content(context, data, @migration, migration)

    expect(Assignment.count).to eq 0
    expect(Quizzes::Quiz.count).to eq 1

    quiz = Quizzes::Quiz.where(migration_id: quiz_hash[:migration_id]).first
    expect(quiz.unpublished?).to be true
    expect(quiz.assignment).to be_nil
  end

  it "builds an assignment for non-canvas imports" do
    context = get_import_context

    quiz_hash = get_import_data ["vista", "quiz"], "simple_quiz_data"
    data = { "assessments" => { "assessments" => [quiz_hash] } }
    migration = context.content_migrations.create!
    allow(migration).to receive(:canvas_import?).and_return(false)
    Importers::CourseContentImporter.import_content(context, data, @migration, migration)

    expect(Assignment.count).to eq 1
    expect(Quizzes::Quiz.count).to eq 1

    quiz = Quizzes::Quiz.where(migration_id: quiz_hash[:migration_id]).first
    expect(quiz.unpublished?).to be true
    expect(quiz.assignment).to_not be_nil
  end

  it "does not create an extra assignment if it already references one (but not set unpublished)" do
    context = get_import_context

    quiz_hash = get_import_data ["vista", "quiz"], "simple_quiz_data"
    assignment_hash = get_import_data "vista", "assignment"
    quiz_hash["assignment_migration_id"] = assignment_hash["migration_id"]

    data = { "assessments" => { "assessments" => [quiz_hash] }, "assignments" => [assignment_hash] }

    migration = context.content_migrations.create!
    Importers::CourseContentImporter.import_content(context, data, @migration, migration)

    expect(Assignment.count).to eq 1
    expect(Quizzes::Quiz.count).to eq 1

    quiz = Quizzes::Quiz.where(migration_id: quiz_hash[:migration_id]).first
    expect(quiz.available?).to be true
    expect(quiz.assignment).not_to be_nil
    expect(quiz.quiz_type).to eq "assignment"
  end

  it "converts relative file references to course-relative file references" do
    context = @course
    import_example_questions
    @migration.resolve_content_links!

    question = AssessmentQuestion.where(migration_id: "4393906433391").first
    expect(question.data[:question_text]).to eq "Why does that bee/rocket ship company suck? <img src=\"/courses/#{context.id}/file_contents/course%20files/rocket.png\">"
    question = AssessmentQuestion.where(migration_id: "URN-X-WEBCT-VISTA_V2-790EA1350E1A681DE0440003BA07D9B4").first
    expect(question.data[:answers].last[:html]).to eq "Chance can't; this is a big problem for evolution. BTW, rockets are cool: <img src=\"/courses/#{context.id}/file_contents/course%20files/rocket.png\">"
  end

  it "updates quiz question on re-import" do
    context = get_import_context
    question_data = import_example_questions
    data = get_import_data ["vista", "quiz"], "simple_quiz_data"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
    quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

    expect(quiz.quiz_questions.active.first.question_data[:question_name]).to eq "Rocket Bee!"

    question_data[:aq_data][data["questions"].first[:migration_id]]["question_name"] = "Not Rocket Bee?"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)

    expect(quiz.quiz_questions.active.first.question_data[:question_name]).to eq "Not Rocket Bee?"
  end

  it "updates quiz question on re-import even if the associated quiz is published" do
    context = get_import_context
    question_data = import_example_questions
    data = get_import_data ["vista", "quiz"], "simple_quiz_data"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
    quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first
    quiz.publish!

    expect(quiz.quiz_questions.active.first.question_data[:question_name]).to eq "Rocket Bee!"

    question_data[:aq_data][data["questions"].first[:migration_id]]["question_name"] = "Not Rocket Bee?"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)

    expect(quiz.reload.quiz_data).to include(hash_including("question_name" => "Not Rocket Bee?"))
    expect(quiz.quiz_data).to_not include(hash_including("question_name" => "Rocket Bee!"))
  end

  it "does not clear dates if these are null in the source hash" do
    course_model
    quiz_hash = {
      "migration_id" => "ib4834d160d180e2e91572e8b9e3b1bc6",
      "title" => "date clobber or not",
      "due_at" => nil,
      "lock_at" => nil,
      "unlock_at" => nil
    }
    migration = @course.content_migrations.create!
    quiz = @course.quizzes.create! title: "test", due_at: Time.now, unlock_at: 1.day.ago, lock_at: 1.day.from_now, migration_id: "ib4834d160d180e2e91572e8b9e3b1bc6"
    Importers::QuizImporter.import_from_migration(quiz_hash, @course, migration, {})
    quiz.reload
    expect(quiz.title).to eq "date clobber or not"
    expect(quiz.due_at).not_to be_nil
    expect(quiz.unlock_at).not_to be_nil
    expect(quiz.lock_at).not_to be_nil
  end

  it "sets root_account_id correctly" do
    context = course_model
    question_data = import_example_questions
    data = get_import_data ["vista", "quiz"], "simple_quiz_data"
    Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
    quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

    expect(quiz.root_account_id).not_to be_nil
    expect(quiz.quiz_questions.first.root_account_id).to eq quiz.root_account_id
    expect(quiz.root_account_id).to eq @course.root_account_id
  end
end
