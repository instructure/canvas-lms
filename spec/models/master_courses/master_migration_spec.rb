# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe MasterCourses::MasterMigration do
  before :once do
    course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    user_factory
  end

  before do
    skip unless Qti.qti_enabled?
    local_storage!
  end

  def mig_id(obj)
    @template.migration_id_for(obj)
  end

  def run_master_migration(opts = {})
    @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @admin, opts)
    run_jobs
    @migration.reload
  end

  def run_course_copy(copy_from, copy_to)
    @cm = ContentMigration.new(context: copy_to,
                               user: @user,
                               source_course: copy_from,
                               migration_type: "course_copy_importer",
                               copy_options: { everything: "1" })
    @cm.migration_settings[:import_immediately] = true
    @cm.set_default_settings
    @cm.save!
    worker = Canvas::Migration::Worker::CourseCopyWorker.new
    worker.perform(@cm)
  end

  describe "start_new_migration!" do
    it "queues a migration" do
      expect_any_instance_of(MasterCourses::MasterMigration).to receive(:queue_export_job).once
      mig = MasterCourses::MasterMigration.start_new_migration!(@template, @user)
      expect(mig.root_account).to eq @course.root_account
      expect(mig.id).to be_present
      expect(mig.master_template).to eq @template
      expect(mig.user).to eq @user
      expect(@template.active_migration).to eq mig
    end

    it "raises an error if there's already a migration running" do
      running = @template.master_migrations.create!(workflow_state: "exporting")
      @template.active_migration = running
      @template.save!

      expect_any_instance_of(MasterCourses::MasterMigration).not_to receive(:queue_export_job)
      expect do
        MasterCourses::MasterMigration.start_new_migration!(@template, @user)
      end.to raise_error("cannot start new migration while another one is running")
    end

    it "still allows if the 'active' migration has been running for a while (and is probably ded)" do
      running = @template.master_migrations.create!(workflow_state: "exporting")
      @template.active_migration = running
      @template.save!

      Timecop.freeze(2.days.from_now) do
        expect_any_instance_of(MasterCourses::MasterMigration).to receive(:queue_export_job).once
        MasterCourses::MasterMigration.start_new_migration!(@template, @user)
      end
    end

    it "queues a job" do
      expect { MasterCourses::MasterMigration.start_new_migration!(@template, @user) }.to change(Delayed::Job, :count).by(1)
      expect_any_instance_of(MasterCourses::MasterMigration).to receive(:perform_exports).once
      run_jobs
    end

    context "priority option" do
      before :once do
        course_factory
        @template.add_child_course!(@course)
      end

      def assert_job_priority(priority)
        export_job = Delayed::Job.where(tag: "MasterCourses::MasterMigration#perform_exports").last
        expect(export_job.priority).to eq priority
        run_job(export_job)

        import_job = Delayed::Job.where(tag: "ContentMigration#import_content").last
        expect(import_job.priority).to eq priority
      end

      it "defaults to Delayed::LOW_PRIORITY" do
        MasterCourses::MasterMigration.start_new_migration!(@template, @user)
        assert_job_priority(Delayed::LOW_PRIORITY)
      end

      it "honors the setting if present" do
        MasterCourses::MasterMigration.start_new_migration!(@template, @user, priority: 42)
        assert_job_priority(42)
      end
    end
  end

  describe "perform_exports" do
    before :once do
      @migration = @template.master_migrations.create!
    end

    it "does not do anything if there aren't any child courses to push to" do
      expect(@migration).not_to receive(:create_export)
      @migration.perform_exports
      @migration.reload
      expect(@migration).to be_completed
      expect(@migration.export_results[:message]).to eq "No child courses to export to"
    end

    it "does not count deleted subscriptions" do
      other_course = course_factory
      sub = @template.add_child_course!(other_course)
      sub.destroy!

      expect(@migration).not_to receive(:create_export)
      @migration.perform_exports
    end

    it "records errors" do
      other_course = course_factory
      @template.add_child_course!(other_course)
      allow(@migration).to receive(:create_export).and_raise "oh neos"
      expect { @migration.perform_exports }.to raise_error("oh neos")

      @migration.reload
      expect(@migration).to be_exports_failed
      expect(ErrorReport.find(@migration.export_results[:error_report_id]).message).to eq "oh neos"
    end

    it "does a full export by default" do
      new_course = course_factory
      new_sub = @template.add_child_course!(new_course)

      expect(@migration).to receive(:export_to_child_courses).with(:full, [new_sub], true)
      @migration.perform_exports
    end

    it "does a selective export based on subscriptions" do
      old_course = course_factory
      sel_sub = @template.add_child_course!(old_course)
      sel_sub.update_attribute(:use_selective_copy, true)

      expect(@migration).to receive(:export_to_child_courses).with(:selective, [sel_sub], true)
      @migration.perform_exports
    end

    it "does two exports if needed" do
      new_course = course_factory
      @template.add_child_course!(new_course)
      old_course = course_factory
      sel_sub = @template.add_child_course!(old_course)
      sel_sub.update_attribute(:use_selective_copy, true)

      expect(@migration).to receive(:export_to_child_courses).twice
      @migration.perform_exports
    end
  end

  describe "Assignment's external tools migration" do
    before :once do
      account_admin_user(active_all: true)
      @copy_from = @course
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)
      tool = external_tool_model(context: Account.default, opts: { use_1_3: true, developer_key: DeveloperKey.create!(account: Account.default) })
      @original_assignment = @copy_from.assignments.create!(title: "some assignment", submission_types: "external_tool", points_possible: 10)
      tag = ContentTag.new(content: tool, url: "http://example.com/original", context: @original_assignment)
      @original_assignment.update!(external_tool_tag: tag)
      @original_line_item = @original_assignment.line_items.first
      @original_line_item.update!(resource_id: "some_resource_id")
    end

    before do
      run_master_migration
      @assignment_copy = @copy_to.assignments.where(migration_id: mig_id(@original_assignment)).first
      @line_item_copy = @assignment_copy.line_items.last
    end

    it "copies external tool tag over" do
      @assignment_copy = @copy_to.assignments.where(migration_id: mig_id(@original_assignment)).first
      expect(@assignment_copy.reload.external_tool_tag).to be_truthy
      expect(@assignment_copy.reload.external_tool_tag.url).to eq "http://example.com/original"
    end

    it "updates associated course's external tool tag on blueprint update" do
      @original_assignment.external_tool_tag.update!(url: "http://example.com/blueprint_updated", new_tab: true)
      @original_assignment.touch
      run_master_migration
      @assignment_copy = @copy_to.assignments.where(migration_id: mig_id(@original_assignment)).first
      expect(@assignment_copy.external_tool_tag.url).to eq "http://example.com/blueprint_updated"
    end

    it "does not update associated course's external tool tag on blueprint update if the associated course had an independent update" do
      @assignment_copy.external_tool_tag.update!(url: "http://example.com/associated_updated", new_tab: true)
      @original_assignment.touch
      run_master_migration
      expect(@assignment_copy.reload.external_tool_tag.url).to eq "http://example.com/associated_updated"
    end

    context "with blueprint_line_item_support ON" do
      it "respects line item downstream editing and assignment locking" do
        Account.site_admin.enable_feature! :blueprint_line_item_support

        @original_line_item.update!(resource_id: "updated_resource_id")
        @original_assignment.update!(title: "updated assignment title")
        run_master_migration
        expect(@line_item_copy.reload.resource_id).to eq("updated_resource_id")

        @line_item_copy.update! resource_id: "downstream_resource_id"
        @original_line_item.update!(resource_id: "updated_resource_id AGAIN")
        @original_assignment.update!(title: "updated assignment title AGAIN")
        @original_assignment.touch
        run_master_migration

        # The one line item downstream change stops assignment sync as a whole
        expect(@assignment_copy.reload.title).to eq("updated assignment title")
        expect(@line_item_copy.reload.label).to eq("updated assignment title")
        expect(@line_item_copy.reload.resource_id).to eq("downstream_resource_id")

        @template.content_tag_for(@original_assignment).update_attribute(:restrictions, { content: true })
        run_master_migration

        expect(@assignment_copy.reload.title).to eq("updated assignment title AGAIN")
        expect(@line_item_copy.reload.label).to eq("updated assignment title AGAIN")
        expect(@line_item_copy.reload.resource_id).to eq("updated_resource_id AGAIN")
      end

      it "does not cause errors for regular course copies" do
        fresh_course = course_factory
        Account.site_admin.enable_feature! :blueprint_line_item_support
        run_course_copy(@copy_from, fresh_course)
        expect(fresh_course.assignments.count).to eq(@copy_from.assignments.count)
        expect(@cm.migration_issues).to be_empty
      end
    end

    context "with blueprint_line_item_support OFF" do
      it "ignores downstream editing" do
        Account.site_admin.disable_feature! :blueprint_line_item_support

        expect(@original_line_item.resource_id).to eq("some_resource_id")

        @original_line_item.update!(resource_id: "updated_resource_id")
        @original_assignment.update!(title: "updated assignment title")
        run_master_migration
        expect(@line_item_copy.reload.resource_id).to eq("updated_resource_id")

        @line_item_copy.update! resource_id: "downstream_resource_id"
        @original_line_item.update!(resource_id: "updated_resource_id AGAIN")
        @original_assignment.update!(title: "updated assignment title AGAIN")
        @original_assignment.touch
        Timecop.freeze(1.minute.from_now) { run_master_migration }
        expect(@assignment_copy.reload.title).to eq("updated assignment title AGAIN")
        expect(@line_item_copy.reload.label).to eq("updated assignment title AGAIN")
        expect(@line_item_copy.reload.resource_id).to eq("updated_resource_id AGAIN")
      end

      it "ignores assignment locking" do
        Account.site_admin.disable_feature! :blueprint_line_item_support
        expect(@original_line_item.resource_id).to eq("some_resource_id")

        @template.content_tag_for(@original_assignment).update_attribute(:restrictions, { content: true })
        @original_line_item.update!(resource_id: "updated_resource_id")
        @original_assignment.update!(title: "updated assignment title")

        Timecop.freeze(1.minute.from_now) { run_master_migration }
        expect(@line_item_copy.reload.label).to eq("updated assignment title")
        expect(@line_item_copy.reload.resource_id).to eq("updated_resource_id")
      end
    end
  end

  describe "Course pace migration" do
    before :once do
      account_admin_user(active_all: true)
      @copy_from = @course

      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @module = @copy_from.context_modules.create! name: "M"
      @assignment = @copy_from.assignments.create! name: "A", workflow_state: "unpublished"
      @tag = @assignment.context_module_tags.create! context_module: @module, context: @copy_from, tag_type: "context_module"

      @original_pace = @copy_from.course_paces.create!
      @original_pace_item = @original_pace.course_pace_module_items.create! module_item: @tag, duration: 2

      run_master_migration
      @copied_pace = @copy_to.course_paces.where(migration_id: mig_id(@original_pace)).first
      @copied_pace_item = @copied_pace.course_pace_module_items.where(migration_id: mig_id(@original_pace_item)).first

      @original_pace.touch
    end

    it "copies the module item data over" do
      expect(@copied_pace_item).to be_truthy
      expect(@copied_pace_item.duration).to eq 2
    end

    it "updates module item data" do
      @original_pace_item.update!(duration: 4)
      Timecop.travel(1.minute.from_now) do
        run_master_migration
      end
      expect(@copied_pace_item.reload.duration).to eq 4
    end

    it "does not overwrite downstream changes" do
      @copied_pace_item.update!(duration: 10)
      @original_pace_item.update!(duration: 4)
      Timecop.travel(1.minute.from_now) do
        run_master_migration
      end
      expect(@copied_pace_item.reload.duration).to eq 10
    end

    it "does overwrite downstream changes if locked" do
      @copied_pace_item.update!(duration: 10)
      @original_pace_item.update!(duration: 4)
      @template.content_tag_for(@original_pace).update_attribute(:restrictions, { content: true })
      Timecop.travel(1.minute.from_now) do
        run_master_migration
      end
      expect(@copied_pace_item.reload.duration).to eq 4
    end

    it "keeps course pace related tags up to date when default restrictions are set" do
      @pace_1 = @copy_from.course_paces.create!
      @pace_2 = @copy_from.course_paces.create!

      pace_tag1 = @template.create_content_tag_for!(@pace_1, use_default_restrictions: true)
      pace_tag2 = @template.create_content_tag_for!(@pace_2, use_default_restrictions: false)

      pace_restricts = { content: true }

      @template.update_attribute(:default_restrictions_by_type, { "CoursePace" => pace_restricts })
      expect(pace_tag1.reload.restrictions).to be_blank # shouldn't have updated yet because it's not configured to use per-object defaults

      @template.update_attribute(:use_default_restrictions_by_type, true)
      expect(pace_tag1.reload.restrictions).to eq pace_restricts
      expect(pace_tag2.reload.restrictions).to be_blank # shouldn't have updated because use_default_restrictions is not set

      @template.update_attribute(:default_restrictions_by_type, {})
      expect(pace_tag1.reload.restrictions).to be_blank
    end
  end

  describe "all the copying" do
    before :once do
      account_admin_user(active_all: true)
      @copy_from = @course
    end

    it "creates an export once and import in each child course" do
      @copy_to1 = course_factory
      @sub1 = @template.add_child_course!(@copy_to1)
      @copy_to2 = course_factory
      @sub2 = @template.add_child_course!(@copy_to2)

      assmt = @copy_from.assignments.create!(name: "some assignment")
      att = Attachment.create!(filename: "1.txt", uploaded_data: StringIO.new("1"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)

      run_master_migration

      expect(@migration).to be_completed
      expect(@migration.imports_completed_at).to be_present
      expect(@migration.migration_results.last.root_account_id).to eq @copy_from.root_account_id

      expect(@template.master_content_tags.where(content: assmt).first.restrictions).to be_empty # never mind

      [@sub1, @sub2].each do |sub|
        sub.reload
        expect(sub.use_selective_copy?).to be_truthy # should have been marked as up-to-date now
      end

      [@copy_to1, @copy_to2].each do |copy_to|
        assmt_to = copy_to.assignments.where(migration_id: mig_id(assmt)).first
        expect(assmt_to).to be_present
        att_to = copy_to.attachments.where(migration_id: mig_id(att)).first
        expect(att_to).to be_present
      end
    end

    it "copies selectively on second time" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      topic = @copy_from.discussion_topics.create!(title: "some title")
      DiscussionTopic.where(id: topic).update_all(updated_at: 5.seconds.ago) # just in case, to fool the selective export
      att = Attachment.create!(filename: "1.txt", uploaded_data: StringIO.new("1"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      Attachment.where(id: att).update_all(updated_at: 5.seconds.ago) # ditto

      run_master_migration
      expect(@migration.export_results.keys).to eq [:full]

      topic_to = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(topic_to).to be_present
      att_to = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(att_to).to be_present
      cm1 = @migration.migration_results.first.content_migration
      expect(cm1.source_course_id).to eq @copy_from.id
      expect(cm1.migration_settings[:imported_assets]["DiscussionTopic"]).to eq topic_to.id.to_s
      expect(cm1.migration_settings[:imported_assets]["Attachment"]).to eq att_to.id.to_s

      page = @copy_from.wiki_pages.create!(title: "another title")

      run_master_migration
      expect(@migration.export_results.keys).to eq [:selective]

      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      expect(page_to).to be_present

      cm2 = @migration.migration_results.first.content_migration
      expect(cm2.migration_settings[:imported_assets]["DiscussionTopic"]).to be_blank # should have excluded it from the selective export
      expect(cm2.migration_settings[:imported_assets]["Attachment"]).to be_blank
      expect(cm2.migration_settings[:imported_assets]["WikiPage"]).to eq page_to.id.to_s
    end

    it "syncs deletions in incremental updates (except items modified downstream, unless locked)" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      assmt = @copy_from.assignments.create!
      @template.content_tag_for(assmt).update_attribute(:restrictions, { points: true })
      topic = @copy_from.discussion_topics.create!(message: "hi", title: "discussion title")
      ann = @copy_from.announcements.create!(message: "goodbye")
      page = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai")
      page2 = @copy_from.wiki_pages.create!(title: "wiki", body: "bluh")
      quiz = @copy_from.quizzes.create!
      quiz2 = @copy_from.quizzes.create!
      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      bank.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      file = @copy_from.attachments.create!(filename: "blah", uploaded_data: default_uploaded_data)
      event = @copy_from.calendar_events.create!(title: "thing", description: "blargh", start_at: 1.day.from_now)
      tool = @copy_from.context_external_tools.create!(name: "new tool",
                                                       consumer_key: "key",
                                                       shared_secret: "secret",
                                                       custom_fields: { "a" => "1", "b" => "2" },
                                                       url: "http://www.example.com")

      run_master_migration

      assmt_to = @copy_to.assignments.where(migration_id: mig_id(assmt)).first
      topic_to = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      ann_to = @copy_to.announcements.where(migration_id: mig_id(ann)).first
      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      page2_to = @copy_to.wiki_pages.where(migration_id: mig_id(page2)).first
      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      quiz2_to = @copy_to.quizzes.where(migration_id: mig_id(quiz2)).first
      bank_to = @copy_to.assessment_question_banks.where(migration_id: mig_id(bank)).first
      file_to = @copy_to.attachments.where(migration_id: mig_id(file)).first
      event_to = @copy_to.calendar_events.where(migration_id: mig_id(event)).first
      tool_to = @copy_to.context_external_tools.where(migration_id: mig_id(tool)).first

      Timecop.freeze(10.minutes.from_now) do
        page2_to.update_attribute(:body, "changed!")
        quiz2_to.update_attribute(:title, "blargh!")
        assmt_to.update_attribute(:title, "blergh!")

        assmt.destroy
        topic.destroy
        ann.destroy
        page.destroy
        page2.destroy
        quiz.destroy
        quiz2.destroy
        bank.destroy
        file.destroy
        event.destroy
        tool.destroy
      end

      Timecop.travel(20.minutes.from_now) do
        mm = run_master_migration

        deletions = mm.export_results[:selective][:deleted]
        expect(deletions.keys).to match_array(["AssessmentQuestionBank", "Assignment", "Attachment", "CalendarEvent", "DiscussionTopic", "ContextExternalTool", "Quizzes::Quiz", "WikiPage"])
        expect(deletions["Assignment"]).to match_array([mig_id(assmt)])
        expect(deletions["Attachment"]).to match_array([mig_id(file)])
        expect(deletions["WikiPage"]).to match_array([mig_id(page), mig_id(page2)])
        expect(deletions["Quizzes::Quiz"]).to match_array([mig_id(quiz), mig_id(quiz2)])

        skips = mm.migration_results.first.skipped_items
        expect(skips).to match_array([mig_id(quiz2), mig_id(page2)])

        expect(assmt_to.reload).to be_deleted
        expect(topic_to.reload).to be_deleted
        expect(ann_to.reload).to be_deleted
        expect(page_to.reload).to be_deleted
        expect(page2_to.reload).not_to be_deleted
        expect(quiz_to.reload).to be_deleted
        expect(quiz2_to.reload).not_to be_deleted
        expect(bank_to.reload).to be_deleted
        expect(file_to.reload).to be_deleted
        expect(event_to.reload).to be_deleted
        expect(tool_to.reload).to be_deleted
      end
    end

    it "doesn't cause spurious sync exceptions when deleting graded quizzes and discussions from the blueprint" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      topic = @copy_from.assignments.create!(submission_types: "discussion_topic").discussion_topic
      quiz = @copy_from.quizzes.create!(quiz_type: "assignment")

      run_master_migration

      topic_to = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first

      Timecop.freeze(10.minutes.from_now) do
        topic.destroy
        quiz.destroy
      end

      Timecop.travel(20.minutes.from_now) do
        run_master_migration
      end

      expect(topic_to.reload).to be_deleted
      expect(quiz_to.reload).to be_deleted

      child_sub = @copy_to.master_course_subscriptions.take
      expect(child_sub.content_tag_for(topic_to).downstream_changes).to be_empty
      expect(child_sub.content_tag_for(quiz_to).downstream_changes).to be_empty
    end

    it "deletes associated pages before importing new ones" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      @page = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai")
      run_master_migration

      @page_to = @copy_to.wiki_pages.where(migration_id: mig_id(@page)).first
      Timecop.freeze(1.minute.from_now) do
        @page.destroy
        @page2 = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai") # same title
      end

      run_master_migration
      expect(@page_to.reload).to be_deleted
      @page2_to = @copy_to.wiki_pages.where(migration_id: mig_id(@page2)).first
      expect(@page2_to.title).to eq @page2.title
    end

    context "when in the blueprint course a file gets replaced" do
      let(:child_course) { course_factory }
      let(:master_course) { @copy_from }
      let(:master_template) { @template }
      let(:file_name) { "filename" }
      let(:attachment_attributes) do
        { filename: file_name, uploaded_data: default_uploaded_data }
      end
      let(:master_attachments) { master_course.reload.attachments.map { |a| [a.display_name, a.file_state] } }
      let(:child_attachments) { child_course.reload.attachments.map { |a| [a.display_name, a.file_state] } }

      before do
        master_course.attachments.create!(attachment_attributes)
        master_template.add_child_course!(child_course)
        run_master_migration
      end

      context "when the child course doesn't have a file with the same name" do
        before do
          Timecop.travel(1.minute.from_now) do
            master_course.attachments.create!(attachment_attributes).handle_duplicates(:overwrite)
            run_master_migration
          end
        end

        it "handles the replacements in both master and child course" do
          expect(master_attachments).to match_array([[file_name, "deleted"], [file_name, "available"]])
          expect(child_attachments).to match_array([[file_name, "deleted"], [file_name, "available"]])
        end
      end

      context "when the child course has a file with the same name" do
        before do
          Timecop.travel(1.minute.from_now) do
            child_course.attachments.create!(attachment_attributes)
            master_course.attachments.create!(attachment_attributes).handle_duplicates(:overwrite)
            run_master_migration
          end
        end

        it "handles the replacement in the child course" do
          expect(child_attachments).to match_array([
                                                     [file_name, "deleted"],
                                                     [file_name, "available"],
                                                     ["#{file_name}-1", "available"]
                                                   ])
        end
      end
    end

    it "syncs deleted quiz questions (unless changed downstream)" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qq1 = quiz.quiz_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      qq2 = quiz.quiz_questions.create!(question_data: { "question_name" => "test question 2", "question_type" => "essay_question" })
      qgroup = quiz.quiz_groups.create!(name: "group", pick_count: 1)
      qq3 = qgroup.quiz_questions.create!(quiz:, question_data: { "question_name" => "test group question", "question_type" => "essay_question" })
      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      qq1_to = quiz_to.quiz_questions.where(migration_id: mig_id(qq1)).first
      qq2_to = quiz_to.quiz_questions.where(migration_id: mig_id(qq2)).first
      qq3_to = quiz_to.quiz_questions.where(migration_id: mig_id(qq3)).first

      new_text = "new text"
      qq1_to.update_attribute(:question_data, qq1_to.question_data.merge("question_text" => new_text))
      Timecop.freeze(2.minutes.from_now) do
        qq2.destroy
      end
      run_master_migration

      expect(qq1_to.reload.question_data["question_text"]).to eq new_text
      expect(qq2_to.reload).to_not be_deleted # should not have overwritten because downstream changes

      Timecop.freeze(4.minutes.from_now) do
        @template.content_tag_for(quiz).update_attribute(:restrictions, { content: true })
      end
      run_master_migration

      expect(qq1_to.reload.question_data["question_text"]).to_not eq new_text # should overwrite now because locked
      expect(qq2_to.reload).to be_deleted
      expect(qq3_to.reload).to_not be_deleted
    end

    it "does not restore quiz questions deleted downstream (unless locked)" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qq = quiz.quiz_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      qq_to = quiz_to.quiz_questions.where(migration_id: mig_id(qq)).first

      qq_to.destroy
      Timecop.freeze(2.minutes.from_now) do
        quiz.touch # re-sync
      end
      run_master_migration
      expect(quiz_to.quiz_questions.active.exists?).to be false # didn't recreate the question

      Timecop.freeze(4.minutes.from_now) do
        @template.content_tag_for(quiz).update_attribute(:restrictions, { content: true })
      end
      run_master_migration

      expect(quiz_to.quiz_questions.active.exists?).to be true # new question but it has the same content
      expect(qq_to.reload).to be_deleted # original doesn't get restored because it just made a new question instead /shrug
    end

    it "syncs deleted quiz groups (unless changed downstream)" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qgroup1 = quiz.quiz_groups.create!(name: "group", pick_count: 1)
      qgroup1.quiz_questions.create!(quiz:, question_data: { "question_name" => "test group question", "question_type" => "essay_question" })
      qgroup2 = quiz.quiz_groups.create!(name: "group2", pick_count: 1)
      qq2 = qgroup2.quiz_questions.create!(quiz:, question_data: { "question_name" => "test group question", "question_type" => "essay_question" })
      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      qgroup1_to = quiz_to.quiz_groups.where(migration_id: mig_id(qgroup1.asset_string)).first
      qgroup2_to = quiz_to.quiz_groups.where(migration_id: mig_id(qgroup2.asset_string)).first
      qq2_to = quiz_to.quiz_questions.where(migration_id: mig_id(qq2)).first

      qq2_to.update_attribute(:question_data, qq2_to.question_data.merge("question_text" => "something")) # trigger a downstream change on the quiz
      Timecop.freeze(2.minutes.from_now) do
        qgroup1.destroy
      end
      run_master_migration

      expect(quiz_to.reload.quiz_groups.to_a).to match_array([qgroup1_to, qgroup2_to]) # should not have overwritten because downstream changes

      Timecop.freeze(4.minutes.from_now) do
        @template.content_tag_for(quiz).update_attribute(:restrictions, { content: true })
      end
      run_master_migration
      expect(quiz_to.reload.quiz_groups.to_a).to eq [qgroup2_to]
    end

    it "syncs deleted quiz groups linked to question banks after the quiz has been published and submitted" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      student = user_factory(active_all: true)
      @copy_to.enroll_student(student, enrollment_state: "active")

      quiz = @copy_from.quizzes.create!
      bank = @copy_from.assessment_question_banks.create!(title: "Test Bank")
      bank.assessment_questions.create!(question_data: { "name" => "test question", "answers" => [{ "id" => 1 }, { "id" => 2 }] })
      bank.assessment_questions.create!(question_data: { "name" => "test question 2", "answers" => [{ "id" => 3 }, { "id" => 4 }] })
      qgroup1 = quiz.quiz_groups.create!(name: "group", pick_count: 1)
      qgroup1.assessment_question_bank = bank
      qgroup1.save
      @template.content_tag_for(quiz).update_attribute(:restrictions, { content: true })
      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first

      Timecop.freeze(4.minutes.from_now) do
        quiz_to.publish!
        quiz_to.generate_submission(student)
      end

      Timecop.freeze(2.minutes.from_now) do
        qgroup1.destroy
      end
      run_master_migration

      expect(quiz_to.reload.quiz_groups.to_a).to eq []
    end

    it "syncs deleted quiz groups with quiz questions after the quiz has been published and submitted" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      student = user_factory(active_all: true)
      @copy_to.enroll_student(student, enrollment_state: "active")

      quiz = @copy_from.quizzes.create!
      qgroup1 = quiz.quiz_groups.create!(name: "group", pick_count: 1)
      qgroup1.quiz_questions.create!(quiz:, question_data: { "question_name" => "test group question", "question_type" => "essay_question" })
      qgroup1.save
      Timecop.freeze(2.minutes.from_now) do
        @template.content_tag_for(quiz).update_attribute(:restrictions, { content: true })
      end
      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first

      Timecop.freeze(4.minutes.from_now) do
        quiz_to.publish!
        quiz_to.generate_submission(student)
      end

      Timecop.freeze(2.minutes.from_now) do
        qgroup1.destroy
      end
      run_master_migration

      expect(quiz_to.reload.quiz_groups.to_a).to eq []
    end

    it "syncs deleted assessment bank questions (unless changed downstream)" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      bank1 = @copy_from.assessment_question_banks.create!(title: "bank")
      aq1 = bank1.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      aq2 = bank1.assessment_questions.create!(question_data: { "question_name" => "test question2", "question_type" => "essay_question" })
      bank2 = @copy_from.assessment_question_banks.create!(title: "bank")
      aq3 = bank2.assessment_questions.create!(question_data: { "question_name" => "test question3", "question_type" => "essay_question" })
      aq4 = bank2.assessment_questions.create!(question_data: { "question_name" => "test question4", "question_type" => "essay_question" })

      run_master_migration

      bank1_to = @copy_to.assessment_question_banks.where(migration_id: mig_id(bank1)).first
      aq1_to = bank1_to.assessment_questions.where(migration_id: mig_id(aq1)).first
      aq2_to = bank1_to.assessment_questions.where(migration_id: mig_id(aq2)).first
      bank2_to = @copy_to.assessment_question_banks.where(migration_id: mig_id(bank2)).first
      aq3_to = bank2_to.assessment_questions.where(migration_id: mig_id(aq3)).first
      aq4_to = bank2_to.assessment_questions.where(migration_id: mig_id(aq4)).first

      aq1_to.update_attribute(:question_data, aq1_to.question_data.merge("question_text" => "something")) # trigger a downstream change on the bank
      Timecop.freeze(2.minutes.from_now) do
        aq2.destroy
        aq3.destroy
      end

      run_master_migration

      expect(aq2_to.reload).to_not be_deleted # should not have overwritten because downstream changes
      expect(aq3_to.reload).to be_deleted # should be because no downstream changes
      expect(aq4_to.reload).to_not be_deleted # should have been left alone
    end

    it "preserves all answer ids on re-copy" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      q = @copy_from.quizzes.create!(title: "q")
      datas = [
        multiple_choice_question_data,
        true_false_question_data,
        short_answer_question_data,
        calculated_question_data,
        numerical_question_data,
        multiple_answers_question_data,
        multiple_dropdowns_question_data,
        matching_question_data
      ]
      datas.each { |d| q.quiz_questions.create!(question_data: d) }

      run_master_migration

      q_to = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      copied_answers = q_to.quiz_questions.to_a.to_h { |qq| [qq.id, qq.question_data.to_hash["answers"]] }
      expect(copied_answers.values.flatten.all? { |a| a["id"] != 0 }).to be_truthy
      q.quiz_questions.each do |qq|
        qq_to = q_to.quiz_questions.where(migration_id: mig_id(qq)).first
        expect(copied_answers[qq_to.id].map { |a| a["id"].to_i }).to eq(qq.question_data["answers"].map { |a| a["id"].to_i })
      end

      Quizzes::Quiz.where(id: q).update_all(updated_at: 1.minute.from_now) # recopy
      run_master_migration

      q_to.reload.quiz_questions.to_a.each do |qq_to|
        expect(copied_answers[qq_to.id]).to eq qq_to.question_data.to_hash["answers"] # should be unchanged
      end
    end

    it "syncs quiz group attributes (unless changed downstream)" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qgroup = quiz.quiz_groups.create!(name: "group", pick_count: 1)
      qgroup.quiz_questions.create!(quiz:, question_data: { "question_name" => "test group question", "question_type" => "essay_question" })
      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      qgroup_to = quiz_to.quiz_groups.where(migration_id: mig_id(qgroup.asset_string)).first
      qgroup_to.update_attribute(:name, "downstream") # should mark it as a downstream change
      Timecop.freeze(2.minutes.from_now) do
        qgroup.update_attribute(:name, "upstream")
        @new_qq = quiz.quiz_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      end
      run_master_migration

      expect(qgroup_to.reload.name).to eq "downstream"
      expect(quiz_to.reload.quiz_questions.where(migration_id: mig_id(@new_qq)).first).to be_nil

      Timecop.freeze(4.minutes.from_now) do
        @template.content_tag_for(quiz).update_attribute(:restrictions, { content: true })
      end
      run_master_migration

      expect(qgroup_to.reload.name).to eq "upstream"
      # adding new questions was borking because a method i didn't think would ever get called was getting called >.<
      expect(quiz_to.reload.quiz_questions.where(migration_id: mig_id(@new_qq)).first).to_not be_nil
    end

    it "creates submissions for assignments without due dates on initial sync" do
      course_with_student(active_all: true)
      @copy_to = @course
      @template.add_child_course!(@copy_to)

      assmt = @copy_from.assignments.create!(title: "assmt")
      run_master_migration

      assmt_to = @copy_to.assignments.where(migration_id: mig_id(assmt)).first
      expect(assmt_to.submissions.where(user_id: @student)).to be_exists
    end

    it "does not delete an assignment group if it's not empty downstream" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      ag1 = @copy_from.assignment_groups.create!(name: "group1")
      @copy_from.assignments.create!(title: "assmt1", assignment_group: ag1)
      ag2 = @copy_from.assignment_groups.create!(name: "group2")
      @copy_from.assignments.create!(title: "assmt2", assignment_group: ag2)
      ag3 = @copy_from.assignment_groups.create!(name: "group3")
      @copy_from.assignments.create!(title: "assmt3", assignment_group: ag3)

      run_master_migration

      ag1_to = @copy_to.assignment_groups.where(migration_id: mig_id(ag1)).first
      a1_to = ag1_to.assignments.first
      ag2_to = @copy_to.assignment_groups.where(migration_id: mig_id(ag2)).first
      a2_to = ag2_to.assignments.first
      ag3_to = @copy_to.assignment_groups.where(migration_id: mig_id(ag3)).first
      a3_to = ag3_to.assignments.first

      Timecop.freeze(30.seconds.from_now) do
        [ag1, ag2, ag3].each(&:destroy!)
        a2_to.update_attribute(:name, "some other downstream name")
        @new_assmt = @copy_to.assignments.create!(title: "a new assignment created downstream", assignment_group: ag3_to)
      end

      run_master_migration

      expect(ag1_to.reload).to be_deleted # should still delete
      expect(a1_to.reload).to be_deleted
      expect(ag2_to.reload).to_not be_deleted # should skip deletion because a2's deletion was skipped
      expect(a2_to.reload).to_not be_deleted
      expect(ag3_to.reload).to_not be_deleted # should skip deletion because of @new_assmt
      expect(a3_to.reload).to be_deleted # but should have still deleted the assigment
      expect(@new_assmt.reload).to_not be_deleted
    end

    it "deletes an assignment group when all assignments are moved out in the same sync" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      ag1 = @copy_from.assignment_groups.create!(name: "group1")
      @copy_from.assignments.create!(title: "assmt1", assignment_group: ag1)
      ag2 = @copy_from.assignment_groups.create!(name: "group2")
      a2 = @copy_from.assignments.create!(title: "assmt2", assignment_group: ag2)

      run_master_migration

      ag1_to = @copy_to.assignment_groups.where(migration_id: mig_id(ag1)).first
      ag2_to = @copy_to.assignment_groups.where(migration_id: mig_id(ag2)).first
      a2_to = ag2_to.assignments.first

      Timecop.freeze(30.seconds.from_now) do
        a2.update_attribute(:assignment_group, ag1)
        ag2.reload.destroy
      end

      run_master_migration

      expect(ag2_to.reload).to be_deleted # should still delete
      expect(a2_to.reload.assignment_group).to eq ag1_to
      expect(a2_to).to be_active
    end

    it "does not import into a deleted downstream assignment group" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      ag1 = @copy_from.assignment_groups.create!(name: "group1")
      @copy_from.assignments.create!(title: "assmt1", assignment_group: ag1)

      run_master_migration

      ag1_to = @copy_to.assignment_groups.where(migration_id: mig_id(ag1)).first
      ag1_to.destroy

      Timecop.freeze(30.seconds.from_now) do
        @a2 = @copy_from.assignments.create!(title: "assmt2", assignment_group: ag1)
      end

      run_master_migration

      a2_to = @copy_to.assignments.where(migration_id: mig_id(@a2)).first
      expect(a2_to.assignment_group).to be_available
    end

    it "does not change assignment group weights and rules if changed downstream" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      ag1 = @copy_from.assignment_groups.create!(name: "group1", group_weight: 50)
      a1 = @copy_from.assignments.create!(title: "assmt1", assignment_group: ag1)
      ag1.update_attribute(:rules, "drop_lowest:1\nnever_drop:#{a1.id}\n")

      run_master_migration

      ag1_to = @copy_to.assignment_groups.where(migration_id: mig_id(ag1)).first
      a1_to = ag1_to.assignments.first
      expect(ag1_to.group_weight).to eq 50
      expect(ag1_to.rules).to eq "drop_lowest:1\nnever_drop:#{a1_to.id}\n"

      # check that syncs still work before we change downstream
      Timecop.freeze(30.seconds.from_now) do
        ag1.update(rules: "drop_lowest:2\n", group_weight: 75)
      end
      run_master_migration
      expect(ag1_to.reload.group_weight).to eq 75
      expect(ag1_to.rules).to eq "drop_lowest:2\n"

      # change downstream
      Timecop.freeze(30.seconds.from_now) do
        ag1.touch
        ag1_to.update(rules: "drop_lowest:3\n", group_weight: 25)
      end
      run_master_migration
      expect(ag1_to.reload.group_weight).to eq 25 # should not have reverted from downstream change
      expect(ag1_to.rules).to eq "drop_lowest:3\n"
    end

    it "doesn't overwrite weights and rules of an assignment group with a similar name on initial sync" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      ag1 = @copy_from.assignment_groups.create!(name: "group1", group_weight: 50)
      a1 = @copy_from.assignments.create!(title: "assmt1", assignment_group: ag1)
      ag1.update_attribute(:rules, "drop_lowest:1\nnever_drop:#{a1.id}\n")

      ag1_assimilation_target = @copy_to.assignment_groups.create!(name: "group1", group_weight: 33)
      ag1_assimilation_target.update_attribute(:rules, "drop_highest:1\n")

      run_master_migration

      ag1_to = @copy_to.assignment_groups.where(migration_id: mig_id(ag1)).first
      expect(ag1_to).to eq ag1_assimilation_target
      expect(ag1_to.group_weight).to eq 33
      expect(ag1_to.rules).to eq "drop_highest:1\n"
      a1_to = ag1_to.assignments.first
      expect(a1_to).to be
    end

    it "syncs unpublished quiz points possible" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!(workflow_state: "unpublished")
      qq = quiz.quiz_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question", "points_possible" => 1 })
      quiz.root_entries(true)
      quiz.save!

      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      expect(quiz_to.points_possible).to eq 1
      qq_to = quiz_to.quiz_questions.where(migration_id: mig_id(qq)).first

      Timecop.freeze(2.minutes.from_now) do
        qq.update_attribute(:question_data, qq.question_data.merge(points_possible: 2))
        quiz.root_entries(true)
        quiz.save!
        expect(quiz.points_possible).to eq 2
      end

      run_master_migration

      expect(qq_to.reload.question_data["points_possible"]).to eq 2
      expect(quiz_to.reload.points_possible).to eq 2
    end

    it "tracks creations and updates in selective migrations" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      assmt = @copy_from.assignments.create!
      @copy_from.discussion_topics.create!(message: "hi", title: "discussion title")
      page = nil
      file = nil

      run_master_migration

      Timecop.freeze(10.minutes.from_now) do
        assmt.update_attribute(:title, "new title eh")
        page = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai")
        file = @copy_from.attachments.create!(filename: "blah", uploaded_data: default_uploaded_data)
      end

      Timecop.travel(20.minutes.from_now) do
        mm = run_master_migration
        expect(mm.export_results[:selective][:created]["WikiPage"]).to eq([mig_id(page)])
        expect(mm.export_results[:selective][:created]["Attachment"]).to eq([mig_id(file)])
        expect(mm.export_results[:selective][:updated]["Assignment"]).to eq([mig_id(assmt)])
      end
    end

    it "doesn't restore deleted associated content unless relocked" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      page1 = @copy_from.wiki_pages.create!(title: "whee")
      page2 = @copy_from.wiki_pages.create!(title: "whoo")
      quiz = @copy_from.quizzes.create!(title: "what")
      run_master_migration

      page1_to = @copy_to.wiki_pages.where(migration_id: mig_id(page1)).first
      page1_to.destroy # "manually" delete it
      page2_to = @copy_to.wiki_pages.where(migration_id: mig_id(page2)).first
      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      quiz_to.destroy

      Timecop.freeze(3.minutes.from_now) do
        page1.update_attribute(:title, "new title eh")
        page2.destroy
        quiz.update_attribute(:title, "new title wat")
      end
      run_master_migration

      expect(page1_to.reload).to be_deleted # shouldn't have restored it
      expect(page2_to.reload).to be_deleted # should still sync the original deletion
      expect(quiz_to.reload).to be_deleted # shouldn't have restored it neither

      Timecop.freeze(5.minutes.from_now) do
        page1.update_attribute(:title, "another new title srsly")
        @template.content_tag_for(page1).update_attribute(:restrictions, { content: true }) # lock it down
        page2.update_attribute(:workflow_state, "active") # restore the original
        quiz.update_attribute(:title, "another new title frd pdq")
        @template.content_tag_for(quiz).update_attribute(:restrictions, { content: true }) # lock it down
      end
      run_master_migration

      expect(page1_to.reload).to be_active # should be restored because it's locked now
      expect(page2_to.reload).to be_active # should be restored because it hadn't been deleted manually
      expect(quiz_to.reload).not_to be_deleted # should be restored because it's locked now
    end

    it "doesn't undelete modules that were deleted downstream" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      mod = @copy_from.context_modules.create! name: "teh"
      run_master_migration

      mod_to = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
      mod_to.destroy

      Timecop.freeze(3.minutes.from_now) do
        mod.touch
      end
      run_master_migration

      expect(mod_to.reload).to be_deleted
    end

    describe "outcomes and groups" do
      before :once do
        @copy_to = course_factory
        @template.add_child_course!(@copy_to)

        root = @copy_from.root_outcome_group
        @og = @copy_from.learning_outcome_groups.create!({ title: "outcome group" })
        root.adopt_outcome_group(@og)
        @outcome = @copy_from.created_learning_outcomes.create!({ title: "new outcome" })
        @og.add_outcome(@outcome)
        run_master_migration

        @outcome_to = @copy_to.learning_outcomes.where(migration_id: mig_id(@outcome)).first
        @og_to = @copy_to.learning_outcome_groups.where(migration_id: mig_id(@og)).first
      end

      it "doesn't undelete learning outcomes and outcome groups that were deleted downstream" do
        @outcome_to.destroy
        @og_to.destroy

        Timecop.freeze(3.minutes.from_now) do
          @og.touch
          @outcome.touch
        end
        run_master_migration

        expect(@outcome_to.reload).to be_deleted
        expect(@og_to.reload).to be_deleted
      end

      it "doesn't resurrect links to deleted outcomes" do
        @outcome_to.destroy

        Timecop.freeze(3.minutes.from_now) do
          @og.touch
          @outcome.touch
        end
        run_master_migration

        expect(@outcome_to.reload).to be_deleted
        expect(@og_to.child_outcome_links.not_deleted.where(content_type: "LearningOutcome", content_id: @outcome_to)).not_to be_any
      end

      it "doesn't spuriously add the outcome to the root outcome group" do
        Timecop.freeze(3.minutes.from_now) do
          @outcome.touch
        end
        run_master_migration

        expect(@copy_to.learning_outcome_links.where(content: @outcome_to).count).to eq 1
      end
    end

    it "copies links to account outcomes on rubrics" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      run_master_migration

      account = @copy_from.account
      account.root_outcome_group
      lo = account.created_learning_outcomes.create!({ title: "new outcome" })

      root = @copy_from.root_outcome_group
      log = @copy_from.learning_outcome_groups.create!(title: "some group")
      root.adopt_outcome_group(log)
      tag = log.add_outcome(lo)

      # don't automatically link in selective content but should still get copied because the rubric is copied
      ContentTag.where(id: tag).update_all(updated_at: 5.minutes.ago)

      rub = Rubric.new(context: @copy_from)
      rub.data = [
        {
          points: 3,
          description: "Outcome row",
          id: 1,
          ratings: [{ points: 3, description: "Rockin'", criterion_id: 1, id: 2 }],
          learning_outcome_id: lo.id
        }
      ]
      rub.save!
      rub.associate_with(@copy_from, @copy_from)
      Rubric.where(id: rub.id).update_all(updated_at: 5.minutes.from_now)

      run_master_migration

      rub_to = @copy_to.rubrics.first
      expect(rub_to.data.first["learning_outcome_id"]).to eq lo.id
    end

    it "copies links to account outcomes in imported groups on rubrics" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      account = @copy_from.account
      a_group = account.root_outcome_group
      lo = account.created_learning_outcomes.create!({ title: "new outcome" })
      a_group.add_outcome(lo)

      root = @copy_from.root_outcome_group
      root.add_outcome_group(a_group) # add the group - not the outcome

      run_master_migration

      rub = Rubric.new(context: @copy_from)
      rub.data = [
        {
          points: 3,
          description: "Outcome row",
          id: 1,
          ratings: [{ points: 3, description: "Rockin'", criterion_id: 1, id: 2 }],
          learning_outcome_id: lo.id
        }
      ]
      rub.save!
      rub.associate_with(@copy_from, @copy_from)
      Rubric.where(id: rub.id).update_all(updated_at: 5.minutes.from_now)

      run_master_migration

      rub_to = @copy_to.rubrics.first
      expect(rub_to.data.first["learning_outcome_id"]).to eq lo.id
    end

    it "doesn't restore deleted associated files unless relocked" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      att1 = Attachment.create!(filename: "file1.txt",
                                uploaded_data: StringIO.new("1"),
                                folder: Folder.root_folders(@copy_from).first,
                                context: @copy_from)
      att2 = Attachment.create!(filename: "file2.txt",
                                uploaded_data: StringIO.new("2"),
                                folder: Folder.root_folders(@copy_from).first,
                                context: @copy_from)

      run_master_migration

      att1_to = @copy_to.attachments.where(migration_id: mig_id(att1)).first
      att1_to.destroy # "manually" delete it
      att2_to = @copy_to.attachments.where(migration_id: mig_id(att2)).first

      Timecop.freeze(3.minutes.from_now) do
        att1.touch
        att2.destroy
      end
      run_master_migration

      expect(att1_to.reload).to be_deleted # shouldn't have restored it
      expect(att2_to.reload).to be_deleted # should still sync the original deletion

      Timecop.freeze(5.minutes.from_now) do
        att1.touch
        @template.content_tag_for(att1).update_attribute(:restrictions, { content: true }) # lock it down

        att2.update_attribute(:file_state, "available") # restore the original
      end
      run_master_migration

      expect(att1_to.reload).to be_available # should be restored because it's locked now
      expect(att2_to.reload).to be_available # should be restored because it hadn't been deleted manually
    end

    it "doesn't sync new files into an old deleted folder with the same name" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      @root_folder = Folder.root_folders(@copy_from).first
      @folder_to_delete = @root_folder.sub_folders.create!(name: "nowyouseeme", context: @copy_from)
      @att1 = Attachment.create!(filename: "file1.txt",
                                 uploaded_data: StringIO.new("1"),
                                 folder: @folder_to_delete,
                                 context: @copy_from)

      run_master_migration
      @att1_to = @copy_to.attachments.where(migration_id: mig_id(@att1)).first
      expect(@att1_to).to be_present

      Timecop.freeze(1.minute.from_now) do
        @att1.update_attribute(:folder, @root_folder)
        @folder_to_delete.destroy
        @replacement_folder = @root_folder.sub_folders.create!(name: "nowyouseeme", context: @copy_from)
        @att1.update_attribute(:folder, @replacement_folder)
      end
      run_master_migration

      @att1_to.reload
      expect(@att1_to).to_not be_deleted
      expect(@att1_to.folder).to_not be_deleted
    end

    context "media_links_use_attachment_id feature flag off" do
      before do
        Account.site_admin.disable_feature!(:media_links_use_attachment_id)
      end

      it "does not copy media tracks" do
        @copy_to = course_factory
        @template.add_child_course!(@copy_to)

        media_id = "m-you_know_what_you_did"
        media_object = @copy_from.media_objects.create!(title: "video.mp4", media_id:)
        media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs")

        run_master_migration

        att_to = @copy_to.attachments.where(migration_id: mig_id(media_object.attachment)).first
        expect(att_to.media_entry_id).to eq media_id
        expect(att_to.media_tracks).to be_empty
      end
    end

    it "copies media tracks" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      media_id = "m-you_know_what_you_did"
      media_object = @copy_from.media_objects.create!(title: "video.mp4", media_id:)
      copy_from_track = media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs")

      run_master_migration

      att_to = @copy_to.attachments.where(migration_id: mig_id(media_object.attachment)).first
      expect(att_to.media_tracks.length).to eq 1
      expect(att_to.media_entry_id).to eq media_id
      copy_to_track = att_to.media_tracks.first
      expect(copy_to_track.id).not_to eq copy_from_track.id
      expect(copy_to_track.slice(:locale, :content)).to match({ locale: "en", content: "en subs" })
    end

    it "overwrites media tracks with new parent changes" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      media_id = "m-you_know_what_you_did"
      media_object = @copy_from.media_objects.create!(title: "video.mp4", media_id:)
      copy_from_track = media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs")

      run_master_migration

      att_to = @copy_to.attachments.where(migration_id: mig_id(media_object.attachment)).first
      copy_to_track = att_to.media_tracks.first
      expect(copy_to_track).to be_present

      Timecop.freeze(1.minute.from_now) do
        copy_from_track.destroy
        media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "orig subs")
      end
      run_master_migration

      expect(att_to.reload.media_tracks.length).to eq 1
      copy_to_track = att_to.media_tracks.first
      expect(copy_to_track.content).to eq "orig subs"
    end

    it "doesn't overwrite media tracks with downstream changes" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      media_id = "m-you_know_what_you_did"
      media_object = @copy_from.media_objects.create!(title: "video.mp4", media_id:)
      copy_from_track = media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs")

      run_master_migration

      att_to = @copy_to.attachments.where(migration_id: mig_id(media_object.attachment)).first
      copy_to_track = att_to.media_tracks.first
      expect(copy_to_track).to be_present

      Timecop.freeze(1.minute.from_now) do
        copy_to_track.destroy
        att_to.media_tracks.create!(kind: "subtitles", locale: "en", content: "new subs")
        copy_from_track.destroy
        media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "orig subs")
      end
      run_master_migration

      expect(att_to.media_tracks.length).to eq 1
      copy_to_track = att_to.media_tracks.first
      expect(copy_to_track.content).to eq "new subs"
    end

    it "overwrites media tracks with downstream changes if the attachment has been updated" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      media_id = "m-you_know_what_you_did"
      media_object = @copy_from.media_objects.create!(title: "video.mp4", media_id:)
      media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs")

      run_master_migration

      att_to = @copy_to.attachments.where(migration_id: mig_id(media_object.attachment)).first
      copy_to_track = att_to.media_tracks.first
      expect(copy_to_track).to be_present

      Timecop.freeze(1.minute.from_now) do
        copy_to_track.destroy
        att_to.media_tracks.create!(kind: "subtitles", locale: "en", content: "new subs")
        @new_att = @copy_from.attachments.create!(filename: "video.mp4", uploaded_data: StringIO.new("ohai"), folder: media_object.attachment.folder, media_entry_id: media_id)
        @new_att.handle_duplicates(:overwrite)
        @new_att.media_tracks.create!(kind: "subtitles", locale: "en", content: "orig subs")
      end
      run_master_migration

      expect(@new_att.media_tracks.length).to eq 1
      copy_to_track = @new_att.media_tracks.first
      expect(copy_to_track.content).to eq "orig subs"
    end

    it "overwrites media tracks when pushing a locked attachment" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      media_id = "m-you_know_what_you_did"
      media_object = @copy_from.media_objects.create!(title: "video.mp4", media_id:)
      media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "orig subs")
      att_from = media_object.attachment

      run_master_migration

      att_to = @copy_to.attachments.where(migration_id: mig_id(media_object.attachment)).first
      copy_to_track = att_to.media_tracks.first
      expect(copy_to_track).to be_present

      Timecop.freeze(1.minute.from_now) do
        copy_to_track.destroy
        att_to.media_tracks.create!(kind: "subtitles", locale: "en", content: "new subs")
        att_to.media_tracks.create!(kind: "subtitles", locale: "fr", content: "fr subs")
      end

      @template.content_tag_for(att_from).update(restrictions: { content: true }) # should touch the content
      run_master_migration

      expect(att_to.media_tracks.length).to eq 1
      copy_to_track = att_to.media_tracks.first
      expect(copy_to_track.content).to eq "orig subs"
    end

    it "limits the number of items to track" do
      Setting.set("master_courses_history_count", "2")

      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      run_master_migration

      Timecop.travel(10.minutes.from_now) do
        3.times { |x| @copy_from.wiki_pages.create! title: "Page #{x}" }
        mm = run_master_migration
        expect(mm.export_results[:selective][:created]["WikiPage"].length).to eq 2
      end
    end

    it "creates two exports (one selective and one full) if needed" do
      @copy_to1 = course_factory
      @template.add_child_course!(@copy_to1)

      topic = @copy_from.discussion_topics.create!(title: "some title")

      run_master_migration
      expect(@migration.export_results.keys).to eq [:full]
      topic_to1 = @copy_to1.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(topic_to1).to be_present
      new_title = "new title"
      topic_to1.update_attribute(:title, new_title)

      page = @copy_from.wiki_pages.create!(title: "another title")

      @copy_to2 = course_factory
      @template.add_child_course!(@copy_to2) # new child course - needs full update

      run_master_migration
      expect(@migration.export_results.keys).to match_array([:selective, :full]) # should create both

      expect(@copy_to1.wiki_pages.where(migration_id: mig_id(page)).first).to be_present # should bring the wiki page in the selective
      expect(topic_to1.reload.title).to eq new_title # should not have have overwritten the new change in the child course

      expect(@copy_to2.discussion_topics.where(migration_id: mig_id(topic)).first).to be_present # should bring both in the full
      expect(@copy_to2.wiki_pages.where(migration_id: mig_id(page)).first).to be_present
    end

    it "skips master course restriction validations on import" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      assmt = @copy_from.assignments.create!
      topic = @copy_from.discussion_topics.create!(message: "hi", title: "discussion title")
      ann = @copy_from.announcements.create!(message: "goodbye")
      page = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai")
      quiz = @copy_from.quizzes.create!
      qq = quiz.quiz_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      aq = bank.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      file = @copy_from.attachments.create!(filename: "blah", uploaded_data: default_uploaded_data)
      event = @copy_from.calendar_events.create!(title: "thing", description: "blargh", start_at: 1.day.from_now)
      tool = @copy_from.context_external_tools.create!(name: "new tool",
                                                       consumer_key: "key",
                                                       shared_secret: "secret",
                                                       custom_fields: { "a" => "1", "b" => "2" },
                                                       url: "http://www.example.com")

      # TODO: make sure that we skip the validations on each importer when we add the Restrictor and
      # probably add more content here
      @template.default_restrictions = { content: true }
      @template.save!

      run_master_migration

      copied_assmt = @copy_to.assignments.where(migration_id: mig_id(assmt)).first
      copied_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      copied_ann = @copy_to.announcements.where(migration_id: mig_id(ann)).first
      copied_page = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      copied_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      copied_qq = copied_quiz.quiz_questions.where(migration_id: mig_id(qq)).first
      copied_bank = @copy_to.assessment_question_banks.where(migration_id: mig_id(bank)).first
      copied_aq = copied_bank.assessment_questions.where(migration_id: mig_id(aq)).first
      copied_file = @copy_to.attachments.where(migration_id: mig_id(file)).first
      copied_event = @copy_to.calendar_events.where(migration_id: mig_id(event)).first
      copied_tool = @copy_to.context_external_tools.where(migration_id: mig_id(tool)).first

      copied_things = [copied_assmt,
                       copied_topic,
                       copied_ann,
                       copied_page,
                       copied_quiz,
                       copied_bank,
                       copied_file,
                       copied_event,
                       copied_tool]
      copied_things.each do |copy|
        expect(MasterCourses::ChildContentTag.where(content: copy).first.migration_id).to eq copy.migration_id
      end

      new_text = "<p>some text here</p>"
      assmt.update_attribute(:description, new_text)
      topic.update_attribute(:message, new_text)
      ann.update_attribute(:message, new_text)
      page.update_attribute(:body, new_text)
      quiz.update_attribute(:description, new_text)
      event.update_attribute(:description, new_text)

      plain_text = "plain text"
      qq.question_data = qq.question_data.tap { |qd| qd["question_text"] = plain_text }
      qq.save!
      bank.update_attribute(:title, plain_text)
      aq.question_data["question_text"] = plain_text
      aq.save!
      file.update_attribute(:display_name, plain_text)
      tool.update_attribute(:name, plain_text)

      [assmt, topic, ann, page, quiz, bank, file, event, tool].each { |c| c.class.where(id: c).update_all(updated_at: 2.seconds.from_now) } # ensure it gets copied

      run_master_migration # re-copy all the content and overwrite the locked stuff

      expect(copied_assmt.reload.description).to eq new_text
      expect(copied_topic.reload.message).to eq new_text
      expect(copied_ann.reload.message).to eq new_text
      expect(copied_page.reload.body).to eq new_text
      expect(copied_quiz.reload.description).to eq new_text
      expect(copied_qq.reload.question_data["question_text"]).to eq plain_text
      expect(copied_bank.reload.title).to eq plain_text
      expect(copied_aq.reload.question_data["question_text"]).to eq plain_text
      expect(copied_file.reload.display_name).to eq plain_text
      expect(copied_event.reload.description).to eq new_text
      expect(copied_tool.reload.name).to eq plain_text
    end

    it "does not overwrite downstream changes in child course unless locked" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      # TODO: add more content here as we add the Restrictor module to more models
      old_title = "some title"
      page = @copy_from.wiki_pages.create!(title: old_title, body: "ohai")
      assignment = @copy_from.assignments.create!(title: old_title, description: "kthnx")

      run_master_migration

      # WikiPage
      copied_page = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      child_tag = sub.child_content_tags.where(content: copied_page).first
      expect(child_tag).to be_present # should create a tag
      new_child_text = "<p>some other text here</p>"
      copied_page.update_attribute(:body, new_child_text)
      child_tag.reload
      expect(child_tag.downstream_changes).to include("body")

      new_master_text = "<p>some text or something</p>"
      page.update_attribute(:body, new_master_text)
      new_master_title = "some new title"
      page.update_attribute(:title, new_master_title)

      # Assignment
      copied_assignment = @copy_to.assignments.where(migration_id: mig_id(assignment)).first
      child_tag = sub.child_content_tags.where(content: copied_assignment).first
      expect(child_tag).to be_present # should create a tag
      new_child_text = "<p>some other text here</p>"
      copied_assignment.update_attribute(:description, new_child_text)
      child_tag.reload
      expect(child_tag.downstream_changes).to include("description")

      new_master_text = "<p>some text or something</p>"
      assignment.update_attribute(:description, new_master_text)
      new_master_title = "some new title"
      assignment.update_attribute(:title, new_master_title)

      # Ensure each object gets marked for copy
      [page, assignment].each { |c| c.class.where(id: c).update_all(updated_at: 2.seconds.from_now) }

      run_master_migration # re-copy all the content but don't actually overwrite the downstream change
      expect(@migration.migration_results.first.skipped_items).to match_array([mig_id(assignment), mig_id(page)])

      expect(copied_page.reload.body).to eq new_child_text # should have been left alone
      expect(copied_page.title).to eq old_title # even the title

      expect(copied_assignment.reload.description).to eq new_child_text # should have been left alone
      expect(copied_assignment.title).to eq old_title # even the title

      [page, assignment].each do |c|
        mtag = @template.content_tag_for(c)
        Timecop.freeze(2.seconds.from_now) do
          mtag.update_attribute(:restrictions, { content: true }) # should touch the content
        end
      end

      run_master_migration # re-copy all the content but this time overwrite the downstream change because we locked it
      expect(@migration.migration_results.first.skipped_items).to be_empty

      expect(copied_assignment.reload.description).to eq new_master_text
      expect(copied_assignment.title).to eq new_master_title
      expect(copied_page.reload.body).to eq new_master_text
      expect(copied_page.title).to eq new_master_title # even the title
    end

    it "updates links correctly when creating an assignment and moving a file" do
      @copy_to = course_factory

      @template.add_child_course!(@copy_to)

      folder1 = @copy_from.folders.create!(name: "folder1")
      folder2 = folder1.sub_folders.create!(name: "folder2", context: @copy_from)
      folder3 = folder2.sub_folders.create!(name: "folder3", context: @copy_from)
      attachment = folder3.file_attachments.build
      attachment.context = @copy_from
      attachment.uploaded_data = default_uploaded_data
      attachment.display_name = "lalala"
      attachment.save!

      expect(@copy_to.folders.where(name: "folder 1").first).to be_nil

      run_master_migration

      folder3.parent_folder = folder1
      folder3.save!

      assignment = @copy_from.assignments.create!(title: "hahaha")
      assignment.description = "<p><a id=\"\" class=\"instructure_file_link instructure_image_thumbnail \" title=\"lalala\" href=\"/courses/#{@copy_from.id}/files/#{attachment.id}/download?wrap=1\" target=\"\">lalala</a></p>"
      assignment.save!

      run_master_migration

      @copy_to.reload
      copy_attachment = @copy_to.attachments.first
      copy_assignments = @copy_to.assignments.all
      expect(copy_assignments.length).to eq 1
      copy_assignment = copy_assignments[0]
      expect(copy_assignment.title).to eq "hahaha"
      expect(copy_assignment.description).to eq "<p><a id=\"\" class=\"instructure_file_link instructure_image_thumbnail \" title=\"lalala\" href=\"/courses/#{@copy_to.id}/files/#{copy_attachment.id}/download?wrap=1\" target=\"\">lalala</a></p>"
    end

    it "removing an assignment from one module to another and deleting module should not make assignments disappear" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      from_module_1 = @copy_from.context_modules.create!(name: "module 1 yo")
      from_assignment_1 = @copy_from.assignments.create!(title: "assignment 1 yo")
      from_module_1.add_item({ id: from_assignment_1.id, type: "assignment", indent: 1 })
      from_module_1.save!
      from_module_2 = @copy_from.context_modules.create!(name: "module 2 B")
      from_assignment_2 = @copy_from.assignments.create!(title: "assignment 2 B")
      from_tag_2 = from_module_2.add_item({ id: from_assignment_2.id, type: "assignment", indent: 1 })
      from_module_2.save!

      run_master_migration
      @copy_to.reload
      expect(@copy_to.active_assignments.count).to eq 2
      to_assignment_1 = @copy_to.assignments.where(title: "assignment 1 yo").first!
      to_assignment_2 = @copy_to.assignments.where(title: "assignment 2 B").first!
      expect(@copy_to.active_context_modules.count).to eq 2
      expect(@copy_to.active_context_modules.where(name: "module 1 yo").first!.content_tags.active.map { |tag| tag.content.id }).to eq [to_assignment_1.id]
      expect(@copy_to.active_context_modules.where(name: "module 2 B").first!.content_tags.active.map { |tag| tag.content.id }).to eq [to_assignment_2.id]

      from_tag_2.position = 2
      from_tag_2.context_module_id = from_module_1.id
      from_tag_2.save!
      from_module_1.touch
      from_module_2.touch

      run_master_migration
      @copy_to.reload
      expect(@copy_to.active_assignments.count).to eq 2
      expect(@copy_to.active_context_modules.count).to eq 2
      expect(@copy_to.active_context_modules.where(name: "module 1 yo").first!.content_tags.active.map { |tag| tag.content.id }).to eq [to_assignment_1.id, to_assignment_2.id]

      from_tag_2.position = 1
      from_tag_2.context_module_id = from_module_2.id
      from_tag_2.save!
      from_module_1.touch
      from_module_2.touch

      run_master_migration
      @copy_to.reload
      expect(@copy_to.active_assignments.count).to eq 2
      expect(@copy_to.active_context_modules.count).to eq 2
      expect(@copy_to.active_context_modules.where(name: "module 1 yo").first!.content_tags.active.map { |tag| tag.content.id }).to eq [to_assignment_1.id]
      expect(@copy_to.active_context_modules.where(name: "module 2 B").first!.content_tags.active.map { |tag| tag.content.id }).to eq [to_assignment_2.id]
    end

    it "does not restore content tags in a deleted module" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      mod = @copy_from.context_modules.create!(name: "module")
      assmt = @copy_from.assignments.create!(title: "assignment")
      tag = mod.add_item({ id: assmt.id, type: "assignment" })

      run_master_migration

      tag_to = @copy_to.context_module_tags.first
      mod_to = @copy_to.context_modules.first
      mod_to.destroy
      expect(tag_to.reload).to be_deleted

      Timecop.freeze(1.minute.from_now) do
        [mod, assmt, tag].each(&:touch) # re-migrate everything
      end

      run_master_migration

      expect(mod_to.reload).to be_deleted
      expect(tag_to.reload).to be_deleted
    end

    it "overwrites/removes availability dates and settings when pushing a locked quiz" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      dates1 = [1.day.ago, 1.day.from_now, 2.days.from_now].map(&:beginning_of_day)
      dates2 = [2.days.ago, 3.days.from_now, 5.days.from_now].map(&:beginning_of_day)

      quiz1 = @copy_from.quizzes.create!(unlock_at: dates1[0], due_at: dates1[1], lock_at: dates1[2])
      quiz2 = @copy_from.quizzes.create!
      run_master_migration

      cq1 = @copy_to.quizzes.where(migration_id: mig_id(quiz1)).first
      cq2 = @copy_to.quizzes.where(migration_id: mig_id(quiz2)).first

      Timecop.travel(5.minutes.from_now) do
        cq1.update(unlock_at: dates2[0], due_at: dates2[1], lock_at: dates2[2])
        cq2.update(unlock_at: dates2[0], due_at: dates2[1], lock_at: dates2[2], ip_filter: "10.0.0.1/24", hide_correct_answers_at: 1.week.from_now)
      end

      Timecop.travel(10.minutes.from_now) do
        @template.content_tag_for(quiz1).update_attribute(:restrictions, { availability_dates: true, due_dates: true })
        @template.content_tag_for(quiz2).update_attribute(:restrictions, { availability_dates: true, due_dates: true, settings: true })

        run_master_migration
      end

      cq1.reload
      expect(cq1.due_at).to eq dates1[1]
      expect(cq1.unlock_at).to eq dates1[0]
      expect(cq1.lock_at).to eq dates1[2]

      cq2.reload
      expect(cq2.due_at).to be_nil
      expect(cq2.unlock_at).to be_nil
      expect(cq2.lock_at).to be_nil
      expect(cq2.ip_filter).to be_nil
      expect(cq2.hide_correct_answers_at).to be_nil
    end

    it "removes due/available dates from locked assignments in sync" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      assmt = @copy_from.assignments.create!(due_at: 1.day.from_now, unlock_at: 1.day.ago, lock_at: 1.day.from_now)
      run_master_migration

      assmt_to = @copy_to.assignments.where(migration_id: mig_id(assmt)).first
      expect(assmt_to.due_at).not_to be_nil

      Timecop.travel(5.minutes.from_now) do
        @template.content_tag_for(assmt).update_attribute(:restrictions, { availability_dates: true, due_dates: true })
        assmt.update(due_at: nil, unlock_at: nil, lock_at: nil)
      end

      Timecop.travel(10.minutes.from_now) do
        run_master_migration
      end

      assmt_to.reload
      expect(assmt_to.due_at).to be_nil
      expect(assmt_to.lock_at).to be_nil
      expect(assmt_to.unlock_at).to be_nil
    end

    it "counts downstream changes to quiz/assessment questions as changes in quiz/bank content" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qq = quiz.quiz_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      aq = bank.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })

      run_master_migration

      copied_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      copied_qq = copied_quiz.quiz_questions.where(migration_id: mig_id(qq)).first
      copied_bank = @copy_to.assessment_question_banks.where(migration_id: mig_id(bank)).first
      copied_aq = copied_bank.assessment_questions.where(migration_id: mig_id(aq)).first

      new_child_text = "some childish text"
      copied_aq.question_data["question_text"] = new_child_text
      copied_aq.save!
      copied_qd = copied_qq.question_data
      copied_qd["question_text"] = new_child_text
      copied_qq.question_data = copied_qd
      copied_qq.save!

      bank_child_tag = sub.child_content_tags.where(content: copied_bank).first
      expect(bank_child_tag.downstream_changes).to include("assessment_questions_content") # treats all assessment questions like a column
      quiz_child_tag = sub.child_content_tags.where(content: copied_quiz).first
      expect(quiz_child_tag.downstream_changes).to include("quiz_questions_content") # treats all assessment questions like a column

      new_master_text = "some mastery text"
      bank.update_attribute(:title, new_master_text)
      aq.question_data["question_text"] = new_master_text
      aq.save!
      quiz.update_attribute(:title, new_master_text)
      qd = qq.question_data
      qd["question_text"] = new_master_text
      qq.question_data = qd
      qq.save!

      [bank, quiz].each { |c| c.class.where(id: c).update_all(updated_at: 2.seconds.from_now) } # ensure it gets copied

      run_master_migration # re-copy all the content - but don't actually overwrite anything because it got changed downstream

      expect(copied_bank.reload.title).to_not eq new_master_text
      expect(copied_aq.reload.question_data["question_text"]).to_not eq new_master_text
      expect(copied_quiz.reload.title).to_not eq new_master_text
      expect(copied_qq.reload.question_data["question_text"]).to_not eq new_master_text

      [bank, quiz].each do |c|
        mtag = @template.content_tag_for(c)
        Timecop.freeze(2.seconds.from_now) do
          mtag.update_attribute(:restrictions, { content: true }) # should touch the content
        end
      end

      run_master_migration # re-copy all the content - and this time overwrite everything because it's locked

      expect(copied_bank.reload.title).to eq new_master_text
      expect(copied_aq.reload.question_data["question_text"]).to eq new_master_text
      expect(copied_quiz.reload.title).to eq new_master_text
      expect(copied_qq.reload.question_data["question_text"]).to eq new_master_text
    end

    it "records a sync exception when downstream question data changes" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qq = quiz.quiz_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })

      run_master_migration

      qd = qq.question_data
      qd["question_text"] = "foo"
      qq.question_data = qd
      qq.save!

      copied_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      copied_qq = copied_quiz.quiz_questions.where(migration_id: mig_id(qq)).first
      copied_qd = copied_qq.question_data
      copied_qd["question_text"] = "bar"
      copied_qq.question_data = copied_qd
      copied_qq.save!

      mm = run_master_migration
      results = mm.migration_results.find_by(child_subscription_id: sub.id).results
      expect(results).to eq({ skipped: [copied_quiz.migration_id] })
    end

    it "uses current version of quiz after import if quiz was published on the copy_to" do
      @copy_to = course_factory
      @copy_to.enroll_student(User.create!, enrollment_state: "active")
      @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!(allowed_attempts: 3)
      qq = quiz.quiz_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })

      run_master_migration

      copied_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      copied_quiz.publish!
      copied_qq = copied_quiz.quiz_questions.where(migration_id: mig_id(qq)).first

      new_master_text = "some mastery text"
      qd = qq.question_data
      qd["question_text"] = new_master_text
      qq.question_data = qd
      qq.save!

      run_master_migration # re-copy all the content

      expect(copied_qq.reload.question_data["question_text"]).to eq new_master_text
      expect(copied_quiz.reload.quiz_data).to include(hash_including("question_text" => new_master_text))
    end

    it "handles graded quizzes/discussions/etc better" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      old_due_at = 5.days.from_now

      quiz_assmt = @copy_from.assignments.create!(due_at: old_due_at, submission_types: "online_quiz").reload
      quiz = quiz_assmt.quiz
      topic = @copy_from.discussion_topics.new
      topic.assignment = @copy_from.assignments.build(due_at: old_due_at)
      topic.save!
      topic_assmt = topic.assignment

      run_master_migration

      copied_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      copied_quiz_assmt = copied_quiz.assignment
      expect(copied_quiz_assmt.migration_id).to eq copied_quiz.migration_id # should use the same migration id = same restrictions
      copied_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      copied_topic_assmt = copied_topic.assignment
      expect(copied_topic_assmt.migration_id).to eq copied_topic.migration_id # should use the same migration id = same restrictions

      new_title = "new master title"
      quiz.update_attribute(:title, new_title)
      topic.update_attribute(:title, new_title)
      [quiz, topic].each { |c| c.class.where(id: c).update_all(updated_at: 2.seconds.from_now) } # ensure it gets copied

      run_master_migration

      expect(copied_quiz_assmt.reload.title).to eq new_title # should carry the new title over to the assignments
      expect(copied_topic_assmt.reload.title).to eq new_title

      quiz_child_tag = sub.child_content_tags.where(content: copied_quiz).first
      topic_child_tag = sub.child_content_tags.where(content: copied_topic).first
      [quiz_child_tag, topic_child_tag].each do |tag|
        expect(tag.downstream_changes).to be_empty
      end

      new_child_due_at = 7.days.from_now
      copied_quiz.update_attribute(:due_at, new_child_due_at)
      copied_topic_assmt.update_attribute(:due_at, new_child_due_at)

      [quiz_child_tag, topic_child_tag].each do |tag|
        expect(tag.reload.downstream_changes).to include("due_at") # store the downstream changes on
      end

      new_master_due_at = 10.days.from_now
      quiz.update_attribute(:due_at, new_master_due_at)
      topic_assmt.update_attribute(:due_at, new_master_due_at)
      [quiz, topic].each { |c| c.class.where(id: c).update_all(updated_at: 2.seconds.from_now) } # ensure it gets copied

      run_master_migration # re-copy all the content - but don't actually overwrite anything because it got changed downstream

      expect(copied_quiz_assmt.reload.due_at.to_i).to eq new_child_due_at.to_i # didn't get overwritten
      expect(copied_topic_assmt.reload.due_at.to_i).to eq new_child_due_at.to_i # didn't get overwritten

      [quiz, topic].each do |c|
        mtag = @template.content_tag_for(c)
        Timecop.freeze(2.seconds.from_now) do
          mtag.update_attribute(:restrictions, { due_dates: true }) # lock the quiz/topic master tags
        end
      end

      run_master_migration # now, overwrite the due_at's because the tags are locked

      expect(copied_quiz_assmt.reload.due_at.to_i).to eq new_master_due_at.to_i # should have gotten overwritten
      expect(copied_topic_assmt.reload.due_at.to_i).to eq new_master_due_at.to_i
    end

    it "does not copy only_visible_to_overrides for quizzes by default" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      quiz_assmt = @copy_from.assignments.create!(submission_types: "online_quiz").reload
      quiz = quiz_assmt.quiz
      quiz.update_attribute(:only_visible_to_overrides, true)

      run_master_migration

      copied_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      expect(copied_quiz.only_visible_to_overrides).to be false
    end

    it "allows a minion course's change of the graded status of a discussion topic to stick" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      topic = @copy_from.discussion_topics.new
      topic.assignment = @copy_from.assignments.build(due_at: 1.month.from_now)
      topic.save!
      run_master_migration

      topic_to = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).take
      assignment_to = topic_to.assignment
      topic_to.assignment = nil
      topic_to.save!

      expect(assignment_to.reload).to be_deleted
      topic_tag = MasterCourses::ChildContentTag.where(content_type: "DiscussionTopic", content_id: topic_to.id).take
      expect(topic_tag.downstream_changes).to include "assignment_id"
      assign_tag = MasterCourses::ChildContentTag.where(content_type: "Assignment", content_id: assignment_to.id).take
      expect(assign_tag.downstream_changes).to include "workflow_state"

      Timecop.travel(1.hour.from_now) do
        topic.message = "content updated"
        topic.save!
      end
      run_master_migration

      expect(topic_to.reload.assignment).to be_nil
      expect(assignment_to.reload).to be_deleted
    end

    it "allows a minion course's change of the graded status of a discussion topic to stick in the opposite direction too" do
      # should be able to make it graded downstream
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      topic = @copy_from.discussion_topics.create!
      run_master_migration

      topic_to = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).take
      topic_to.assignment = @copy_to.assignments.build(due_at: 1.month.from_now)
      topic_to.save!

      topic_tag = MasterCourses::ChildContentTag.where(content_type: "DiscussionTopic", content_id: topic_to.id).take
      expect(topic_tag.downstream_changes).to include "assignment_id"

      Timecop.travel(1.hour.from_now) do
        topic.message = "content updated"
        topic.save!
      end
      run_master_migration

      expect(topic_to.reload.assignment).to_not be_nil
      expect(topic_to.assignment).to_not be_deleted
    end

    it "ignores course settings on selective export unless requested" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @copy_from.tab_configuration = [{ "id" => 0 }, { "id" => 14 }, { "id" => 8 }, { "id" => 5 }, { "id" => 6 }, { "id" => 2 }, { "id" => 3, "hidden" => true }]
      @copy_from.start_at = 1.month.ago.beginning_of_day
      @copy_from.conclude_at = 1.month.from_now.beginning_of_day
      @copy_from.restrict_enrollments_to_course_dates = true
      @copy_from.save!
      run_master_migration(copy_settings: false) # initial sync with explicit false
      expect(@copy_to.reload.tab_configuration).to_not eq @copy_from.tab_configuration
      expect(@copy_to.start_at).to be_nil
      expect(@copy_to.conclude_at).to be_nil
      expect(@copy_to.restrict_enrollments_to_course_dates).to be_falsy

      @copy_to2 = course_factory
      @sub = @template.add_child_course!(@copy_to2)
      run_master_migration # initial sync by default
      expect(@copy_to2.reload.tab_configuration).to eq @copy_from.tab_configuration
      expect(@copy_to2.start_at).to eq @copy_from.start_at
      expect(@copy_to2.conclude_at).to eq @copy_from.conclude_at
      expect(@copy_to2.restrict_enrollments_to_course_dates).to be_truthy

      @copy_from.update_attribute(:is_public, true)
      run_master_migration # selective without settings
      expect(@copy_to.reload.is_public).to_not be_truthy

      run_master_migration(copy_settings: true) # selective with settings
      expect(@copy_to.reload.is_public).to be_truthy
      expect(@copy_to.start_at).to eq @copy_from.start_at
      expect(@copy_to.conclude_at).to eq @copy_from.conclude_at
      expect(@copy_to.restrict_enrollments_to_course_dates).to be_truthy

      run_master_migration # selective without settings
      expect(@copy_to.reload.start_at).to_not be_nil # keep the dates
      expect(@copy_to.conclude_at).to_not be_nil

      Timecop.freeze(1.minute.from_now) do
        @copy_from.update(start_at: nil, conclude_at: nil)
      end
      run_master_migration(copy_settings: true) # selective with settings
      expect(@copy_to.reload.start_at).to be_nil # remove the dates
      expect(@copy_to.conclude_at).to be_nil
    end

    it "is able to disable grading standard" do
      gs = @copy_from.grading_standards.create!(title: "Standard eh", data: [["Eh", 0.93], ["Eff", 0]])
      @copy_from.update(grading_standard_enabled: true, grading_standard: gs)

      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      run_master_migration

      expect(@copy_to.reload.grading_standard.data).to eq gs.data
      expect(@copy_to.grading_standard_enabled).to be true

      @copy_from.update_attribute(:grading_standard_enabled, false)
      run_master_migration(copy_settings: true)

      expect(@copy_to.reload.grading_standard).to be_nil
      expect(@copy_to.grading_standard_enabled).to be false
    end

    it "copies front wiki pages" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @page = @copy_from.wiki_pages.create!(title: "first page")
      @page.set_as_front_page!
      @copy_from.update_attribute(:default_view, "wiki")

      run_master_migration(copy_settings: true)

      expect(@copy_to.reload.default_view).to eq "wiki"
      @page_copy = @copy_to.wiki_pages.where(migration_id: mig_id(@page)).first
      expect(@copy_to.wiki.front_page).to eq @page_copy

      Timecop.freeze(1.minute.from_now) do
        @page2 = @copy_from.wiki_pages.create!(title: "second page")
        @page2.set_as_front_page!
      end

      run_master_migration

      @page2_copy = @copy_to.wiki_pages.where(migration_id: mig_id(@page2)).first
      expect(@copy_to.wiki.reload.front_page).to eq @page2_copy

      Timecop.freeze(2.minutes.from_now) do
        @copy_from.wiki.reload.unset_front_page! # should unset on associated course
      end

      run_master_migration

      expect(@copy_to.wiki.reload.front_page).to be_nil
    end

    it "leaves front wiki setting alone on downstream change to front page url" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @page = @copy_from.wiki_pages.create!(title: "first page")
      @page.set_as_front_page!
      @copy_from.update_attribute(:default_view, "wiki")

      run_master_migration(copy_settings: true)
      @page_copy = @copy_to.wiki_pages.where(migration_id: mig_id(@page)).first

      Timecop.freeze(30.seconds.from_now) do
        @page_copy.update(title: "other title", url: "other-url")
        @page_copy.set_as_front_page!
        @page.update_attribute(:body, "beep")
      end

      run_master_migration

      expect(@page_copy.reload.is_front_page?).to be true
      expect(@copy_to.reload.default_view).to eq "wiki"
    end

    it "changes front wiki pages unless it gets changed downstream" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @page = @copy_from.wiki_pages.create!(title: "first page")
      @page.set_as_front_page!

      run_master_migration

      Timecop.freeze(10.seconds.from_now) do
        @page.update(title: "new title", url: "new_url")
        @page.set_as_front_page! # change the url but keep as front page
      end

      run_master_migration

      @page_copy = @copy_to.wiki_pages.where(migration_id: mig_id(@page)).first
      expect(@page_copy.title).to eq "new title"
      expect(@copy_to.wiki.reload.front_page).to eq @page_copy

      @copy_to.wiki.unset_front_page! # set downstream change

      Timecop.freeze(20.seconds.from_now) do
        @page.update(title: "another new title", url: "another_new_url")
        @page.set_as_front_page!
      end

      run_master_migration

      expect(@copy_to.wiki.reload.front_page_url).to be_nil # should leave alone
    end

    it "does not overwrite syllabus body if already present or changed" do
      @copy_to1 = course_factory
      @template.add_child_course!(@copy_to1)

      @copy_to2 = course_factory
      child_syllabus1 = "<p>some child syllabus</p>"
      @template.add_child_course!(@copy_to2)
      @copy_to2.update_attribute(:syllabus_body, child_syllabus1)

      master_syllabus1 = "<p>some original syllabus</p>"
      Timecop.freeze(1.minute.from_now) do
        @copy_from.update_attribute(:syllabus_body, master_syllabus1)
        run_master_migration
        expect(@copy_to1.reload.syllabus_body).to eq master_syllabus1 # use the master syllabus
        expect(@copy_to2.reload.syllabus_body).to eq child_syllabus1 # keep the existing one
      end

      master_syllabus2 = "<p>some new syllabus</p>"
      Timecop.freeze(2.minutes.from_now) do
        @copy_from.update_attribute(:syllabus_body, master_syllabus2)
        run_master_migration
        expect(@copy_to1.reload.syllabus_body).to eq master_syllabus2 # keep syncing
        expect(@copy_to2.reload.syllabus_body).to eq child_syllabus1
      end

      child_syllabus2 = "<p>syllabus is a weird word</p>"
      Timecop.freeze(3.minutes.from_now) do
        @copy_to1.update_attribute(:syllabus_body, child_syllabus2)
        run_master_migration
        expect(@copy_to1.reload.syllabus_body).to eq child_syllabus2 # preserve the downstream change
      end
    end

    it "triggers folder locking data cache invalidation" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      enable_cache do
        expect(MasterCourses::FolderHelper.locked_folder_ids_for_course(@copy_to)).to be_empty

        master_parent_folder = Folder.root_folders(@copy_from).first.sub_folders.create!(name: "parent", context: @copy_from)
        master_sub_folder = master_parent_folder.sub_folders.create!(name: "child", context: @copy_from)
        att = Attachment.create!(filename: "file.txt", uploaded_data: StringIO.new("1"), folder: master_sub_folder, context: @copy_from)
        att_tag = @template.create_content_tag_for!(att, restrictions: { all: true })

        run_master_migration

        copied_att = @copy_to.attachments.where(migration_id: att_tag.migration_id).first
        child_sub_folder = copied_att.folder
        child_parent_folder = child_sub_folder.parent_folder
        expected_ids = [child_sub_folder, child_parent_folder, Folder.root_folders(@copy_to).first].map(&:id)
        expect(Folder.connection).not_to receive(:select_values) # should have already been cached in migration
        expect(MasterCourses::FolderHelper.locked_folder_ids_for_course(@copy_to)).to match_array(expected_ids)
      end
    end

    it "propagates folder name and state changes" do
      master_parent_folder = nil
      att_tag = nil
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      Timecop.travel(10.minutes.ago) do
        master_parent_folder = Folder.root_folders(@copy_from).first.sub_folders.create!(name: "parent", context: @copy_from)
        master_sub_folder = master_parent_folder.sub_folders.create!(name: "child", context: @copy_from)
        att = Attachment.create!(filename: "file.txt", uploaded_data: StringIO.new("1"), folder: master_sub_folder, context: @copy_from)
        att_tag = @template.create_content_tag_for!(att)
        run_master_migration
      end

      master_parent_folder.update(name: "parent RENAMED", locked: true)
      master_parent_folder.sub_folders.create!(name: "empty", context: @copy_from)

      run_master_migration

      copied_att = @copy_to.attachments.where(migration_id: att_tag.migration_id).first
      expect(copied_att.full_path).to eq "course files/parent RENAMED/child/file.txt"
      expect(@copy_to.folders.where(name: "parent RENAMED").first.locked).to be true
    end

    it "deals with a deleted folder being changed upstream" do
      blueprint_folder = nil
      att_tag = nil
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      Timecop.travel(10.minutes.ago) do
        blueprint_folder = Folder.root_folders(@copy_from).first.sub_folders.create!(name: "folder", context: @copy_from)
        att = Attachment.create!(filename: "file.txt", uploaded_data: StringIO.new("1"), folder: blueprint_folder, context: @copy_from)
        att_tag = @template.create_content_tag_for!(att)
        run_master_migration
      end

      att2_tag = nil
      Timecop.travel(5.minutes.ago) do
        associated_folder = @copy_to.folders.where(cloned_item_id: blueprint_folder.cloned_item_id).take
        associated_folder.destroy

        blueprint_folder.update(name: "folder RENAMED", locked: true)
        att2 = Attachment.create!(filename: "file2.txt", uploaded_data: StringIO.new("2"), folder: blueprint_folder, context: @copy_from)
        att2_tag = @template.create_content_tag_for!(att2)
      end

      m = run_master_migration
      expect(m).to be_completed

      copied_att = @copy_to.attachments.where(migration_id: att2_tag.migration_id).first
      expect(copied_att.full_path).to eq "course files/folder RENAMED/file2.txt"
    end

    it "syncs moved folders" do
      folder_A = Folder.root_folders(@copy_from).first.sub_folders.create!(name: "A", context: @copy_from)
      folder_B = Folder.root_folders(@copy_from).first.sub_folders.create!(name: "B", context: @copy_from)
      # this needs to be here because empty folders don't sync
      Attachment.create!(filename: "decoy.txt", uploaded_data: StringIO.new("1"), folder: folder_B, context: @copy_from)
      folder_C = folder_A.sub_folders.create!(name: "C", context: @copy_from)
      att = Attachment.create!(filename: "file.txt", uploaded_data: StringIO.new("1"), folder: folder_C, context: @copy_from)
      att_tag = @template.create_content_tag_for!(att)

      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)
      run_master_migration

      copied_att = @copy_to.attachments.where(migration_id: att_tag.migration_id).first
      expect(copied_att.full_path).to eq "course files/A/C/file.txt"

      Timecop.travel(10.minutes.from_now) do
        folder_C.parent_folder = folder_B
        folder_C.save!
        run_master_migration
      end

      expect(copied_att.reload.full_path).to eq "course files/B/C/file.txt"
    end

    it "baleets assignment overrides when an admin pulls a bait-n-switch with date restrictions" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      topic = @copy_from.discussion_topics.new
      topic.assignment = @copy_from.assignments.build
      topic.save!
      normal_assmt = @copy_from.assignments.create!

      run_master_migration

      copied_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      copied_topic_assmt = copied_topic.assignment
      copied_normal_assmt = @copy_to.assignments.where(migration_id: mig_id(normal_assmt)).first

      topic_override = create_section_override_for_assignment(copied_topic_assmt)
      normal_override = create_section_override_for_assignment(copied_normal_assmt)

      new_title = "new master title"
      topic.update_attribute(:title, new_title)
      normal_assmt.update_attribute(:title, new_title)
      [topic, normal_assmt].each { |c| c.class.where(id: c).update_all(updated_at: 2.seconds.from_now) } # ensure it gets copied

      run_master_migration

      expect(copied_topic_assmt.reload.title).to eq new_title
      expect(copied_normal_assmt.reload.title).to eq new_title
      [topic_override, normal_override].each { |ao| expect(ao.reload).to be_active } # leave the overrides alone

      [topic, normal_assmt].each do |c|
        Timecop.freeze(3.seconds.from_now) do
          @template.content_tag_for(c).update(restrictions: { content: true, availability_dates: true }) # tightening the restrictions should touch it by default
        end
      end

      run_master_migration

      [topic_override, normal_override].each { |ao| expect(ao.reload).to be_deleted }
    end

    it "works with a single full export for a new association" do
      @copy_to1 = course_factory
      sub1 = @template.add_child_course!(@copy_to1)
      @copy_from.discussion_topics.create!(title: "some title")

      run_master_migration

      sub1.destroy!
      @copy_to2 = course_factory
      @template.add_child_course!(@copy_to2)

      run_master_migration
      expect(@copy_to2.discussion_topics.first).to be_present
    end

    it "is able to unset group discussions (unless posted to already)" do
      @copy_to1 = course_factory
      @copy_to2 = course_factory(active_all: true)
      @template.add_child_course!(@copy_to1)
      sub2 = @template.add_child_course!(@copy_to2)

      group_category = @copy_from.group_categories.create!(name: "a set")
      topic = @copy_from.discussion_topics.create!(title: "a group dis", group_category:)

      run_master_migration

      topic_to1 = @copy_to1.discussion_topics.where(migration_id: mig_id(topic)).first
      topic_to2 = @copy_to2.discussion_topics.where(migration_id: mig_id(topic)).first
      [topic_to1, topic_to2].each do |topic_to|
        expect(topic_to.group_category).to be_present
      end

      student_in_course(course: @copy_to2, active_all: true)
      group2 = @copy_to2.groups.create!(group_category: topic_to2.group_category, name: "a group")
      group2.add_user(@student)
      topic_to2.child_topic_for(@student).reply_from(user: @student, text: "a entry")

      Timecop.freeze(1.minute.from_now) do
        topic.update_attribute(:group_category_id, nil)
        run_master_migration
      end
      expect(topic_to1.reload.group_category).to be_nil
      expect(topic_to2.reload.group_category).to be_present # has a reply so can't be unset

      result2 = @migration.migration_results.where(child_subscription_id: sub2).first
      expect(result2.skipped_items).to eq [mig_id(topic)]
    end

    it "links assignment rubrics on update" do
      Timecop.freeze(10.minutes.ago) do
        @copy_to = course_factory
        @template.add_child_course!(@copy_to)
        @assmt = @copy_from.assignments.create!
      end
      Timecop.freeze(8.minutes.ago) do
        run_master_migration # copy the assignment
      end

      assignment_to = @copy_to.assignments.where(migration_id: mig_id(@assmt)).first
      expect(assignment_to).to be_present

      @course = @copy_from
      outcome_with_rubric
      @ra = @rubric.associate_with(@assmt, @copy_from, purpose: "grading")

      run_master_migration # copy the rubric

      rubric_to = @copy_to.rubrics.where(migration_id: mig_id(@rubric)).first
      expect(rubric_to).to be_present
      expect(assignment_to.reload.rubric).to eq rubric_to

      Timecop.freeze(5.minutes.from_now) do
        @ra.destroy # unlink the rubric
        run_master_migration
      end
      expect(assignment_to.reload.rubric).to be_nil

      # create another rubric - it should leave alone
      other_rubric = outcome_with_rubric(course: @copy_to)
      other_rubric.associate_with(assignment_to, @copy_to, purpose: "grading", use_for_grading: true)

      Assignment.where(id: @assmt).update_all(updated_at: 10.minutes.from_now)
      run_master_migration
      expect(assignment_to.reload.rubric).to eq other_rubric
    end

    it "links assignment rubrics when association is pointed to a new rubric" do
      Timecop.freeze(10.minutes.ago) do
        @copy_to = course_factory
        @template.add_child_course!(@copy_to)
        @assmt = @copy_from.assignments.create!
        @course = @copy_from
        @first_rubric = outcome_with_rubric
        @ra = @first_rubric.associate_with(@assmt, @copy_from, purpose: "grading")
      end
      Timecop.freeze(8.minutes.ago) do
        run_master_migration
      end

      assignment_to = @copy_to.assignments.where(migration_id: mig_id(@assmt)).first
      rubric_to = @copy_to.rubrics.where(migration_id: mig_id(@first_rubric)).first
      expect(assignment_to.reload.rubric).to eq rubric_to

      @second_rubric = outcome_with_rubric
      @ra.rubric = @second_rubric
      @ra.save! # change the rubric but don't make a new association

      run_master_migration

      second_rubric_to = @copy_to.rubrics.where(migration_id: mig_id(@second_rubric)).first
      expect(assignment_to.reload.rubric).to eq second_rubric_to
    end

    it "does not delete module items in associated courses" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      mod = @copy_from.context_modules.create!(name: "module")

      run_master_migration

      mod_to = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
      tag = mod_to.add_item(type: "context_module_sub_header", title: "header")

      Timecop.freeze(2.seconds.from_now) do
        mod.update_attribute(:name, "new title")
      end
      run_master_migration
      expect(tag.reload).to_not be_deleted
    end

    it "syncs module item positions properly" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      mod = @copy_from.context_modules.create!(name: "module")
      tag1 = mod.add_item(type: "context_module_sub_header", title: "header")
      tag2 = mod.add_item(type: "context_module_sub_header", title: "header2")

      run_master_migration

      tag1_to = @copy_to.context_module_tags.where(migration_id: mig_id(tag1)).first
      tag2_to = @copy_to.context_module_tags.where(migration_id: mig_id(tag2)).first
      expect(tag1_to.position).to eq 1
      expect(tag2_to.position).to eq 2
      Timecop.freeze(2.seconds.from_now) do
        ContentTag.where(id: tag1).update_all(position: 2)
        ContentTag.where(id: tag2).update_all(position: 1)
        mod.touch
      end
      run_master_migration

      expect(tag1_to.reload.position).to eq 2
      expect(tag2_to.reload.position).to eq 1
    end

    it "tries to properly append on the end even if the destination module item positions are lying" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      mod = @copy_from.context_modules.create!(name: "module")
      mod.add_item(type: "context_module_sub_header", title: "header")
      mod.add_item(type: "context_module_sub_header", title: "header2")

      run_master_migration
      @copy_to.context_modules.first.content_tags.update_all(position: 1)

      tag3 = mod.add_item(type: "context_module_sub_header", title: "header3") # should add at end
      Timecop.freeze(2.seconds.from_now) do
        mod.touch
      end
      run_master_migration
      tag3_to = @copy_to.context_module_tags.where(migration_id: mig_id(tag3)).first
      expect(tag3_to.reload.position).to eq 3
    end

    it "is able to delete modules" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      mod = @copy_from.context_modules.create!(name: "module")

      run_master_migration

      mod_to = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
      expect(mod_to).to be_active

      mod.destroy

      run_master_migration
      expect(@migration).to be_completed
      expect(mod_to.reload).to be_deleted
    end

    it "copies outcomes in selective copies" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      default = @copy_from.root_outcome_group
      log = @copy_from.learning_outcome_groups.create!(context: @copy_from, title: "outcome groupd")
      default.adopt_outcome_group(log)

      run_master_migration # get the full sync out of the way

      Timecop.freeze(1.minute.from_now) do
        @lo = @copy_from.created_learning_outcomes.new(context: @copy_from, short_description: "whee", workflow_state: "active")
        @lo.data = { rubric_criterion: { mastery_points: 2,
                                         ratings: [{ description: "e", points: 50 },
                                                   { description: "me", points: 2 },
                                                   { description: "Does Not Meet Expectations", points: 0.5 }],
                                         description: "First outcome",
                                         points_possible: 5 } }
        @lo.save!
        log.reload.add_outcome(@lo)
      end

      run_master_migration
      expect(@migration).to be_completed
      lo_to = @copy_to.learning_outcomes.where(migration_id: mig_id(@lo)).first
      expect(lo_to).to be_present
    end

    it "copies a question bank alignment even if the outcome and bank have already been synced" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      default = @copy_from.root_outcome_group
      @lo = @copy_from.created_learning_outcomes.new(context: @copy_from, short_description: "whee", workflow_state: "active")
      @lo.data = { rubric_criterion: { mastery_points: 2,
                                       ratings: [{ description: "e", points: 50 },
                                                 { description: "me", points: 2 },
                                                 { description: "Does Not Meet Expectations", points: 0.5 }],
                                       description: "First outcome",
                                       points_possible: 5 } }
      @lo.save!
      default.add_outcome(@lo)

      @bank = @copy_from.assessment_question_banks.create!(title: "bank")
      @bank.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })

      run_master_migration

      @lo_to = @copy_to.learning_outcomes.where(migration_id: mig_id(@lo)).first
      expect(@lo_to).to be_present
      @bank_to = @copy_to.assessment_question_banks.where(migration_id: mig_id(@bank)).first
      expect(@bank_to).to be_present

      Timecop.freeze(1.minute.from_now) do
        @lo.align(@bank, @copy_from)
      end

      run_master_migration

      expect(@bank_to.learning_outcome_alignments.first.learning_outcome).to eq @lo_to
    end

    it "copies a question bank alignment even if the outcome and bank have already been synced and the outcome is nested in another group" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      @og = @copy_from.learning_outcome_groups.create!({ title: "outcome group" })
      @copy_from.root_outcome_group.adopt_outcome_group(@og)

      @lo = @copy_from.account.created_learning_outcomes.new(context: @copy_from.account, short_description: "whee", workflow_state: "active")
      @lo.data = { rubric_criterion: { mastery_points: 2,
                                       ratings: [{ description: "e", points: 50 },
                                                 { description: "me", points: 2 },
                                                 { description: "Does Not Meet Expectations", points: 0.5 }],
                                       description: "First outcome",
                                       points_possible: 5 } }
      @lo.save!
      @og.add_outcome(@lo)

      run_master_migration

      Timecop.freeze(2.minutes.from_now) do
        @bank = @copy_from.assessment_question_banks.create!(title: "bank")
        @bank.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
        @lo.align(@bank, @copy_from)
      end

      run_master_migration
      @bank_to = @copy_to.assessment_question_banks.where(migration_id: mig_id(@bank)).first
      expect(@bank_to.learning_outcome_alignments.first.learning_outcome).to eq @lo
    end

    it "preserves account question bank references" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!(title: "quiz")
      bank = @copy_from.account.assessment_question_banks.create!(title: "bank")

      bank.assessment_question_bank_users.create!(user: @user)
      group = quiz.quiz_groups.create!(name: "group", pick_count: 5, question_points: 2.0)
      group.assessment_question_bank = bank
      group.save

      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      group_to = quiz_to.quiz_groups.first
      expect(group_to.assessment_question_bank_id).to eq bank.id
    end

    it "resets generated quiz questions on assessment question re-import" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!(title: "quiz")
      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      aq = bank.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      group = quiz.quiz_groups.create!(name: "group", pick_count: 1, question_points: 2.0)
      group.assessment_question_bank = bank
      group.save
      quiz.publish!

      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      student1 = user_factory
      quiz_to.generate_submission(student1) # generates quiz questions from the bank questions

      new_text = "something new"
      Timecop.freeze(2.minutes.from_now) do
        aq.update_attribute(:question_data, aq.question_data.merge("question_text" => new_text))
      end

      run_master_migration

      student2 = user_factory
      sub = quiz_to.generate_submission(student2)
      expect(sub.quiz_data.first["question_text"]).to eq new_text
    end

    it "preserves assessment question links for quiz question re-import" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      data = { "question_name" => "test question", "question_type" => "essay_question", "question_text" => "text" }
      aq = bank.assessment_questions.create!(question_data: data)
      quiz = @copy_from.quizzes.create!(title: "quiz")
      quiz.quiz_questions.create!(question_data: data, assessment_question: aq)
      quiz.publish!

      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      qq_to = quiz_to.quiz_questions.first
      aq_to = @copy_to.assessment_questions.first
      expect(qq_to.assessment_question).to eq aq_to

      Quizzes::Quiz.where(id: quiz).update_all(updated_at: 2.minutes.from_now) # sync just the quiz

      run_master_migration
      expect(qq_to.reload.assessment_question).to eq aq_to # should leave unchanged
    end

    it "syncs quiz_groups with points locked" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!(title: "quiz")
      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      bank.assessment_questions.create!(question_data: { "question_name" => "test question", "question_type" => "essay_question" })
      group = quiz.quiz_groups.create!(name: "group", pick_count: 1, question_points: 2.0)
      group.assessment_question_bank = bank
      group.save
      @template.create_content_tag_for!(quiz, restrictions: { content: false, points: true })

      mm = run_master_migration
      expect(mm.migration_results.first.content_migration.warnings).to be_empty

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).take
      qg_to = quiz_to.quiz_groups.first # NOTE: it's migration_id isn't mig_id(group) because qti_generator is an oddball. oh well.

      expect(qg_to.question_points).to eq 2.0
      qg_to.question_points = 3.0
      expect(qg_to.save).to be false
      expect(qg_to.errors.first.second).to eq "cannot change column(s): question_points - locked by Master Course"
    end

    it "copies tab configurations for account-level external tools" do
      @tool_from = @copy_from.account.context_external_tools.create!(name: "new tool", consumer_key: "key", shared_secret: "secret", custom_fields: { "a" => "1", "b" => "2" }, url: "http://www.example.com")
      @tool_from.settings[:course_navigation] = { url: "http://www.example.com", text: "Example URL" }
      @tool_from.save!

      @copy_from.tab_configuration = [{ "id" => 0 }, { "id" => "context_external_tool_#{@tool_from.id}", "hidden" => true }, { "id" => 14 }]
      @copy_from.save!

      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      run_master_migration
      expect(@copy_to.reload.tab_configuration).to eq @copy_from.tab_configuration
    end

    it "does not break trying to match existing attachments on cloned_item_id" do
      # this was 'fun' to debug - i'm still not quite sure how it came about
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)
      att1 = Attachment.create!(filename: "first.txt",
                                uploaded_data: StringIO.new("ohai"),
                                folder: Folder.unfiled_folder(@copy_from),
                                context: @copy_from)

      run_master_migration

      att_to = @copy_to.attachments.where(migration_id: mig_id(att1)).first
      expect(att_to.cloned_item_id).to eq att1.reload.cloned_item_id # i still don't know why we set this

      sub.destroy

      @copy_from2 = course_factory
      @template2 = MasterCourses::MasterTemplate.set_as_master_course(@copy_from2)
      att2 = Attachment.create!(filename: "first.txt",
                                uploaded_data: StringIO.new("ohai"),
                                folder: Folder.unfiled_folder(@copy_from2),
                                context: @copy_from2,
                                cloned_item_id: att1.cloned_item_id)
      @template2.add_child_course!(@copy_to)

      MasterCourses::MasterMigration.start_new_migration!(@template2, @admin)
      run_jobs

      expect(@copy_to.content_migrations.last.migration_issues).to_not be_exists
      att2_to = @copy_to.attachments.where(migration_id: @template2.migration_id_for(att2)).first
      expect(att2_to).to be_present
    end

    it "links to existing outcomes even when some weird migration_id thing happens" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      lo = @copy_from.created_learning_outcomes.new(context: @copy_from, short_description: "whee", workflow_state: "active")
      lo.data = { rubric_criterion: { mastery_points: 2,
                                      ratings: [{ description: "e", points: 50 },
                                                { description: "me", points: 2 },
                                                { description: "Does Not Meet Expectations", points: 0.5 }],
                                      description: "First outcome",
                                      points_possible: 5 } }
      lo.save!
      from_root = @copy_from.root_outcome_group
      from_root.add_outcome(lo)

      LearningOutcome.where(id: lo).update_all(updated_at: 1.minute.ago)

      run_master_migration

      lo_to = @copy_to.created_learning_outcomes.where(migration_id: mig_id(lo)).first

      rub = Rubric.new(context: @copy_from)
      rub.data = [{
        points: 3,
        description: "Outcome row",
        id: 2,
        ratings: [{ points: 3, description: "meep", criterion_id: 2, id: 3 }],
        ignore_for_scoring: true,
        learning_outcome_id: lo.id
      }]
      rub.save!
      rub.associate_with(@copy_from, @copy_from)

      run_master_migration

      rub_to = @copy_to.rubrics.where(migration_id: mig_id(rub)).first
      expect(rub_to.data.first["learning_outcome_id"]).to eq lo_to.id
      expect(rub_to.learning_outcome_alignments.first.learning_outcome_id).to eq lo_to.id
    end

    it "syncs workflow states more betterisher" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      assmt = @copy_from.assignments.create!
      topic = @copy_from.discussion_topics.create!(message: "hi", title: "discussion title")
      page = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai")
      quiz = @copy_from.quizzes.create!(workflow_state: "available")
      file = @copy_from.attachments.create!(filename: "blah", uploaded_data: default_uploaded_data)
      mod = @copy_from.context_modules.create!(name: "module")
      tag = mod.add_item(type: "context_module_sub_header", title: "header")
      tag.publish!

      run_master_migration

      copied_assmt = @copy_to.assignments.where(migration_id: mig_id(assmt)).first
      copied_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      copied_page = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      copied_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      copied_file = @copy_to.attachments.where(migration_id: mig_id(file)).first
      copied_mod = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
      copied_tag = @copy_to.context_module_tags.where(migration_id: mig_id(tag)).first
      copied_things = [copied_assmt, copied_topic, copied_page, copied_quiz, copied_file, copied_mod, copied_tag]

      copied_things.each do |copied_obj|
        expect(copied_obj).to be_published
      end

      # unpublish everything
      Timecop.freeze(1.minute.from_now) do
        [assmt, topic, page, quiz, mod, tag].each do |obj|
          obj.update_attribute(:workflow_state, "unpublished")
        end
        file.update_attribute(:locked, true)
      end

      run_master_migration

      # should be unpublished
      copied_things.each do |copied_obj|
        expect(copied_obj.reload).to_not be_published
      end

      # republish everything
      Timecop.freeze(2.minutes.from_now) do
        assmt.update_attribute(:workflow_state, "published")
        quiz.update_attribute(:workflow_state, "available")
        [topic, page, mod, tag].each do |obj|
          obj.update_attribute(:workflow_state, "active")
        end
        file.update_attribute(:locked, false)
      end

      run_master_migration

      # should be published
      copied_things.each do |copied_obj|
        expect(copied_obj.reload).to be_published
      end

      # unpublish everything on child side
      [copied_assmt, copied_topic, copied_page, copied_quiz, copied_mod, copied_tag].each do |obj|
        obj.update_attribute(:workflow_state, "unpublished")
      end
      copied_file.update_attribute(:locked, true)
      Timecop.freeze(3.minutes.from_now) do
        [assmt, topic, page, quiz, mod, tag, file].each(&:touch) # retouch
      end

      run_master_migration

      # should still be unpublished
      copied_things.each do |copied_obj|
        expect(copied_obj.reload).to_not be_published
      end
    end

    it "copies module prerequisites selectively" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      mod1 = @copy_from.context_modules.create! name: "wun"
      mod2 = @copy_from.context_modules.create! name: "too"

      run_master_migration

      mod1_to = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      mod2_to = @copy_to.context_modules.where(migration_id: mig_id(mod2)).first

      Timecop.freeze(2.minutes.from_now) do
        mod2.prerequisites = "module_#{mod1.id}"
        mod2.save!
      end

      run_master_migration
      expect(mod2_to.reload.prerequisites[0][:id]).to eql(mod1_to.id)

      Timecop.freeze(3.minutes.from_now) do
        mod2.prerequisites = ""
        mod2.save!
      end

      run_master_migration
      expect(mod2_to.reload.prerequisites).to be_empty
    end

    it "copies module requirements (and lack thereof)" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      mod1 = @copy_from.context_modules.create! name: "mod"
      page = @copy_from.wiki_pages.create!(title: "some page")
      page_tag = mod1.add_item({ id: page.id, type: "wiki_page", indent: 1 })
      mod1.update(completion_requirements: [{ id: page_tag.id, type: "must_view" }])

      run_master_migration

      mod1_to = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      page_tag_to = mod1_to.content_tags.first
      expect(mod1_to.completion_requirements).to eq([{ id: page_tag_to.id, type: "must_view" }])

      Timecop.freeze(1.minute.from_now) do
        mod1.update(completion_requirements: [])
      end
      run_master_migration
      expect(mod1_to.reload.completion_requirements).to eq([])
    end

    it "preserves prerequisites and requirements set downstream" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      mod1 = @copy_from.context_modules.create!(name: "module1")
      mod2 = @copy_from.context_modules.create!(name: "module2")
      assmt = @copy_from.assignments.create!
      tag = mod2.add_item type: "assignment", id: assmt.id
      run_master_migration

      mod1_to = @copy_to.context_modules.where(migration_id: mig_id(mod1)).take
      mod2_to = @copy_to.context_modules.where(migration_id: mig_id(mod2)).take
      tag_to = @copy_to.context_module_tags.where(migration_id: mig_id(tag)).take
      mod2_to.prerequisites = mod1_to.asset_string
      mod2_to.completion_requirements = [{ id: tag_to.id, type: "must_submit" }]
      mod2_to.requirement_count = 1
      mod2_to.require_sequential_progress = true
      mod2_to.save!

      Timecop.travel(5.minutes.from_now) do
        mod2.name = "module too"
        mod2.save!
        run_master_migration
      end

      mod2_to.reload
      expect(mod2_to.completion_requirements).to eq([{ id: tag_to.id, type: "must_submit" }])
      expect(mod2_to.prerequisites).to eq([{ id: mod1_to.id, type: "context_module", name: "module1" }])
      expect(mod2_to.require_sequential_progress).to be true
      expect(mod2_to.requirement_count).to eq 1
    end

    it "copies the lack of a module unlock date" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      mod = @copy_from.context_modules.create!(name: "m", unlock_at: 3.days.from_now)
      run_master_migration
      mod_to = @copy_to.context_modules.where(migration_id: mig_id(mod)).first

      Timecop.freeze(1.minute.from_now) do
        mod.update_attribute(:unlock_at, nil)
      end
      run_master_migration
      expect(mod_to.reload.unlock_at).to be_nil
    end

    it "works with links to files copied in previous sync" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      Timecop.freeze(1.minute.ago) do
        @att = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from), context: @copy_from)
      end
      run_master_migration

      @att_copy = @copy_to.attachments.where(migration_id: mig_id(@att)).first
      expect(@att_copy).to be_present

      Timecop.freeze(1.minute.from_now) do
        @topic = @copy_from.discussion_topics.create!(title: "some topic", message: "<img src='/courses/#{@copy_from.id}/files/#{@att.id}/download?wrap=1'>")
      end
      run_master_migration

      @topic_copy = @copy_to.discussion_topics.where(migration_id: mig_id(@topic)).first
      expect(@topic_copy.message).to include("/courses/#{@copy_to.id}/files/#{@att_copy.id}/download?wrap=1")
    end

    it "replaces module item contents when file is replaced" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @att = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from), context: @copy_from)
      @mod = @copy_from.context_modules.create!
      @tag = @mod.add_item(id: @att.id, type: "attachment")

      run_master_migration

      @att_copy = @copy_to.attachments.where(migration_id: mig_id(@att)).first
      @tag_copy = @copy_to.context_module_tags.where(migration_id: mig_id(@tag)).first
      expect(@tag_copy.content).to eq @att_copy

      Timecop.freeze(1.minute.from_now) do
        @new_att = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from), context: @copy_from)
        @new_att.handle_duplicates(:overwrite)
      end
      expect(@tag.reload.content).to eq @new_att

      run_master_migration

      @new_att_copy = @copy_to.attachments.where(migration_id: mig_id(@new_att)).first
      expect(@tag_copy.reload.content).to eq @new_att_copy
    end

    it "exports account-level linked outcomes in a selective migration" do
      Timecop.freeze(1.minute.ago) do
        @acc_outcome = @copy_from.account.created_learning_outcomes.create!(short_description: "womp")
      end

      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)
      run_master_migration # make a full sync

      Timecop.freeze(30.seconds.from_now) do
        @copy_from.root_outcome_group.add_outcome(@acc_outcome) # link to course - note that the original outcome hasn't been updated
      end

      run_master_migration
      expect(@copy_to.linked_learning_outcomes.to_a).to eq [@acc_outcome]
    end

    it "doesn't clear assignment group rules on a selective sync" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      ag = @copy_from.assignment_groups.create!(name: "group")
      a = @copy_from.assignments.create!(title: "some assignment", assignment_group_id: ag.id)
      ag.update_attribute(:rules, "drop_lowest:1\nnever_drop:#{a.id}\n")

      run_master_migration

      ag_to = @copy_to.assignment_groups.where(migration_id: mig_id(ag)).first
      a_to = @copy_to.assignments.where(migration_id: mig_id(a)).first

      Timecop.freeze(30.seconds.from_now) do
        ag.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{a.id}\n")
      end

      run_master_migration
      expect(ag_to.reload.rules).to eq "drop_lowest:2\nnever_drop:#{a_to.id}\n"

      Timecop.freeze(60.seconds.from_now) do
        ag.update_attribute(:rules, "never_drop:#{a.id}\n")
      end
      run_master_migration
      expect(ag_to.reload.rules).to be_nil # set to empty if there are no dropping rules
    end

    it "doesn't clear external tool config on exception" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      a = @copy_from.assignments.create!(title: "some assignment")
      run_master_migration
      a_to = @copy_to.assignments.where(migration_id: mig_id(a)).first

      Timecop.freeze(60.seconds.from_now) do
        a.touch
      end

      tool = @copy_to.context_external_tools.create!(name: "some tool",
                                                     consumer_key: "test_key",
                                                     shared_secret: "test_secret",
                                                     url: "http://example.com/launch")
      a_to.update(submission_types: "external_tool", external_tool_tag_attributes: { content: tool })
      tag = a_to.external_tool_tag

      run_master_migration

      expect(a_to.reload.external_tool_tag).to eq tag # don't change
    end

    it "can publish a course after initial sync if requested" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      run_master_migration
      expect(@copy_to.reload).to be_unpublished

      @copy_to2 = course_factory
      @template.add_child_course!(@copy_to2)

      run_master_migration(publish_after_initial_sync: true)
      expect(@copy_to2.reload).to be_available
    end

    it "updates quiz assignment cached due dates" do
      course_with_student(active_all: true)
      @copy_to = @course
      @sub = @template.add_child_course!(@copy_to)

      q = @copy_from.quizzes.create!(title: "some quiz")
      q.publish!

      run_master_migration
      q_to = @copy_to.quizzes.where(migration_id: mig_id(q)).first
      sub = @student.submissions.where(assignment_id: q_to.assignment).first
      expect(sub.cached_due_date).to be_nil

      due_at = 1.day.from_now
      Timecop.freeze(1.minute.from_now) do
        q.update_attribute(:due_at, due_at)
        run_master_migration
      end

      expect(sub.reload.cached_due_date.to_i).to eq due_at.to_i
    end

    it "handles downstream changes of ungraded discussion dates correctly" do
      date1 = 1.week.ago.at_noon
      date2 = 2.weeks.ago.at_noon
      copy_to = course_factory
      sub = @template.add_child_course!(copy_to)
      topic = @copy_from.discussion_topics.create!(lock_at: date1)
      run_master_migration
      topic_to = copy_to.discussion_topics.where(migration_id: mig_id(topic)).take

      # ensure schedule_delayed_transitions does not cause a spurious downstream change record
      expect(sub.child_content_tags.where(content: topic_to).take.downstream_changes).to eq([])

      Timecop.travel(5.minutes.from_now) do
        # now actually make a downstream change
        topic.touch
        topic_to.lock_at = date2
        topic_to.save!
        run_master_migration
        expect(topic_to.reload.lock_at).to eq date2
        expect(sub.child_content_tags.where(content: topic_to).take.downstream_changes).to eq(["lock_at"])
      end

      # lock the availability dates and ensure the downstream change is overwritten
      Timecop.travel(10.minutes.from_now) do
        @template.content_tag_for(topic).update_attribute(:restrictions, { availability_dates: true })
        topic.touch
        run_master_migration
        expect(sub.child_content_tags.where(content: topic_to).take.downstream_changes).to eq([])
        expect(topic_to.reload.lock_at).to eq date1
      end
    end

    context "attachment migration id preservation" do
      it "does not overwrite blueprint attachment migration ids from other course copies" do
        att = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from), context: @copy_from)

        @copy_to = course_factory(active_all: true)
        @sub = @template.add_child_course!(@copy_to)

        run_master_migration

        att_to = @copy_to.attachments.where(migration_id: mig_id(att)).take

        @other_copy_from = course_factory(active_all: true)
        run_course_copy(@copy_from, @other_copy_from)
        impostor_att = @other_copy_from.attachments.last

        run_course_copy(@other_copy_from, @copy_to)
        expect(att_to.reload.migration_id).to eq mig_id(att) # should not have changed

        impostor_att_to = @copy_to.attachments.where(migration_id: CC::CCHelper.create_key(impostor_att, global: true)).first
        expect(impostor_att_to.id).to_not eq att_to.id # should make a copy
        expect(impostor_att_to.display_name).to_not eq att_to.display_name
      end

      def import_package(course)
        cm = ContentMigration.create!(context: course, user: @user)
        cm.migration_type = "canvas_cartridge_importer"
        cm.migration_settings["import_immediately"] = true
        cm.save!

        package_path = File.join(File.dirname(__FILE__) + "/../../fixtures/migration/canvas_attachment.zip")
        attachment = Attachment.create!(context: cm, uploaded_data: File.open(package_path, "rb"), filename: "file.zip")
        cm.attachment = attachment
        cm.save!
        cm.queue_migration
        run_jobs
      end

      it "does not overwrite blueprint attachment migration ids from other canvas package imports" do
        import_package(@copy_from)
        att = @copy_from.attachments.first

        course_factory(active_all: true)
        @copy_to = @course
        @sub = @template.add_child_course!(@copy_to)

        run_master_migration

        att_to = @copy_to.attachments.where(migration_id: mig_id(att)).take

        import_package(@copy_to)
        expect(att_to.reload.migration_id).to eq mig_id(att) # should not have changed

        impostor_att_to = @copy_to.attachments.where(migration_id: att.migration_id).first # package should make a copy
        expect(impostor_att_to.id).to_not eq att_to.id
        expect(impostor_att_to.display_name).to_not eq att_to.display_name
      end
    end

    context "caching" do
      specs_require_cache(:redis_cache_store)

      it "stuff" do
        @copy_to = course_factory(active_all: true)
        student = user_factory(active_all: true)
        @copy_to.enroll_student(student, enrollment_state: "active")
        @sub = @template.add_child_course!(@copy_to)

        a = @copy_from.assignments.create!(title: "some assignment")
        q = @copy_from.quizzes.create!(title: "some quiz")
        run_master_migration

        a_to = @copy_to.assignments.where(migration_id: mig_id(a)).first
        q_to = @copy_to.quizzes.where(migration_id: mig_id(q)).first
        ares1 = a_to.context_module_tag_info(student, @copy_to, has_submission: false)
        expect(ares1[:due_date]).to be_nil
        qres1 = q_to.context_module_tag_info(student, @copy_to, has_submission: false)
        expect(qres1[:due_date]).to be_nil
        due_at = 1.day.from_now
        Timecop.freeze(1.minute.from_now) do
          a.update_attribute(:due_at, due_at)
          q.update_attribute(:due_at, due_at)
          run_master_migration
        end
        expect(a_to.reload.due_at.to_i).to eq due_at.to_i
        ares2 = a_to.context_module_tag_info(student, @copy_to, has_submission: false)
        expect(ares2[:due_date]).to eq due_at.iso8601

        expect(q_to.reload.due_at.to_i).to eq due_at.to_i
        qres2 = q_to.context_module_tag_info(student, @copy_to, has_submission: false)
        expect(qres2[:due_date]).to eq due_at.iso8601
      end
    end

    context "sharding" do
      specs_require_sharding

      it "translates links to content with module item id" do
        mod1 = @copy_from.context_modules.create!(name: "some module")
        asmnt = @copy_from.assignments.create!(title: "some assignment")
        assmt_tag = mod1.add_item({ id: asmnt.id, type: "assignment", indent: 1 })
        page = @copy_from.wiki_pages.create!(title: "some page")
        page_tag = mod1.add_item({ id: page.id, type: "wiki_page", indent: 1 })

        body = %(<p>Link to assignment module item: <a href="/courses/%s/assignments/%s?module_item_id=%s">some assignment</a></p>
          <p>Link to page module item: <a href="/courses/%s/pages/%s?module_item_id=%s">some page</a></p>)
        topic = @copy_from.discussion_topics.create!(title: "some topic",
                                                     message: body % [@copy_from.id, asmnt.id, assmt_tag.id, @copy_from.id, page.url, page_tag.id])

        @copy_to = course_factory
        @sub = @template.add_child_course!(@copy_to)

        run_master_migration

        mod1_to = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
        asmnt_to = @copy_to.assignments.where(migration_id: mig_id(asmnt)).first
        assmt_tag_to = mod1_to.content_tags.where(content_type: "Assignment").first
        page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
        page_tag_to = mod1_to.content_tags.where(content_type: "WikiPage").first
        topic_to = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
        expect(topic_to.message).to eq body % [@copy_to.id, asmnt_to.id, assmt_tag_to.id, @copy_to.id, page_to.url, page_tag_to.id]
      end
    end

    it "sends notifications", priority: "2" do
      n0 = Notification.create(name: "Blueprint Sync Complete")
      n1 = Notification.create(name: "Blueprint Content Added")
      @admin = @user
      course_with_teacher active_all: true
      @template.add_child_course!(@course)
      cc0 = communication_channel(@admin, { username: "test_#{@admin.id}@example.com", active_cc: true })
      cc1 = communication_channel(@user, { username: "test_#{@user.id}@example.com", active_cc: true })
      run_master_migration comment: "ohai eh", send_notification: true
      expect(DelayedMessage.where(notification_id: n0, communication_channel_id: cc0).last.summary).to include "ohai eh"
      expect(DelayedMessage.where(notification_id: n1, communication_channel_id: cc1).last.summary).to include "ohai eh"
    end

    context "master courses + external migrations" do
      let(:klass) do
        Class.new do
          class << self
            attr_reader :course, :migration, :imported_content

            def send_imported_content(course, migration, imported_content)
              @course = course
              @migration = migration
              @imported_content = imported_content
            end
          end
        end
      end

      before do
        allow(Canvas::Migration::ExternalContent::Migrator).to receive(:registered_services).and_return({ "test_service" => klass })
      end

      it "works" do
        @copy_to = course_factory
        @template.add_child_course!(@copy_to)

        assmt = @copy_from.assignments.create!
        topic = @copy_from.discussion_topics.create!(message: "hi", title: "discussion title")
        ann = @copy_from.announcements.create!(message: "goodbye")
        cm = @copy_from.context_modules.create!(name: "some module")
        item = cm.add_item(id: assmt.id, type: "assignment")
        att = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from), context: @copy_from)
        page = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai")
        quiz = @copy_from.quizzes.create!

        data = {
          "$canvas_assignment_id" => assmt.id,
          "$canvas_discussion_topic_id" => topic.id,
          "$canvas_announcement_id" => ann.id,
          "$canvas_context_module_id" => cm.id,
          "$canvas_context_module_item_id" => item.id,
          "$canvas_file_id" => att.id, # $canvas_attachment_id works too
          "$canvas_page_id" => page.id,
          "$canvas_quiz_id" => quiz.id
        }

        allow(klass).to receive_messages(applies_to_course?: true,
                                         begin_export: true,
                                         export_completed?: true,
                                         retrieve_export: data)

        run_master_migration

        copied_assmt = @copy_to.assignments.where(migration_id: mig_id(assmt)).first
        copied_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
        copied_ann = @copy_to.announcements.where(migration_id: mig_id(ann)).first
        copied_cm = @copy_to.context_modules.where(migration_id: mig_id(cm)).first
        copied_item = @copy_to.context_module_tags.where(migration_id: mig_id(item)).first
        copied_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
        copied_page = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
        copied_quiz = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first

        expect(klass.course).to eq @copy_to

        expected_data = {
          "$canvas_assignment_id" => copied_assmt.id,
          "$canvas_discussion_topic_id" => copied_topic.id,
          "$canvas_announcement_id" => copied_ann.id,
          "$canvas_context_module_id" => copied_cm.id,
          "$canvas_context_module_item_id" => copied_item.id,
          "$canvas_file_id" => copied_att.id, # $canvas_attachment_id works too
          "$canvas_page_id" => copied_page.id,
          "$canvas_quiz_id" => copied_quiz.id
        }
        expect(klass.imported_content).to eq expected_data
      end
    end
  end
end
