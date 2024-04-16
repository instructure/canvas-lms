# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "course_copy_helper"

describe ContentMigration do
  context "course copy quizzes" do
    include_context "course copy"

    before do
      skip unless Qti.qti_enabled?
    end

    it "copies a quiz when assignment is selected" do
      @quiz = @copy_from.quizzes.create!
      @quiz.did_edit
      @quiz.offer!
      expect(@quiz.assignment).not_to be_nil

      @cm.copy_options = {
        assignments: { mig_id(@quiz.assignment) => "1" },
        quizzes: { mig_id(@quiz) => "0" },
      }
      @cm.save!

      run_course_copy

      expect(@copy_to.quizzes.where(migration_id: mig_id(@quiz)).first).not_to be_nil
    end

    it "creates a new assignment and module item if copying a new quiz (even if the assignment migration_id matches)" do
      quiz = @copy_from.quizzes.create!(title: "new quiz")
      quiz2 = @copy_to.quizzes.create!(title: "already existing quiz")

      mod = @copy_from.context_modules.create!(name: "some module")
      mod.add_item({ id: quiz.id, type: "quiz" })

      [quiz, quiz2].each do |q|
        q.did_edit
        q.offer!
      end

      a = quiz2.assignment
      a.migration_id = mig_id(quiz.assignment)
      a.save!

      run_course_copy

      expect(@copy_to.quizzes.map(&:title).sort).to eq ["already existing quiz", "new quiz"]
      expect(@copy_to.assignments.map(&:title).sort).to eq ["already existing quiz", "new quiz"]
      expect(@copy_to.context_module_tags.map(&:title)).to eq ["new quiz"]
    end

    it "does not duplicate quizzes and associated items if overwrite_quizzes is true" do
      # overwrite_quizzes should now default to true for course copy and canvas import

      quiz = @copy_from.quizzes.create!(title: "published quiz")
      quiz2 = @copy_from.quizzes.create!(title: "unpublished quiz")
      quiz.did_edit
      quiz.offer!
      quiz2.unpublish!

      mod = @copy_from.context_modules.create!(name: "some module")
      mod.add_item({ id: quiz.id, type: "quiz" })
      mod.add_item({ id: quiz2.id, type: "quiz" })

      run_course_copy

      expect(@copy_to.quizzes.map(&:title).sort).to eq ["published quiz", "unpublished quiz"]
      expect(@copy_to.assignments.map(&:title).sort).to eq ["published quiz", "unpublished quiz"]
      expect(@copy_to.context_module_tags.map(&:title).sort).to eq ["published quiz", "unpublished quiz"]

      expect(@copy_to.quizzes.where(title: "published quiz").first).not_to be_unpublished
      expect(@copy_to.quizzes.where(title: "unpublished quiz").first).to be_unpublished

      quiz.title = "edited published quiz"
      quiz.save!
      quiz2.title = "edited unpublished quiz"
      quiz2.save!

      # run again
      @cm = ContentMigration.new(
        context: @copy_to,
        user: @user,
        source_course: @copy_from,
        migration_type: "course_copy_importer",
        copy_options: { everything: "1" }
      )
      @cm.user = @user
      @cm.migration_settings[:import_immediately] = true
      @cm.save!

      run_course_copy

      expect(@copy_to.quizzes.map(&:title).sort).to eq ["edited published quiz", "edited unpublished quiz"]
      expect(@copy_to.assignments.map(&:title).sort).to eq ["edited published quiz", "edited unpublished quiz"]
      expect(@copy_to.context_module_tags.map(&:title).sort).to eq ["edited published quiz", "edited unpublished quiz"]

      expect(@copy_to.context_module_tags.map(&:workflow_state).sort).to eq ["active", "unpublished"]

      expect(@copy_to.quizzes.where(title: "edited published quiz").first).not_to be_unpublished
      expect(@copy_to.quizzes.where(title: "edited unpublished quiz").first).to be_unpublished
    end

    it "duplicates quizzes and associated items if overwrite_quizzes is false" do
      quiz = @copy_from.quizzes.create!(title: "published quiz")
      quiz2 = @copy_from.quizzes.create!(title: "unpublished quiz")
      quiz.did_edit
      quiz2.did_edit
      quiz.offer!

      mod = @copy_from.context_modules.create!(name: "some module")
      mod.add_item({ id: quiz.id, type: "quiz" })
      mod.add_item({ id: quiz2.id, type: "quiz" })

      run_course_copy

      # run again
      @cm = ContentMigration.new(
        context: @copy_to,
        user: @user,
        source_course: @copy_from,
        migration_type: "course_copy_importer",
        copy_options: { everything: "1" }
      )
      @cm.user = @user
      @cm.migration_settings[:import_immediately] = true
      @cm.migration_settings[:overwrite_quizzes] = false
      @cm.save!

      run_course_copy

      expect(@copy_to.quizzes.map(&:title).sort).to eq ["published quiz", "published quiz", "unpublished quiz", "unpublished quiz"]
      expect(@copy_to.assignments.map(&:title).sort).to eq ["published quiz", "published quiz", "unpublished quiz", "unpublished quiz"]
      expect(@copy_to.context_module_tags.map(&:title).sort).to eq ["published quiz", "published quiz", "unpublished quiz", "unpublished quiz"]
    end

    it "has correct question count on copied surveys and practive quizzes" do
      sp = @copy_from.quizzes.create!(title: "survey pub", quiz_type: "survey")
      data = {
        question_type: "multiple_choice_question",
        question_name: "test fun",
        name: "test fun",
        points_possible: 10,
        question_text: "<strong>html for fun</strong>",
        answers: [{ migration_id: "QUE_1016_A1", text: "<br />", weight: 100, id: 8080 },
                  { migration_id: "QUE_1017_A2", text: "<pre>", weight: 0, id: 2279 }]
      }.with_indifferent_access
      sp.quiz_questions.create!(question_data: data)
      sp.generate_quiz_data
      sp.published_at = Time.now
      sp.workflow_state = "available"
      sp.save!

      expect(sp.question_count).to eq 1

      run_course_copy

      q = @copy_to.quizzes.where(migration_id: mig_id(sp)).first
      expect(q).not_to be_nil
      expect(q.question_count).to eq 1
    end

    it "does not mix up quiz questions and assessment questions with the same ids" do
      quiz1 = @copy_from.quizzes.create!(title: "quiz 1")
      quiz2 = @copy_from.quizzes.create!(title: "quiz 1")

      qq1 = quiz1.quiz_questions.create!(question_data: { "question_name" => "test question 1", "answers" => [{ "id" => 1 }, { "id" => 2 }] })
      qq2 = quiz2.quiz_questions.create!(question_data: { "question_name" => "test question 2", "answers" => [{ "id" => 1 }, { "id" => 2 }] })
      Quizzes::QuizQuestion.where(id: qq1).update_all(assessment_question_id: qq2.id)

      run_course_copy

      newquiz2 = @copy_to.quizzes.where(migration_id: mig_id(quiz2)).first
      expect(newquiz2.quiz_questions.first.question_data["question_name"]).to eq "test question 2"
    end

    it "generates numeric ids for answers" do
      q = @copy_from.quizzes.create!(title: "test quiz")
      q.quiz_questions.create!(question_data: {
        points_possible: 1,
        question_type: "multiple_choice_question",
        question_name: "mc",
        name: "mc",
        question_text: "what is your favorite color?",
        answers: [{ text: "blue", weight: 0, id: 123 },
                  { text: "yellow", weight: 100, id: 456 }]
      }.with_indifferent_access)
      q.quiz_questions.create!(question_data: {
        points_possible: 1,
        question_type: "true_false_question",
        question_name: "tf",
        name: "tf",
        question_text: "this statement is false.",
        answers: [{ text: "True", weight: 100, id: 9608 },
                  { text: "False", weight: 0, id: 9093 }]
      }.with_indifferent_access)
      q.generate_quiz_data
      q.workflow_state = "available"
      q.save!

      run_course_copy

      q2 = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      expect(q2.quiz_data.size).to be(2)
      ans_count = 0
      q2.quiz_data.each do |qd|
        qd["answers"].each do |ans|
          expect(ans["id"]).to be_a(Integer)
          ans_count += 1
        end
      end
      expect(ans_count).to be(4)
    end

    it "makes true-false question answers consistent" do
      q = @copy_from.quizzes.create!(title: "test quiz")
      q.quiz_questions.create!(question_data: {
        points_possible: 1,
        question_type: "true_false_question",
        question_name: "tf",
        name: "tf",
        question_text: "this statement is false.",
        answers: [{ text: "false", weight: 0, id: 9093 },
                  { text: "true", weight: 100, id: 9608 }]
      }.with_indifferent_access)
      q.generate_quiz_data
      q.workflow_state = "available"
      q.save!

      run_course_copy

      q2 = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      expect(q2.quiz_data.first["answers"].pluck("text")).to eq ["True", "False"]
      expect(q2.quiz_data.first["answers"].pluck("weight")).to eq [100, 0]
    end

    it "imports invalid true-false questions as multiple choice" do
      q = @copy_from.quizzes.create!(title: "test quiz")
      q.quiz_questions.create!(question_data: {
        points_possible: 1,
        question_type: "true_false_question",
        question_name: "tf",
        name: "tf",
        question_text: "this statement is false.",
        answers: [{ text: "foo", weight: 0, id: 9093 },
                  { text: "tr00", weight: 100, id: 9608 }]
      }.with_indifferent_access)
      q.generate_quiz_data
      q.workflow_state = "available"
      q.save!

      run_course_copy

      q2 = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      expect(q2.quiz_data.first["question_type"]).to eq "multiple_choice_question"
      expect(q2.quiz_data.first["answers"].pluck("text")).to eq ["foo", "tr00"]
    end

    it "escapes html characters in text answers" do
      q = @copy_from.quizzes.create!(title: "test quiz")
      q.quiz_questions.create!(question_data: {
        points_possible: 1,
        question_type: "fill_in_multiple_blanks_question",
        question_name: "tf",
        name: "tf",
        question_text: "this statement is false. [orisit]",
        answers: [{ text: "<p>foo</p>", weight: 100, id: 9093, blank_id: "orisit" },
                  { text: "<div/>tr00", weight: 100, id: 9608, blank_id: "orisit" }]
      }.with_indifferent_access)
      q.generate_quiz_data
      q.workflow_state = "available"
      q.save!

      run_course_copy

      q2 = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      expect(q2.quiz_data.first["answers"].pluck("text")).to eq ["<p>foo</p>", "<div/>tr00"]
    end

    it "copies quizzes as published if they were published before" do
      g = @copy_from.assignment_groups.create!(name: "new group")
      asmnt_unpub = @copy_from.quizzes.create!(title: "asmnt unpub", quiz_type: "assignment", assignment_group_id: g.id)
      asmnt_pub = @copy_from.quizzes.create(title: "asmnt", quiz_type: "assignment", assignment_group_id: g.id)
      asmnt_pub.publish!
      graded_survey_unpub = @copy_from.quizzes.create!(title: "graded survey unpub", quiz_type: "graded_survey", assignment_group_id: g.id)
      graded_survey_pub = @copy_from.quizzes.create(title: "grade survey pub", quiz_type: "graded_survey", assignment_group_id: g.id)
      graded_survey_pub.publish!
      survey_unpub = @copy_from.quizzes.create!(title: "survey unpub", quiz_type: "survey")
      survey_pub = @copy_from.quizzes.create(title: "survey pub", quiz_type: "survey")
      survey_pub.publish!
      practice_unpub = @copy_from.quizzes.create!(title: "practice unpub", quiz_type: "practice_quiz")
      practice_pub = @copy_from.quizzes.create(title: "practice pub", quiz_type: "practice_quiz")
      practice_pub.publish!

      run_course_copy

      [asmnt_unpub, asmnt_pub, graded_survey_unpub, graded_survey_pub, survey_pub, survey_unpub, practice_unpub, practice_pub].each do |orig|
        q = @copy_to.quizzes.where(migration_id: mig_id(orig)).first
        expect("#{q.title} - #{q.published?}").to eq "#{orig.title} - #{orig.published?}" # titles in there to help identify what type failed
        expect(q.quiz_type).to eq orig.quiz_type
      end
    end

    it "exports quizzes with groups that point to external banks" do
      course_with_teacher(user: @user)
      different_course = @course
      different_account = Account.create!

      q1 = @copy_from.quizzes.create!(title: "quiz1")
      bank = different_course.assessment_question_banks.create!(title: "bank")
      bank2 = @copy_from.account.assessment_question_banks.create!(title: "bank2")
      bank3 = different_account.assessment_question_banks.create!(title: "bank3")
      group = q1.quiz_groups.create!(name: "group", pick_count: 3, question_points: 5.0)
      group.assessment_question_bank = bank
      group.save
      group2 = q1.quiz_groups.create!(name: "group2", pick_count: 5, question_points: 2.0)
      group2.assessment_question_bank = bank2
      group2.save
      group3 = q1.quiz_groups.create!(name: "group3", pick_count: 5, question_points: 2.0)
      group3.assessment_question_bank = bank3
      group3.save

      run_course_copy(["User didn't have permission to reference question bank in quiz group #{group3.name}"])

      q = @copy_to.quizzes.where(migration_id: mig_id(q1)).first
      expect(q).not_to be_nil
      expect(q.quiz_groups.count).to eq 3
      g = q.quiz_groups[0]
      expect(g.assessment_question_bank_id).to eq bank.id
      g = q.quiz_groups[1]
      expect(g.assessment_question_bank_id).to eq bank2.id
      g = q.quiz_groups[2]
      expect(g.assessment_question_bank_id).to be_nil
    end

    it "omits deleted questions in banks" do
      bank1 = @copy_from.assessment_question_banks.create!(title: "bank")
      bank1.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      q2 = bank1.assessment_questions.create!(question_data: { "question_name" => "test question 2", "question_type" => "essay_question" })
      bank1.assessment_questions.create!(question_data: { "question_name" => "test question 3", "question_type" => "essay_question" })
      q2.destroy

      run_course_copy

      bank2 = @copy_to.assessment_question_banks.first
      expect(bank2).to be_present
      # we don't copy over deleted questions at all, not even marked as deleted
      expect(bank2.assessment_questions.active.size).to eq 2
      expect(bank2.assessment_questions.size).to eq 2
    end

    it "does not restore deleted questions when restoring a bank" do
      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      bank.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      q2 = bank.assessment_questions.create!(question_data: { "question_name" => "test question 2", "question_type" => "essay_question" })

      run_course_copy

      bank_to = @copy_to.assessment_question_banks.where(migration_id: mig_id(bank)).first
      bank_to.destroy
      q2.destroy

      run_course_copy

      expect(bank_to.reload).to be_active
      expect(bank_to.assessment_questions.active.count).to eq 1
    end

    it "avoids duplicates due to alphanumeric ids" do
      bank1 = @copy_from.assessment_question_banks.create!(title: "bank")
      bank1.assessment_questions.create!(question_data: {
                                           "question_type" => "multiple_choice_question",
                                           "name" => "test question",
                                           "answers" => [
                                             { "id" => "1aB", "text" => "Correct", "weight" => 100 },
                                             { "id" => "1y3", "text" => "Incorrect", "weight" => 0 }
                                           ],
                                         })
      run_course_copy
      expect(@copy_to.assessment_questions.first.question_data[:answers].pluck(:id).uniq.count).to eq(2)
    end

    it "does not copy plain text question comments as html" do
      bank1 = @copy_from.assessment_question_banks.create!(title: "bank")
      bank1.assessment_questions.create!(question_data: {
                                           "question_type" => "multiple_choice_question",
                                           "name" => "test question",
                                           "answers" => [{ "id" => 1, "text" => "Correct", "weight" => 100, "comments" => "another comment" },
                                                         { "id" => 2, "text" => "inorrect", "weight" => 0 }],
                                           "correct_comments" => "Correct answer comment",
                                           "incorrect_comments" => "Incorrect answer comment",
                                           "neutral_comments" => "General Comment",
                                           "more_comments" => "even more comments"
                                         })

      run_course_copy

      q2 = @copy_to.assessment_questions.first
      %w[correct_comments_html incorrect_comments_html neutral_comments_html more_comments_html].each do |k|
        expect(q2.question_data.keys).not_to include(k)
      end
      q2.question_data["answers"].each do |a|
        expect(a.keys).not_to include("comments_html")
      end
    end

    it "does not copy deleted assignment attached to quizzes" do
      g = @copy_from.assignment_groups.create!(name: "new group")
      quiz = @copy_from.quizzes.create(title: "asmnt", quiz_type: "assignment", assignment_group_id: g.id)
      quiz.workflow_state = "available"
      quiz.save!

      asmnt = quiz.assignment

      quiz.quiz_type = "practice_quiz"
      quiz.save!

      asmnt.reload
      asmnt.workflow_state = "deleted"
      asmnt.save!

      run_course_copy

      expect(@copy_to.quizzes.where(migration_id: mig_id(quiz)).first).not_to be_nil
      expect(@copy_to.assignments.where(migration_id: mig_id(asmnt)).first).to be_nil
    end

    it "copies all quiz attributes" do
      attributes = {
        title: "quiz",
        description: "<p>description eh</p>",
        shuffle_answers: true,
        show_correct_answers: true,
        time_limit: 20,
        disable_timer_autosubmission: true,
        allowed_attempts: 4,
        scoring_policy: "keep_highest",
        quiz_type: "survey",
        access_code: "code",
        anonymous_submissions: true,
        hide_results: "until_after_last_attempt",
        ip_filter: "192.168.1.1",
        require_lockdown_browser: true,
        require_lockdown_browser_for_results: true,
        one_question_at_a_time: true,
        cant_go_back: true,
        require_lockdown_browser_monitor: true,
        lockdown_browser_monitor_data: "VGVzdCBEYXRhCg==",
        one_time_results: true,
        show_correct_answers_last_attempt: true,
      }
      q = @copy_from.quizzes.create!(attributes)

      run_course_copy

      new_quiz = @copy_to.quizzes.first

      attributes.each_key do |prop|
        expect(new_quiz.send(prop)).to eq(q.send(prop)), "#{prop}: expected #{q.send(prop).inspect}, got #{new_quiz.send(prop).inspect}"
      end
    end

    it "copies nil values for hide_results" do
      q = @copy_from.quizzes.create!(hide_results: "always")
      run_course_copy
      q_to = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      expect(q_to.hide_results).to eq "always"

      q.update_attribute(:hide_results, nil)
      run_course_copy
      expect(q_to.reload.hide_results).to be_nil
    end

    it "leaves file references in AQ context as-is on copy" do
      @bank = @copy_from.assessment_question_banks.create!(title: "Test Bank")
      @attachment = attachment_with_context(@copy_from)
      @attachment2 = @attachment = Attachment.create!(filename: "test.jpg", display_name: "test.jpg", uploaded_data: StringIO.new("psych!"), folder: Folder.unfiled_folder(@copy_from), context: @copy_from)
      data = { "question_type" => "text_only_question", "name" => "Hi", "question_text" => <<~HTML.strip }
        File ref:<img src="/courses/#{@copy_from.id}/files/#{@attachment.id}/download">
        different file ref: <img src="/courses/#{@copy_from.id}/file_contents/course%20files/unfiled/test.jpg">
        equation: <img class="equation_image" title="Log_216" src="/equation_images/Log_216" alt="Log_216">
        link to some other course: <a href="/courses/#{@copy_from.id + @copy_to.id}">Cool Course</a>
        canvas image: <img style="max-width: 723px;" src="/images/preview.png" alt="">
      HTML
      @question = @bank.assessment_questions.create!(question_data: data)
      expect(@question.reload.question_data["question_text"]).to match %r{/assessment_questions/}

      run_course_copy

      bank = @copy_to.assessment_question_banks.first
      expect(bank.assessment_questions.count).to eq 1
      aq = bank.assessment_questions.first

      expect(aq.question_data["question_text"]).to match_ignoring_whitespace(@question.question_data["question_text"])
    end

    it "changes old media file references in AQ context on copy" do
      @bank = @copy_from.assessment_question_banks.create!(title: "Test Bank")
      @attachment = attachment_with_context(@copy_from, media_entry_id: "0_l4l5n0wt")
      data = { "question_type" => "text_only_question", "name" => "Hi", "question_text" => <<~HTML.strip }
        media comment: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
        media object: <iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_objects_iframe/0_l4l5n0wt?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe>
      HTML
      @question = @bank.assessment_questions.create!(question_data: data)

      run_course_copy

      bank = @copy_to.assessment_question_banks.first
      expect(bank.assessment_questions.count).to eq 1
      aq = bank.assessment_questions.first
      # TODO: fix media attachments not being copied to assessment question context like other attachments
      new_att = @copy_to.attachments.take
      translated_body = <<~HTML.strip
        media comment: <iframe id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" style="width: 320px; height: 240px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{new_att.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe>
        media object: <iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt" src="/media_attachments_iframe/#{new_att.id}?embedded=true&amp;type=video"></iframe>
      HTML

      expect(aq.question_data["question_text"]).to match_ignoring_whitespace(translated_body)
    end

    it "copies quiz question html file references correctly" do
      root = Folder.root_folders(@copy_from).first
      folder = root.sub_folders.create!(context: @copy_from, name: "folder 1")
      att = Attachment.create!(filename: "first.jpg", display_name: "first.jpg", uploaded_data: StringIO.new("first"), folder: root, context: @copy_from)
      att2 = Attachment.create!(filename: "test.jpg", display_name: "test.jpg", uploaded_data: StringIO.new("second"), folder: root, context: @copy_from)
      att3 = Attachment.create!(filename: "testing.jpg", display_name: "testing.jpg", uploaded_data: StringIO.new("test this"), folder: root, context: @copy_from)
      att4 = Attachment.create!(filename: "sub_test.jpg", display_name: "sub_test.jpg", uploaded_data: StringIO.new("sub_folder"), folder:, context: @copy_from)
      qtext = <<~HTML.strip
        sad file ref: <img src="%s">
        File ref:<img src="/courses/%s/files/%s/download">
        different file ref: <img src="/courses/%s/%s">
        subfolder file ref: <img src="/courses/%s/%s">
        equation: <img class="equation_image" title="Log_216" src="/equation_images/Log_216" alt="Log_216">
      HTML

      data = { correct_comments_html: "<strong>correct</strong>",
               question_type: "multiple_choice_question",
               question_name: "test fun",
               name: "test fun",
               points_possible: 10,
               question_text: qtext % ["/files/#{att.id}", @copy_from.id, att.id, @copy_from.id, "file_contents/course%20files/test.jpg", @copy_from.id, "file_contents/course%20files/folder%201/sub_test.jpg"],
               answers: [{ migration_id: "QUE_1016_A1", html: %(File ref:<img src="/courses/#{@copy_from.id}/files/#{att3.id}/download">), comments_html: "<i>comment</i>", text: "", weight: 100, id: 8080 },
                         { migration_id: "QUE_1017_A2", html: "<strong>html answer 2</strong>", comments_html: "<i>comment</i>", text: "", weight: 0, id: 2279 }] }.with_indifferent_access

      q1 = @copy_from.quizzes.create!(title: "quiz1")
      q1.quiz_questions.create!(question_data: data)

      run_course_copy

      expect(@copy_to.attachments.count).to eq 4
      att_2 = @copy_to.attachments.where(migration_id: mig_id(att)).first
      att2_2 = @copy_to.attachments.where(migration_id: mig_id(att2)).first
      att3_2 = @copy_to.attachments.where(migration_id: mig_id(att3)).first
      att4_2 = @copy_to.attachments.where(migration_id: mig_id(att4)).first

      q_to = @copy_to.quizzes.first
      qq_to = q_to.active_quiz_questions.first
      expect(qq_to.question_data[:question_text]).to match_ignoring_whitespace(qtext % ["/courses/#{@copy_to.id}/files/#{att_2.id}/preview", @copy_to.id, att_2.id, @copy_to.id, "files/#{att2_2.id}/preview", @copy_to.id, "files/#{att4_2.id}/preview"])
      expect(qq_to.question_data[:answers][0][:html]).to match_ignoring_whitespace(%(File ref:<img src="/courses/#{@copy_to.id}/files/#{att3_2.id}/download">))
    end

    it "updates quiz question media file references to new style" do
      root = Folder.root_folders(@copy_from).first
      root.sub_folders.create!(context: @copy_from, name: "folder 1")
      attachment_with_context(@copy_from, media_entry_id: "0_l4l5n0wt")
      data = { "question_type" => "text_only_question", "name" => "Hi", "question_text" => <<~HTML.strip }
        media comment: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
        media object: <iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_objects_iframe/0_l4l5n0wt?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe>
      HTML
      q1 = @copy_from.quizzes.create!(title: "quiz1")
      q1.quiz_questions.create!(question_data: data)

      run_course_copy

      quiz = @copy_to.quizzes.first
      expect(quiz.quiz_questions.count).to eq 1
      question = quiz.quiz_questions.first
      new_att = @copy_to.attachments.take
      translated_body = <<~HTML.strip
        media comment: <iframe id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" style="width: 320px; height: 240px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{new_att.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe>
        media object: <iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt" src="/media_attachments_iframe/#{new_att.id}?embedded=true&amp;type=video"></iframe>
      HTML

      expect(question.question_data["question_text"]).to match_ignoring_whitespace(translated_body)
    end

    it "copies quiz question mathml equation image references correctly" do
      qtext = <<~HTML.strip
        equation: <p>
          <img class="equation_image" title="\\sum" src="/equation_images/%255Csum"
            alt="LaTeX: \\sum" data-equation-content="\\sum" x-canvaslms-safe-mathml="&lt;math xmlns=&quot;http://www.w3.org/1998/Math/MathML&quot;&gt;
              &lt;mo&gt;&amp;#x2211;&lt;!-- &sum; --&gt;&lt;/mo&gt;&lt;/math&gt;" />
        </p>
      HTML
      data = { "question_name" => "test question 1", "question_type" => "essay_question", "question_text" => qtext }

      q1 = @copy_from.quizzes.create!(title: "quiz1")
      qq = q1.quiz_questions.create!(question_data: data)

      run_course_copy

      q_to = @copy_to.quizzes.where(migration_id: mig_id(q1)).first
      qq_to = q_to.active_quiz_questions.first
      expect(qq_to.question_data[:question_text]).to match_ignoring_whitespace(qq.question_data[:question_text])
    end

    it "does more terrible equation stuff" do
      qtext = <<~HTML.strip
              hmm: <p><img class="equation_image"
        data-equation-content="h\\left( x \\right) = \\left\\{ {\\begin{array}{*{20}{c}}
        {{x^2} + 4x - 1}&amp;{{\\rm{for}}}&amp;{ - 7 \\le x \\le - 1}\\\\
        { - 3x + p}&amp;{{\\rm{for}}}&amp;{ - 1 &lt; x \\le 6}
        \\end{array}} \\right."></p>
      HTML

      data = { "question_name" => "test question 1", "question_type" => "essay_question", "question_text" => qtext }

      q1 = @copy_from.quizzes.create!(title: "quiz1")
      qq = q1.quiz_questions.create!(question_data: data)

      run_course_copy

      q_to = @copy_to.quizzes.where(migration_id: mig_id(q1)).first
      qq_to = q_to.active_quiz_questions.first

      expect(qq_to.question_data["question_text"]).to match_ignoring_whitespace(qq.question_data["question_text"])
    end

    it "copies all html fields in assessment questions" do
      @bank = @copy_from.assessment_question_banks.create!(title: "Test Bank")
      data = { correct_comments_html: "<strong>correct</strong>",
               question_type: "multiple_choice_question",
               incorrect_comments_html: "<strong>incorrect</strong>",
               neutral_comments_html: "<strong>meh</strong>",
               question_name: "test fun",
               name: "test fun",
               points_possible: 10,
               question_text: "<strong>html for fun</strong>",
               answers: [{ migration_id: "QUE_1016_A1", html: "<strong>html answer 1</strong>", comments_html: "<i>comment</i>", text: "", weight: 100, id: 8080 },
                         { migration_id: "QUE_1017_A2", html: "<span style=\"color: #808000;\">html answer 2</span>", comments_html: "<i>comment</i>", text: "", weight: 0, id: 2279 }] }.with_indifferent_access
      aq_from1 = @bank.assessment_questions.create!(question_data: data)
      data2 = data.clone
      data2[:question_text] = "<i>matching yo</i>"
      data2[:question_type] = "matching_question"
      data2[:matches] = [{ match_id: 4835, text: "a", html: "<i>a</i>" },
                         { match_id: 6247, text: "b", html: "<i>a</i>" }]
      data2[:answers][0][:match_id] = 4835
      data2[:answers][0][:left_html] = data2[:answers][0][:html]
      data2[:answers][0][:right] = "a"
      data2[:answers][1][:match_id] = 6247
      data2[:answers][1][:right] = "b"
      data2[:answers][1][:left_html] = data2[:answers][1][:html]
      aq_from2 = @bank.assessment_questions.create!(question_data: data2)

      run_course_copy

      aq = @copy_to.assessment_questions.where(migration_id: mig_id(aq_from1)).first

      expect(aq.question_data[:question_text]).to eq data[:question_text]
      expect(aq.question_data[:answers][0][:html]).to eq data[:answers][0][:html]
      expect(aq.question_data[:answers][0][:comments_html]).to eq data[:answers][0][:comments_html]
      expect(aq.question_data[:answers][1][:html]).to eq data[:answers][1][:html]
      expect(aq.question_data[:answers][1][:comments_html]).to eq data[:answers][1][:comments_html]
      expect(aq.question_data[:correct_comments_html]).to eq data[:correct_comments_html]
      expect(aq.question_data[:incorrect_comments_html]).to eq data[:incorrect_comments_html]
      expect(aq.question_data[:neutral_comments_html]).to eq data[:neutral_comments_html]

      # and the matching question
      aq = @copy_to.assessment_questions.where(migration_id: mig_id(aq_from2)).first
      expect(aq.question_data[:answers][0][:html]).to eq data2[:answers][0][:html]
      expect(aq.question_data[:answers][0][:left_html]).to eq data2[:answers][0][:left_html]
      expect(aq.question_data[:answers][1][:html]).to eq data2[:answers][1][:html]
      expect(aq.question_data[:answers][1][:left_html]).to eq data2[:answers][1][:left_html]
    end

    it "copies matching question fields with html-lookalike text correctly" do
      @bank = @copy_from.assessment_question_banks.create!(title: "Test Bank")
      data = { question_type: "matching_question",
               points_possible: 10,
               question_text: "text",
               matches: [{ match_id: 4835, text: "<i>aasdf</i>" },
                         { match_id: 6247, text: "<p>not good" }],
               answers: [{ id: 2939, text: "<p>srsly is all text</p> <img totes & bork", match_id: 4835 },
                         { id: 2940, html: "<img src=\"http://example.com\">good ol html", match_id: 6247 }] }.with_indifferent_access
      aq_from = @bank.assessment_questions.create!(question_data: data)

      quiz = @copy_from.quizzes.create!(title: "survey pub", quiz_type: "survey")
      qq_from = quiz.quiz_questions.new(assessment_question: aq_from)
      qq_from.write_attribute(:question_data, data)
      qq_from.save!
      quiz.generate_quiz_data
      quiz.save!

      run_course_copy

      aq = @copy_to.assessment_questions.where(migration_id: mig_id(aq_from)).first
      qq = @copy_to.quizzes.first.quiz_questions.first

      [aq, qq].each do |q|
        expect(q.question_data[:question_text]).to eq data[:question_text]
        expect(q.question_data[:matches][0][:text]).to eq data[:matches][0][:text]
        expect(q.question_data[:matches][1][:text]).to eq data[:matches][1][:text]
        expect(q.question_data[:answers][0][:text]).to eq data[:answers][0][:text]
        expect(q.question_data[:answers][1][:html]).to eq data[:answers][1][:html]
      end
    end

    it "copies file_upload_questions" do
      bank = @copy_from.assessment_question_banks.create!(title: "Test Bank")
      data = { question_type: "file_upload_question",
               points_possible: 10,
               question_text: "<strong>html for fun</strong>" }.with_indifferent_access
      bank.assessment_questions.create!(question_data: data)

      q = @copy_from.quizzes.create!(title: "survey pub", quiz_type: "survey")
      q.quiz_questions.create!(question_data: data)
      q.generate_quiz_data
      q.published_at = Time.now
      q.workflow_state = "available"
      q.save!

      run_course_copy

      expect(@copy_to.assessment_questions.count).to eq 2
      @copy_to.assessment_questions.each do |aq|
        expect(aq.question_data["question_type"]).to eq data[:question_type]
        expect(aq.question_data["question_text"]).to eq data[:question_text]
      end

      expect(@copy_to.quizzes.count).to eq 1
      quiz = @copy_to.quizzes.first
      expect(quiz.active_quiz_questions.size).to eq 1

      qq = quiz.active_quiz_questions.first
      expect(qq.question_data["question_type"]).to eq data[:question_type]
      expect(qq.question_data["question_text"]).to eq data[:question_text]
    end

    it "leaves text answers as text" do
      @bank = @copy_from.assessment_question_banks.create!(title: "Test Bank")
      data = {
        question_type: "multiple_choice_question",
        question_name: "test fun",
        name: "test fun",
        points_possible: 10,
        question_text: "<strong>html for fun</strong>",
        answers: [{ migration_id: "QUE_1016_A1", text: "<br />", weight: 100, id: 8080 },
                  { migration_id: "QUE_1017_A2", text: "<pre>", weight: 0, id: 2279 }]
      }.with_indifferent_access
      aq_from1 = @bank.assessment_questions.create!(question_data: data)

      run_course_copy

      aq = @copy_to.assessment_questions.where(migration_id: mig_id(aq_from1)).first

      expect(aq.question_data[:answers][0][:text]).to eq data[:answers][0][:text]
      expect(aq.question_data[:answers][1][:text]).to eq data[:answers][1][:text]
      expect(aq.question_data[:answers][0][:html]).to be_nil
      expect(aq.question_data[:answers][1][:html]).to be_nil
      expect(aq.question_data[:question_text]).to eq data[:question_text]
    end

    it "retains imported quiz questions in their original assessment question banks" do
      data = { "question_name" => "test question 1", "question_type" => "essay_question", "question_text" => "blah" }

      aqb = @copy_from.assessment_question_banks.create!(title: "oh noes")
      aq = aqb.assessment_questions.create!(question_data: data)

      data["points_possible"] = 2
      quiz = @copy_from.quizzes.create!(title: "ruhroh")
      qq = quiz.quiz_questions.create!(question_data: data, assessment_question: aq)

      run_course_copy

      aqb2 = @copy_to.assessment_question_banks.where(migration_id: mig_id(aqb)).first
      expect(aqb2.assessment_questions.count).to eq 1

      quiz2 = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      expect(quiz2.quiz_questions.count).to eq 1
      qq2 = quiz2.quiz_questions.first
      expect(qq2.assessment_question_id).to eq aqb2.assessment_questions.first.id
      expect(qq2.question_data["points_possible"]).to eq qq.question_data["points_possible"]
    end

    it "copies the assignment group in full copy" do
      group = @copy_from.assignment_groups.create!(name: "new group")
      quiz = @copy_from.quizzes.create(title: "asmnt", quiz_type: "assignment", assignment_group_id: group.id)
      quiz.publish!
      run_course_copy
      dest_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      expect(dest_quiz.assignment_group.migration_id).to eql mig_id(group)
    end

    it "does not copy the assignment group in selective copy" do
      group = @copy_from.assignment_groups.create!(name: "new group")
      quiz = @copy_from.quizzes.create(title: "asmnt", quiz_type: "assignment", assignment_group_id: group.id)
      quiz.publish!
      @cm.copy_options = { "everything" => "0", "quizzes" => { mig_id(quiz) => "1" } }
      run_course_copy
      dest_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      expect(dest_quiz.assignment_group.migration_id).to be_nil
    end

    it "does not copy the assignment group in selective export" do
      group = @copy_from.assignment_groups.create!(name: "new group")
      quiz = @copy_from.quizzes.create(title: "asmnt", quiz_type: "assignment", assignment_group_id: group.id)
      quiz.publish!
      # test that we neither export nor reference the assignment group
      decoy_assignment_group = @copy_to.assignment_groups.create!(name: "decoy")
      decoy_assignment_group.update_attribute(:migration_id, mig_id(group))
      run_export_and_import do |export|
        export.selected_content = { "quizzes" => { mig_id(quiz) => "1" } }
      end
      dest_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      expect(dest_quiz.assignment_group.migration_id).not_to eql decoy_assignment_group
      expect(decoy_assignment_group.reload.name).not_to eql group.name
    end

    it "rounds numeric answer margins sanely" do
      q = @copy_from.quizzes.create!(title: "blah")
      # this one targets rounding errors in gems/plugins/qti_exporter/lib/qti/numeric_interaction.rb (import side)
      data1 = { question_type: "numerical_question",
                question_text: "what is the optimal matter/antimatter intermix ratio",
                answers: [{
                  text: "answer_text",
                  weight: 100,
                  numerical_answer_type: "exact_answer",
                  answer_exact: 1,
                  answer_error_margin: 0.0001
                }] }.with_indifferent_access
      # this one targets rounding errors in lib/cc/qti/qti_items.rb (export side)
      data2 = { question_type: "numerical_question",
                question_text: "what is the airspeed velocity of an unladed African swallow",
                answers: [{
                  text: "answer_text",
                  weight: 100,
                  numerical_answer_type: "exact_answer",
                  answer_exact: 2.0009,
                  answer_error_margin: 0.0001
                }] }.with_indifferent_access

      q.quiz_questions.create!(question_data: data1)
      q.quiz_questions.create!(question_data: data2)
      run_course_copy

      q2 = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      expect(q2.quiz_questions[0].question_data["answers"][0]["margin"].to_s).to eq "0.0001"
      expect(q2.quiz_questions[1].question_data["answers"][0]["margin"].to_s).to eq "0.0001"
    end

    it "copies precision answers for numeric questions" do
      q = @copy_from.quizzes.create!(title: "blah")
      data = { question_type: "numerical_question",
               question_text: "how many people think about course copy when they add things?",
               answers: [{
                 text: "answer_text",
                 weight: 100,
                 numerical_answer_type: "precision_answer",
                 answer_approximate: 0.0042,
                 answer_precision: 3
               }] }.with_indifferent_access
      q.quiz_questions.create!(question_data: data)

      run_course_copy

      q2 = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      answer = q2.quiz_questions[0].question_data["answers"][0]
      expect(answer["numerical_answer_type"]).to eq "precision_answer"
      expect(answer["approximate"]).to eq 0.0042
      expect(answer["precision"]).to eq 3
    end

    it "copies large precision answers for numeric questions" do
      q = @copy_from.quizzes.create!(title: "blah")
      data = { question_type: "numerical_question",
               question_text: "how many problems does QTI cause?",
               answers: [{
                 text: "answer_text",
                 weight: 100,
                 numerical_answer_type: "precision_answer",
                 answer_approximate: 99_000_000,
                 answer_precision: 2
               }] }.with_indifferent_access
      q.quiz_questions.create!(question_data: data)

      run_course_copy

      q2 = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      answer = q2.quiz_questions[0].question_data["answers"][0]
      expect(answer["numerical_answer_type"]).to eq "precision_answer"
      expect(answer["approximate"]).to eq 99_000_000
      expect(answer["precision"]).to eq 2
    end

    it "copies range answers for numeric questions" do
      q = @copy_from.quizzes.create!(title: "blah")
      data = { question_type: "numerical_question",
               question_text: "how many people think about course copy when they add things?",
               answers: [{
                 text: "answer_text",
                 weight: 100,
                 numerical_answer_type: "range_answer",
                 answer_range_start: -1,
                 answer_range_end: 2
               }] }.with_indifferent_access
      q.quiz_questions.create!(question_data: data)

      run_course_copy

      q2 = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      answer = q2.quiz_questions[0].question_data["answers"][0]
      expect(answer["numerical_answer_type"]).to eq "range_answer"
      expect(answer["start"]).to eq(-1)
      expect(answer["end"]).to eq 2
    end

    it "does not combine when copying question banks with the same title" do
      data = { "question_name" => "test question 1", "question_type" => "essay_question", "question_text" => "blah" }

      bank1 = @copy_from.assessment_question_banks.create!(title: "oh noes i have the same title")
      bank2 = @copy_from.assessment_question_banks.create!(title: "oh noes i have the same title")

      bank1.assessment_questions.create!(question_data: data)
      bank2.assessment_questions.create!(question_data: data)

      quiz = @copy_from.quizzes.create!(title: "ruhroh")

      group1 = quiz.quiz_groups.create!(name: "group", pick_count: 2, question_points: 5.0)
      group1.assessment_question_bank = bank1
      group1.save
      group2 = quiz.quiz_groups.create!(name: "group2", pick_count: 1, question_points: 2.0)
      group2.assessment_question_bank = bank2
      group2.save

      run_course_copy

      bank1_copy = @copy_to.assessment_question_banks.where(migration_id: mig_id(bank1)).first
      bank2_copy = @copy_to.assessment_question_banks.where(migration_id: mig_id(bank2)).first

      expect(bank1_copy).to_not be_nil
      expect(bank2_copy).to_not be_nil

      quiz_copy = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      expect(quiz_copy.quiz_groups.count).to eq 2
      group1_copy = quiz_copy.quiz_groups.where(migration_id: mig_id(group1)).first
      group2_copy = quiz_copy.quiz_groups.where(migration_id: mig_id(group2)).first

      expect(group1_copy.assessment_question_bank_id).to eq bank1_copy.id
      expect(group1_copy.pick_count).to eq group1.pick_count
      expect(group1_copy.name).to eq group1.name
      expect(group2_copy.assessment_question_bank_id).to eq bank2_copy.id
    end

    def terrible_quiz(context)
      data1 = { question_type: "file_upload_question",
                points_possible: 10,
                question_text: "why is this question terrible" }.with_indifferent_access

      data2 = { question_type: "essay_question",
                points_possible: 10,
                question_text: "so terrible" }.with_indifferent_access

      data3 = {
        question_type: "multiple_choice_question",
        question_name: "test fun",
        name: "test fun",
        points_possible: 10,
        question_text: "<strong>html for fun</strong>",
        answers: [{ migration_id: "QUE_1016_A1", text: "<br />", weight: 100, id: 8080 },
                  { migration_id: "QUE_1017_A2", text: "<pre>", weight: 0, id: 2279 }]
      }.with_indifferent_access

      q = context.quizzes.create!(title: "survey pub", quiz_type: "survey")
      q.quiz_questions.create!(question_data: data1)
      q.quiz_questions.create!(question_data: data2)
      q.quiz_questions.create!(question_data: data3)
      q.generate_quiz_data
      q.save!
      q
    end

    it "copies stuff" do
      q = terrible_quiz(@copy_from)

      run_course_copy
      q_copy = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      expect(q_copy.quiz_questions.count).to eq 3
      q_copy.quiz_questions.each do |qq|
        # should link quiz questions
        expect(qq.assessment_question_id).to_not be_nil
      end

      @cm.copy_options = { all_quizzes: true }
      run_course_copy

      # should not duplicate the questions
      q_copy.reload
      expect(q_copy.quiz_questions.count).to eq 3
      q_copy.quiz_questions.each do |qq|
        # should unlink them since the new quiz questions are possibly overwritten
        expect(qq.assessment_question_id).to be_nil
      end

      @cm.copy_options = { everything: true }
      run_course_copy

      q_copy.reload
      expect(q_copy.quiz_questions.count).to eq 3
      q_copy.quiz_questions.each do |qq|
        # should re-link them
        expect(qq.assessment_question_id).to_not be_nil
      end
    end

    it "does not try to restore deleted quizzes to an unpublished state if unable to" do
      quiz_from = @copy_from.quizzes.create!(title: "ruhroh")
      quiz_from.did_edit
      quiz_from.offer!
      a_from = quiz_from.assignment

      run_course_copy

      a_from.unpublish!
      quiz_from.unpublish!

      @copy_to.offer!
      student_in_course(course: @copy_to, active_user: true)

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz_from)).first
      Quizzes::QuizSubmission.create!(quiz: quiz_to, user: @student)
      expect(quiz_to.can_unpublish?).to be_falsey

      a_to = @copy_to.assignments.where(migration_id: mig_id(a_from)).first
      a_to.destroy
      quiz_to.destroy

      run_course_copy

      quiz_to.reload
      a_to.reload
      expect(quiz_to).to be_published
      expect(quiz_to.assignment).to eq a_to
      expect(a_to).to be_published
    end

    it "does not bring questions back when restoring a deleted quiz" do
      quiz_from = terrible_quiz(@copy_from)

      group1 = quiz_from.quiz_groups.create!(name: "group1", pick_count: 1, question_points: 1.0)
      group1.quiz_questions.create!(quiz: quiz_from, question_data: { "question_text" => "group question 1", "answers" => [{ "id" => 1 }, { "id" => 2 }] })
      group2 = quiz_from.quiz_groups.create!(name: "group2", pick_count: 1, question_points: 1.0)
      group2.quiz_questions.create!(quiz: quiz_from, question_data: { "question_text" => "group question 2", "answers" => [{ "id" => 1 }, { "id" => 2 }] })

      run_course_copy

      quiz_from.quiz_questions.detect { |qq| qq["question_data"]["question_text"].include? "html" }.destroy

      group2.destroy

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz_from)).first
      quiz_to.destroy

      run_course_copy

      quiz_to.reload
      expect(quiz_to).to be_unpublished
      expect(quiz_to.quiz_questions.active.map { |qq| qq["question_data"]["question_text"] })
        .to match_array(["why is this question terrible", "so terrible", "group question 1"])
      expect(quiz_to.quiz_groups.count).to eq 1
      expect(quiz_to.quiz_groups.first.name).to eq "group1"
    end

    it "copies links to quizzes inside assessment questions correctly" do
      link_quiz = @copy_from.quizzes.create!(title: "linked quiz")

      html = "<a href=\"/courses/%s/quizzes/%s\">linky</a>"

      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      data = { "question_name" => "test question",
               "question_type" => "essay_question",
               "question_text" => (html % [@copy_from.id, link_quiz.id]) }
      aq = bank.assessment_questions.create!(question_data: data)

      other_quiz = @copy_from.quizzes.create!(title: "other quiz")
      other_quiz.quiz_questions.create!(question_data: data)
      other_quiz.generate_quiz_data
      other_quiz.published_at = Time.now
      other_quiz.workflow_state = "available"
      other_quiz.save!

      run_course_copy

      link_quiz2 = @copy_to.quizzes.where(migration_id: mig_id(link_quiz)).first
      expected_html = (html % [@copy_to.id, link_quiz2.id])

      other_quiz2 = @copy_to.quizzes.where(migration_id: mig_id(other_quiz)).first
      aq2 = @copy_to.assessment_questions.where(migration_id: mig_id(aq)).first
      qq2 = other_quiz2.quiz_questions.first

      expect(aq2.question_data["question_text"]).to eq expected_html
      expect(qq2.question_data["question_text"]).to eq expected_html
      expect(other_quiz2.quiz_data.first["question_text"]).to eq expected_html
    end

    it "copies links to quizzes inside standalone quiz questions correctly" do
      # i.e. quiz questions imported independently from their original assessment question
      link_quiz = @copy_from.quizzes.create!(title: "linked quiz")

      html = "<a href=\"/courses/%s/quizzes/%s\">linky</a>"

      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      data = { "question_name" => "test question",
               "question_type" => "essay_question",
               "question_text" => (html % [@copy_from.id, link_quiz.id]) }
      bank.assessment_questions.create!(question_data: data)

      other_quiz = @copy_from.quizzes.create!(title: "other quiz")
      other_quiz.quiz_questions.create!(question_data: data)
      other_quiz.generate_quiz_data
      other_quiz.published_at = Time.now
      other_quiz.workflow_state = "available"
      other_quiz.save!

      @cm.copy_options = {
        quizzes: { mig_id(link_quiz) => "1", mig_id(other_quiz) => "1" }
      }
      run_course_copy

      link_quiz2 = @copy_to.quizzes.where(migration_id: mig_id(link_quiz)).first
      expected_html = (html % [@copy_to.id, link_quiz2.id])

      other_quiz2 = @copy_to.quizzes.where(migration_id: mig_id(other_quiz)).first
      qq2 = other_quiz2.quiz_questions.first

      expect(qq2.question_data["question_text"]).to eq expected_html
      expect(other_quiz2.quiz_data.first["question_text"]).to eq expected_html
    end

    it "properly copies escaped brackets in html comments" do
      bank1 = @copy_from.assessment_question_banks.create!(title: "bank")
      text = "&lt;braaackets&gt;"
      bank1.assessment_questions.create!(question_data: {
                                           "question_type" => "multiple_choice_question",
                                           "name" => "test question",
                                           "answers" => [{ "id" => 1, "text" => "Correct", "weight" => 100, "comments_html" => text },
                                                         { "id" => 2, "text" => "inorrect", "weight" => 0 }],
                                           "correct_comments_html" => text
                                         })

      run_course_copy

      q2 = @copy_to.assessment_questions.first
      expect(q2.question_data["correct_comments_html"]).to eq text
      expect(q2.question_data["answers"].first["comments_html"]).to eq text
    end

    it "copies neutral feedback for file upload questions" do
      q = @copy_from.quizzes.create!(title: "q")
      data = { "question_type" => "file_upload_question", "name" => "test question", "neutral_comments_html" => "<i>comment</i>", "neutral_comments" => "comment" }
      q.quiz_questions.create!(question_data: data)

      run_course_copy

      q2 = @copy_to.quizzes.first
      qq2 = q2.quiz_questions.first
      expect(qq2.question_data["neutral_comments_html"]).to eq data["neutral_comments_html"]
      expect(qq2.question_data["neutral_comments"]).to eq data["neutral_comments"]
    end

    describe "assignment overrides" do
      before :once do
        @quiz_plain = @copy_from.quizzes.create!(title: "my quiz")
        @quiz_assigned = @copy_from.quizzes.create!(title: "assignment quiz")
        @quiz_assigned.did_edit
        @quiz_assigned.offer!
      end

      it "copies only noop overrides" do
        account = Account.default
        account.settings[:conditional_release] = { value: true }
        account.save!
        due_at = 1.hour.from_now.round
        assignment_override_model(quiz: @quiz_plain, set_type: "Noop", set_id: 1, title: "Tag 3")
        assignment_override_model(quiz: @quiz_assigned, set_type: "Noop", set_id: 1, title: "Tag 4", due_at:)
        run_course_copy
        to_quiz_plain = @copy_to.quizzes.where(migration_id: mig_id(@quiz_plain)).first
        to_quiz_assigned = @copy_to.quizzes.where(migration_id: mig_id(@quiz_assigned)).first
        expect(to_quiz_plain.assignment_overrides.pluck(:title)).to eq ["Tag 3"]
        expect(to_quiz_assigned.assignment_overrides.pluck(:title)).to eq ["Tag 4"]
        expect(to_quiz_assigned.assignment_overrides.first.due_at).to eq due_at
      end

      it "ignores conditional release noop overrides if feature is not enabled in destination" do
        assignment_override_model(quiz: @quiz_assigned, set_type: "Noop", set_id: 1, title: "ignore me")
        @quiz_assigned.update_attribute(:only_visible_to_overrides, true)

        assignment_override_model(quiz: @quiz_plain, set_type: "Noop", set_id: 9001, title: "should keep this")
        @quiz_plain.update_attribute(:only_visible_to_overrides, true)

        run_course_copy
        to_quiz_plain = @copy_to.quizzes.where(migration_id: mig_id(@quiz_plain)).first
        to_quiz_assigned = @copy_to.quizzes.where(migration_id: mig_id(@quiz_assigned)).first
        expect(to_quiz_assigned.assignment_overrides.count).to eq 0
        expect(to_quiz_assigned.only_visible_to_overrides).to be false
        expect(to_quiz_plain.assignment_overrides.count).to eq 1
        expect(to_quiz_plain.only_visible_to_overrides).to be true
      end
    end

    it "does not destroy assessment questions when copying twice" do
      bank1 = @copy_from.assessment_question_banks.create!(title: "bank")
      data = {
        "question_type" => "multiple_choice_question",
        "name" => "test question",
        "answers" => [{ "id" => 1, "text" => "Correct", "weight" => 100 },
                      { "id" => 2, "text" => "inorrect", "weight" => 0 }],
      }
      aq = bank1.assessment_questions.create!(question_data: data)

      run_course_copy

      run_course_copy # run it twice

      aq_to = @copy_to.assessment_questions.where(migration_id: mig_id(aq)).first
      expect(aq_to.data["question_type"]).to eq "multiple_choice_question"
    end

    it "does not remove outer tags with style tags from questions" do
      html = "<p style=\"text-align: center;\">This is aligned to the center</p>"
      q = @copy_from.quizzes.create!(title: "q")
      data = { "question_name" => "test question",
               "question_type" => "essay_question",
               "question_text" => html }
      q.quiz_questions.create!(question_data: data)

      run_course_copy

      q_to = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      qq_to = q_to.quiz_questions.first
      expect(qq_to.question_data[:question_text]).to eq html
    end
  end
end
