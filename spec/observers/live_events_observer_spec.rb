# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe LiveEventsObserver do
  describe "general" do
    it "doesn't post events for no change" do
      user_model(name: "Joey Joe Joe")

      @user.name = "Joey Joe Joe"
      expect(Canvas::LiveEvents).not_to receive(:user_updated)
      @user.save!
    end

    it "doesn't post events for NOP fields" do
      account_model
      course_model(name: "CS101", account: @account)
      sis = @account.sis_batches.create

      @course.name = "CS101"
      @course.sis_batch_id = sis.id
      expect(Canvas::LiveEvents).not_to receive(:course_updated)
      @course.save!
    end

    it "does post event for actual change" do
      user_model(name: "Joey Joe Joe")

      @user.name = "Joey Joe Joe Jr. Shabadu"
      expect(Canvas::LiveEvents).to receive(:user_updated).once
      @user.save!
    end
  end

  describe "syllabus" do
    it "doesn't post for no changes" do
      course_model
      @course.syllabus_body = "old syllabus"
      @course.save!

      expect(Canvas::LiveEvents).not_to receive(:course_syllabus_updated)
      @course.save!
    end

    it "posts update events" do
      course_model
      @course.syllabus_body = "old syllabus"
      @course.save!

      @course.syllabus_body = "new syllabus"
      expect(Canvas::LiveEvents).to receive(:course_syllabus_updated).with(@course, "old syllabus")
      @course.save
    end
  end

  describe "wiki" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:wiki_page_created).once
      wiki_page_model
    end

    it "posts update events for title" do
      wiki_page_model(title: "old title")
      expect(Canvas::LiveEvents).to receive(:wiki_page_updated).with(@page, "old title", nil)
      @page.title = "new title"
      @page.save
    end

    it "posts update events for body" do
      wiki_page_model(body: "old body")
      expect(Canvas::LiveEvents).to receive(:wiki_page_updated).with(@page, nil, "old body")
      @page.body = "new body"
      @page.save
    end

    it "does not post trivial update events" do
      wiki_page_model
      expect(Canvas::LiveEvents).not_to receive(:wiki_page_updated)
      @page.touch
    end

    it "posts soft delete events" do
      wiki_page_model
      expect(Canvas::LiveEvents).to receive(:wiki_page_deleted).once
      @page.destroy
    end

    it "posts delete events" do
      wiki_page_model
      expect(Canvas::LiveEvents).to receive(:wiki_page_deleted).once
      @page.destroy_permanently!
    end
  end

  describe "attachment" do
    let!(:attachment) { attachment_model }

    {
      display_name: "some_other_attachment_name_now",
      lock_at: 10.days.from_now,
      unlock_at: 10.days.from_now,
    }.each do |key, val|
      context "if #{key} changes" do
        it "posts attachment_updated events" do
          expect(Canvas::LiveEvents).to receive(:attachment_updated)
          attachment.update(key => val)
        end
      end
    end

    context "if the attachment moves to a new folder" do
      it "posts attachment_updated events" do
        expect(Canvas::LiveEvents).to receive(:attachment_updated)
        attachment.update(folder: folder_model)
      end
    end

    context "if only the modified_at timestamp changes" do
      it "does not post an attachment_updated event" do
        expect(Canvas::LiveEvents).not_to receive(:attachment_updated)
        attachment.touch
      end
    end
  end

  describe "conversation" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:conversation_created).once
      sender = user_model
      recipient = user_model
      conversation(sender, recipient)
    end
  end

  describe "conversation messsage" do
    it "posts conversation message create events" do
      expect(Canvas::LiveEvents).to receive(:conversation_message_created).once
      user1 = user_model
      user2 = user_model
      convo = Conversation.initiate([user1, user2], false)
      convo.add_message(user1, "create new conversation message")
    end
  end

  describe "course" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:course_created).once
      course_model
    end

    it "posts update events" do
      expect(Canvas::LiveEvents).to receive(:course_updated).twice
      course_model # creation fires updated as well
      @course.name = "Name Changed"
      @course.save
    end
  end

  describe "discussion topic" do
    it "posts create events" do
      course_model
      expect(Canvas::LiveEvents).to receive(:discussion_topic_created).once
      discussion_topic_model(context: @course)
    end
  end

  describe "discussion entry" do
    it "posts create events" do
      course_model
      expect(Canvas::LiveEvents).to receive(:discussion_entry_created).once
      discussion_topic_model(context: @course)
      @topic.discussion_entries.create!(message: "entry")
    end
  end

  describe "group" do
    it "posts create events for group_categories" do
      course = course_model
      expect(Canvas::LiveEvents).to receive(:group_category_created).once
      course.group_categories.create!(name: "project A", create_group_count: 2)
    end

    it "posts create events for groups" do
      course = course_model
      expect(Canvas::LiveEvents).to receive(:group_created).twice
      course.groups.create!(name: "Group 1")
      course.groups.create!(name: "Group 2")
    end

    it "posts update events for groups" do
      course = course_model
      group = course.groups.create!(name: "Group 1")
      expect(Canvas::LiveEvents).to receive(:group_updated).once
      group.name = "New Group Name"
      group.save
    end

    it "posts create events for group_memberships" do
      course = course_model
      student1 = course.enroll_student(user_model).user
      student2 = course.enroll_student(user_model).user
      group1 = course.groups.create!(name: "Group 1")
      group2 = course.groups.create!(name: "Group 2")
      expect(Canvas::LiveEvents).to receive(:group_membership_created).twice
      group1.add_user(student1)
      group2.add_user(student2)
    end

    it "posts update events for group_memberships" do
      course = course_model
      student = course.enroll_student(user_model).user
      group = course.groups.create!(name: "Group 1")
      membership = group.add_user(student)
      expect(Canvas::LiveEvents).to receive(:group_membership_updated).once
      membership.moderator = true
      membership.save
    end
  end

  describe "assignment" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:assignment_created).once
      assignment_model
    end

    it "posts update events" do
      expect(Canvas::LiveEvents).to receive(:assignment_updated).once
      assignment_model(title: "original")
      @assignment.title = "new title"
      @assignment.save
    end
  end

  describe "assignment overrides" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:assignment_override_created).once
      assignment_override_model
    end

    it "posts update events" do
      expect(Canvas::LiveEvents).to receive(:assignment_override_updated).once
      assignment_override_model(title: "original")
      @override.title = "new title"
      @override.save
    end
  end

  describe "submission" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:submission_created).once
      submission_model
    end

    it "does not post a create event when a submission is first created in an unsubmitted state" do
      expect(Canvas::LiveEvents).to_not receive(:submission_created)
      Submission.create!(assignment: assignment_model, user: user_model, workflow_state: "unsubmitted", submitted_at: Time.zone.now)
    end

    it "posts a create event when a submission is first created in an submitted state" do
      expect(Canvas::LiveEvents).to receive(:submission_created).once
      Submission.create!(
        assignment: assignment_model,
        user: user_model,
        workflow_state: "submitted",
        submitted_at: Time.zone.now,
        submission_type: "online_url"
      )
    end

    it "posts a submission_created event when a unsubmitted submission is submitted" do
      s = unsubmitted_submission_model
      expect(Canvas::LiveEvents).to receive(:submission_created).once
      s.assignment.submit_homework(s.user, { url: "http://www.instructure.com/" })
    end

    it "posts a create event when a submitted submission is resubmitted" do
      s = submission_model
      expect(Canvas::LiveEvents).to receive(:submission_created).once
      s.assignment.submit_homework(s.user, { url: "http://www.instructure.com/" })
    end

    it "posts update events" do
      expect(Canvas::LiveEvents).to receive(:submission_updated).once
      s = submission_model
      s.excused = true
      s.save!
    end
  end

  describe "user" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:user_created).once
      user_model
    end

    it "posts update events" do
      expect(Canvas::LiveEvents).to receive(:user_updated).once
      user_model
      @user.name = "Name Changed"
      @user.save
    end
  end

  describe "enrollment" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:enrollment_created).once
      course_with_student
    end

    it "posts update events" do
      expect(Canvas::LiveEvents).to receive(:enrollment_updated).once
      course_with_student
      @enrollment.workflow_state = "rejected"
      @enrollment.save
    end
  end

  describe "enrollment_state" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:enrollment_state_created).once
      course_with_student
    end

    it "posts update events" do
      expect(Canvas::LiveEvents).to receive(:enrollment_state_updated).once
      course_with_student
      @enrollment.limit_privileges_to_course_section = true
      @enrollment.save
    end
  end

  describe "user_account_association" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:user_account_association_created).once
      user_with_pseudonym(account: Account.default, username: "bobbo", active_all: true)
    end
  end

  describe "account_notification" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:account_notification_created).once
      account_notification
    end
  end

  context "content_exports" do
    def enable_quizzes_next(course)
      course.enable_feature!(:quizzes_next)
      # do quizzes next provision
      # quizzes_next is available to users only after quizzes next provisioning
      course.root_account.settings[:provision] = { "lti" => "lti url" }
      course.root_account.save!
    end

    describe "quiz_export_complete" do
      it "posts update events for quizzes2" do
        expect(Canvas::LiveEvents).to receive(:quiz_export_complete).once
        course = Account.default.courses.create!
        enable_quizzes_next(course)

        Account.default.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )
        quiz = course.quizzes.create!(title: "quiz1")
        ce = course.content_exports.create!(
          export_type: ContentExport::QUIZZES2,
          selected_content: quiz.id,
          user: user_model
        )
        ce.export(synchronous: true)
      end

      it "does not post for other ContentExport types" do
        expect(Canvas::LiveEvents).not_to receive(:quiz_export_complete)
        course = Account.default.courses.create!
        ce = course.content_exports.create!
        ce.export(synchronous: true)
      end
    end

    describe "content_export_created" do
      it "posts for ContentExport created type" do
        expect(Canvas::LiveEvents).to receive(:content_export_created).once
        course = Account.default.courses.create!
        ce = course.content_exports.create!
        ce.export(synchronous: true)
      end
    end
  end

  describe "content_migration_completed" do
    it "posts update events" do
      expect(Canvas::LiveEvents).to receive(:content_migration_completed).once
      user_model
      account_model
      course_model(name: "CS101", account: @account)
      @cm = ContentMigration.create!(
        context: @course,
        user: @teacher,
        workflow_state: "importing",
        migration_settings: {
          import_quizzes_next: true
        }
      )
      @cm.workflow_state = "imported"
      @cm.save!
    end
  end

  describe "modules" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:module_created).with(anything)
      Account.default.courses.create!.context_modules.create!
    end

    it "posts update events" do
      context_module = Account.default.courses.create!.context_modules.create!
      expect(Canvas::LiveEvents).to receive(:module_updated).with(context_module)
      context_module.update_attribute(:position, 10)
    end
  end

  describe "context events" do
    let(:course) { Account.default.courses.create! }

    context "the tag_type is context_module" do
      it "posts create events" do
        expect(Canvas::LiveEvents).to receive(:module_item_created).with(anything)
        context_module = course.context_modules.create!
        ContentTag.create!(
          title: "content",
          context: course,
          tag_type: "context_module",
          context_module:
        )
      end

      it "posts update events" do
        context_module = course.context_modules.create!
        content_tag = ContentTag.create!(
          title: "content",
          context: course,
          tag_type: "context_module",
          context_module:
        )
        expect(Canvas::LiveEvents).to receive(:module_item_updated).with(content_tag)
        content_tag.update_attribute(:position, 11)
      end
    end

    context "the tag_type is context_module_progression" do
      let(:context_module) { course.context_modules.create! }
      let(:context_module_progression) { context_module.context_module_progressions.create!(user_id: user_model.id) }

      it "posts update events if module and course are complete" do
        expect(Canvas::LiveEvents).to receive(:course_completed).with(any_args)
        expect_any_instance_of(CourseProgress).to receive(:completed?).and_return(true)
        context_module_progression.workflow_state = "completed"
        context_module_progression.requirements_met = ["done"]
        context_module_progression.save!
      end

      it "does not post update events if module is not complete" do
        expect(Canvas::LiveEvents).not_to receive(:course_completed).with(any_args)
        context_module_progression.update_attribute(:workflow_state, "in_progress")
      end

      it "does not post update events if course is not actually complete" do
        expect(Canvas::LiveEvents).not_to receive(:course_completed).with(any_args)
        expect_any_instance_of(CourseProgress).to receive(:completed?).and_return(false)
        context_module_progression.workflow_state = "completed"
        context_module_progression.requirements_met = ["done?"]
        context_module_progression.save!
      end
    end

    context "the tag_type is not context_module or context_module_progression" do
      it "does nothing" do
        expect(Canvas::LiveEvents).not_to receive(:module_item_created)
        expect(Canvas::LiveEvents).not_to receive(:module_item_updated)
        context_module = course.context_modules.create!
        content_tag = ContentTag.create!(
          title: "content",
          context: course,
          tag_type: "learning_outcome",
          context_module:
        )
        content_tag.update_attribute(:position, 11)
      end
    end
  end

  describe "learning_outcomes" do
    before do
      @context = course_model
    end

    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:learning_outcome_created).with(anything)
      outcome_model
    end

    it "posts update events" do
      outcome = outcome_model
      expect(Canvas::LiveEvents).to receive(:learning_outcome_updated).with(outcome)
      outcome.update_attribute(:short_description, "this is new")
    end
  end

  describe "learning_outcome_groups" do
    before do
      @context = course_model
      @context.root_outcome_group
    end

    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:learning_outcome_group_created).with(anything)
      outcome_group_model
    end

    it "posts update events" do
      group = outcome_group_model
      expect(Canvas::LiveEvents).to receive(:learning_outcome_group_updated).with(group)
      group.update_attribute(:description, "this is new")
    end
  end

  describe "learning_outcome_links" do
    before do
      @context = course_model
    end

    it "posts create events" do
      outcome = outcome_model
      group = outcome_group_model
      expect(Canvas::LiveEvents).to receive(:learning_outcome_link_created).with(anything)
      group.add_outcome(outcome)
    end

    it "posts updated events" do
      outcome = outcome_model
      group = outcome_group_model
      link = group.add_outcome(outcome)
      expect(Canvas::LiveEvents).to receive(:learning_outcome_link_updated).with(link)
      link.destroy!
    end
  end

  describe "outcome_proficiency" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:outcome_proficiency_created).once
      outcome_proficiency_model(account_model)
    end

    it "posts updated events when ratings are changed" do
      proficiency = outcome_proficiency_model(account_model)
      expect(Canvas::LiveEvents).to receive(:outcome_proficiency_updated).once
      rating = OutcomeProficiencyRating.new(description: "new_rating", points: 5, mastery: true, color: "ff0000")
      proficiency.outcome_proficiency_ratings = [rating]
      proficiency.save!
    end

    it "posts updated events when proficiencies are destroyed" do
      proficiency = outcome_proficiency_model(account_model)
      expect(Canvas::LiveEvents).to receive(:outcome_proficiency_updated).once
      proficiency.destroy
    end
  end

  describe "calculation_method" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:outcome_calculation_method_created).once
      outcome_calculation_method_model(account_model)
    end

    it "posts updated events" do
      calculation_method = outcome_calculation_method_model(account_model)
      expect(Canvas::LiveEvents).to receive(:outcome_calculation_method_updated).once
      calculation_method.destroy
    end
  end

  describe "friendly_description" do
    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:outcome_friendly_description_created).once
      outcome_friendly_description_model(account_model)
    end

    it "posts updated events when friendly description is changed" do
      friendly_description = outcome_friendly_description_model(account_model)
      expect(Canvas::LiveEvents).to receive(:outcome_friendly_description_updated).once
      friendly_description.description = "A new friendly description"
      friendly_description.save!
    end

    it "posts updated events when proficiencies are destroyed" do
      friendly_description = outcome_friendly_description_model(account_model)
      expect(Canvas::LiveEvents).to receive(:outcome_friendly_description_updated).once
      friendly_description.destroy
    end
  end

  describe "RubricAssessment" do
    before(:once) do
      outcome_model
      outcome_with_rubric(outcome: @outcome, context: Account.default)
      course_with_student
    end

    it "posts create events" do
      expect(Canvas::LiveEvents).to receive(:rubric_assessed).once
      rubric_assessment_model(rubric: @rubric, user: @student)
    end

    # an update event will look like a save for a rubric assessment
    # because it is simply versioned
    it "posts update events" do
      expect(Canvas::LiveEvents).to receive(:rubric_assessed).twice
      first_assessment = rubric_assessment_model(rubric: @rubric, user: @student)
      expect(first_assessment.versions.count).to eq 1

      first_assessment.score = 1
      first_assessment.save
      expect(first_assessment.reload.versions.count).to eq 2
    end
  end

  describe "MasterCourses::MasterTemplate" do
    it "posts create events" do
      course_model
      expect(Canvas::LiveEvents).to receive(:master_template_created).once
      MasterCourses::MasterTemplate.create!(course: @course)
    end
  end

  describe "MasterCourses::MasterMigration" do
    it "posts update events when the migration completes" do
      course_model
      master_template = MasterCourses::MasterTemplate.create!(course: @course)
      master_migration = MasterCourses::MasterMigration.create!(master_template:)
      expect(Canvas::LiveEvents).to receive(:master_migration_completed).once
      master_migration.update(workflow_state: "completed")
    end

    it "does not post update events when the migration updates for other reasons" do
      course_model
      master_template = MasterCourses::MasterTemplate.create!(course: @course)
      master_migration = MasterCourses::MasterMigration.create!(master_template:)
      expect(Canvas::LiveEvents).not_to receive(:master_migration_completed)
      master_migration.update(workflow_state: "exports_failed")
    end
  end

  describe "MasterCourses::MasterContentTag" do
    before do
      course_model
      default_restrictions =
        { content: true, points: false, due_dates: false, availability_dates: false }
      assignment = @course.assignments.create!
      master_template = MasterCourses::MasterTemplate.create!(course: @course)
      @master_content_tag_params = {
        master_template_id: master_template.id,
        content_type: "Assignment",
        content_id: assignment.id,
        restrictions: default_restrictions,
        migration_id: "mastercourse_1_3_f9ca51a6679e4779d0d68ef2dc33bc0a",
        use_default_restrictions: true
      }
    end

    context "when the master_content_tag is associated with a New Quiz" do
      before do
        allow_any_instance_of(Assignment).to receive(:quiz_lti?).and_return(true)
      end

      context "when the restrictions field change" do
        it "posts a blueprint_restrictions_updated event after update" do
          expect(Canvas::LiveEvents).to receive(:blueprint_restrictions_updated).once
          master_content_tag = MasterCourses::MasterContentTag.create!(@master_content_tag_params)

          updated_restrictions =
            { content: false, points: true, due_dates: false, availability_dates: false }
          master_content_tag.update!(restrictions: updated_restrictions)
        end
      end

      context "when the use_default_restrictions field change" do
        it "posts a blueprint_restrictions_updated event after update" do
          expect(Canvas::LiveEvents).to receive(:blueprint_restrictions_updated).once
          master_content_tag = MasterCourses::MasterContentTag.create!(@master_content_tag_params)
          master_content_tag.update!(use_default_restrictions: false)
        end
      end

      context "when restriction-related fields do not change" do
        it "does not post a blueprint_restrictions_updated event after update" do
          expect(Canvas::LiveEvents).not_to receive(:blueprint_restrictions_updated)
          master_content_tag = MasterCourses::MasterContentTag.create!(@master_content_tag_params)
          master_content_tag.update!(migration_id: "mastercourse_1_3_d0d68ef2dc33bc0af9ca51a6679e4779")
        end
      end
    end

    context "when the master_content_tag is not associated with a New Quiz" do
      it "does not post a blueprint_restrictions_updated event after update" do
        expect(Canvas::LiveEvents).not_to receive(:blueprint_restrictions_updated)
        master_content_tag = MasterCourses::MasterContentTag.create!(@master_content_tag_params)
        updated_restrictions =
          { content: false, points: true, due_dates: false, availability_dates: false }
        master_content_tag.update!(restrictions: updated_restrictions)
      end
    end
  end
end
