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

    context "common_cartridge_qti_new_quizzes_import" do
      let :context do
        course_model
      end

      let :question_data do
        import_example_questions
      end

      let :data do
        data = get_import_data ["vista", "quiz"], "simple_quiz_data"
        data[:assignment] = {}
        data
      end

      before do
        allow_any_instance_of(ContentMigration)
          .to receive(:for_common_cartridge?)
          .and_return(true)
      end

      context "FF is enabled" do
        before do
          allow(NewQuizzesFeaturesHelper)
            .to receive(:common_cartridge_qti_new_quizzes_import_enabled?)
            .with(instance_of(Course))
            .and_return(true)
        end

        it "updates the content migration to show that a new quiz was imported" do
          data[:qti_new_quiz] = true
          Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
          expect(@migration.reload.migration_settings[:quiz_next_imported]).to be true
        end

        it "marks the assignment as ready to migrate when qti_new_quiz" do
          data[:qti_new_quiz] = true

          Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
          quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

          expect(quiz.assignment.settings["common_cartridge_import"]["migrate_to_quizzes_next"]).to be true
        end

        it "leaves the assignment.settings as nil when not qti_new_quiz" do
          Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
          quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

          expect(quiz.assignment.settings).to be_nil
        end

        context "is import_quizzes_next" do
          before do
            allow(@migration)
              .to receive(:migration_settings)
              .and_return({ import_quizzes_next: true })
          end

          it "marks the assignment as ready to migrate" do
            Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
            quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

            expect(quiz.assignment.settings["common_cartridge_import"]["migrate_to_quizzes_next"]).to be true
          end
        end
      end

      context "FF is disabled" do
        before do
          allow(NewQuizzesFeaturesHelper)
            .to receive(:common_cartridge_qti_new_quizzes_import_enabled?)
            .with(instance_of(Course))
            .and_return(false)
        end

        it "does not mark the assignment as ready to migrate when qti_new_quiz" do
          data[:qti_new_quiz] = true

          Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
          quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

          expect(quiz.assignment.settings).to be_nil
        end

        it "leaves the assignment.settings as nil when not qti_new_quiz" do
          Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
          quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

          expect(quiz.assignment.settings).to be_nil
        end

        context "is import_quizzes_next" do
          before do
            allow(@migration)
              .to receive(:migration_settings)
              .and_return({ import_quizzes_next: true })
          end

          it "marks the assignment as ready to migrate" do
            Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
            quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

            expect(quiz.assignment.settings).to be_nil
          end
        end
      end
    end
  end

  context "when importing qti new quizzes with the setting 'import_quizzes_next' disabled" do
    before do
      allow(@migration).to receive_messages(quizzes_next_migration?: false, canvas_import?: true)
    end

    context "when the original quiz has points different than the quiz entries points" do
      it "retains the points from the original quiz" do
        context = course_model
        question_data = import_example_questions
        data = get_import_data ["vista", "quiz"], "new_quizzes_assignment"

        Importers::QuizImporter.import_from_migration(data, context, @migration, question_data)
        quiz = Quizzes::Quiz.where(migration_id: data[:migration_id]).first

        expect(quiz.points_possible).to eq 10
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
    quiz = @course.quizzes.create! title: "test", due_at: Time.zone.now, unlock_at: 1.day.ago, lock_at: 1.day.from_now, migration_id: "ib4834d160d180e2e91572e8b9e3b1bc6"
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

  describe "import_from_migration date shift saving method" do
    subject { Importers::QuizImporter.import_from_migration(input_hash, course, migration, question_data) }

    let(:course) { course_model }
    let(:migration) { course.content_migrations.create! }
    let(:input_hash) { get_import_data ["vista", "quiz"], "simple_quiz_data" }
    let(:question_data) { import_example_questions }

    context "when FF pre_date_shift_for_assignment_importing enabled" do
      before do
        Account.site_admin.enable_feature!(:pre_date_shift_for_assignment_importing)
      end

      it "should use the try_to_save_with_date_shift method" do
        expect(Importers::QuizImporter)
          .to receive(:try_to_save_with_date_shift).with(kind_of(Quizzes::Quiz), migration).and_call_original
        subject
      end
    end

    context "when FF pre_date_shift_for_assignment_importing disabled" do
      it "should not use the try_to_save_with_date_shift method" do
        expect(Importers::QuizImporter).to_not receive(:try_to_save_with_date_shift)
        subject
      end
    end
  end

  describe "#try_to_save_with_date_shift" do
    subject do
      Importers::QuizImporter.try_to_save_with_date_shift(item, migration)
    end

    let(:course) { Course.create! }
    let(:migration) do
      course.content_migrations.create!(
        migration_settings: {
          date_shift_options: {
            old_start_date: "2023-01-01",
            old_end_date: "2023-12-31",
            new_start_date: "2024-01-01",
            new_end_date: "2024-12-31"
          }
        }
      )
    end
    # This is not saved at this point, so there is no id
    let(:item) { course.quizzes.temp_record }
    let(:original_date) { Time.zone.parse("2023-06-01") }
    let(:original_date_plus_one) { original_date + 1.day }
    # With the given date shift options, this is the expected date
    let(:expected_date) { Time.zone.parse("2024-05-30") }
    let(:deletable_error_fields) { %i[due_at lock_at unlock_at show_correct_answers_at hide_correct_answers_at] }

    context "when there is no date_shift_options on migration" do
      let(:migration) { super().tap { |m| m.migration_settings.delete(:date_shift_options) } }

      before do
        item.update!(
          due_at: original_date,
          lock_at: original_date,
          unlock_at: original_date,
          show_correct_answers_at: original_date,
          hide_correct_answers_at: original_date_plus_one
        )
      end

      it "should not change the due_at field" do
        expect(subject.due_at).to eq(original_date)
      end

      it "should not change the lock_at field" do
        expect(subject.lock_at).to eq(original_date)
      end

      it "should not change the unlock_at field" do
        expect(subject.unlock_at).to eq(original_date)
      end

      it "should not change the show_correct_answers_at field" do
        expect(subject.show_correct_answers_at).to eq(original_date)
      end

      it "should not change the hide_correct_answers_at field" do
        expect(subject.hide_correct_answers_at).to eq(original_date_plus_one)
      end

      it "should early return" do
        expect(Importers::CourseContentImporter).not_to receive(:shift_date_options_from_migration)
        subject
      end
    end

    context "when setting due_at field" do
      context "when field is given" do
        before do
          item.update!(due_at: original_date)
        end

        it "should shift the date" do
          expect(subject.due_at).to eq(expected_date)
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.due_at = original_date
          item.errors.add(:due_at, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.due_at).to eq(original_date)
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:due_at)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on quiz #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end

      context "when field is missing" do
        it "should shift the date" do
          expect(subject.due_at).to be_nil
        end
      end
    end

    context "when setting lock_at field" do
      context "when field is given" do
        before do
          item.update!(lock_at: original_date)
        end

        it "should shift the date" do
          expect(subject.lock_at).to eq(expected_date)
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.lock_at = original_date
          item.errors.add(:lock_at, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.lock_at).to eq(original_date)
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:lock_at)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on quiz #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end

      context "when field is missing" do
        it "should shift the date" do
          expect(subject.lock_at).to be_nil
        end
      end
    end

    context "when setting unlock_at field" do
      context "when field is given" do
        before do
          item.update!(unlock_at: original_date)
        end

        it "should shift the date" do
          expect(subject.unlock_at).to eq(expected_date)
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.unlock_at = original_date
          item.errors.add(:unlock_at, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.unlock_at).to eq(original_date)
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:unlock_at)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on quiz #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end

      context "when field is missing" do
        it "should shift the date" do
          expect(subject.unlock_at).to be_nil
        end
      end
    end

    context "when setting show_correct_answers_at field" do
      context "when field is given" do
        before do
          item.update!(show_correct_answers_at: original_date)
        end

        it "should shift the date" do
          expect(subject.show_correct_answers_at).to eq(expected_date)
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.show_correct_answers_at = original_date
          item.errors.add(:show_correct_answers_at, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.show_correct_answers_at).to eq(original_date)
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:show_correct_answers_at)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on quiz #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end

      context "when field is missing" do
        it "should shift the date" do
          expect(subject.show_correct_answers_at).to be_nil
        end
      end
    end

    context "when setting hide_correct_answers_at field" do
      context "when field is given" do
        before do
          item.update!(hide_correct_answers_at: original_date)
        end

        it "should shift the date" do
          expect(subject.hide_correct_answers_at).to eq(expected_date)
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.hide_correct_answers_at = original_date
          item.errors.add(:hide_correct_answers_at, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.hide_correct_answers_at).to eq(original_date)
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:hide_correct_answers_at)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on quiz #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end

      context "when field is missing" do
        it "should shift the date" do
          expect(subject.hide_correct_answers_at).to be_nil
        end
      end
    end
  end
end
