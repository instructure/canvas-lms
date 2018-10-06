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

require 'spec_helper'

describe MasterCourses::MasterMigration do
  before :once do
    course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    user_factory
  end

  before :each do
    skip unless Qti.qti_enabled?
    local_storage!
  end

  describe "start_new_migration!" do
    it "should queue a migration" do
      expect_any_instance_of(MasterCourses::MasterMigration).to receive(:queue_export_job).once
      mig = MasterCourses::MasterMigration.start_new_migration!(@template, @user)
      expect(mig.id).to be_present
      expect(mig.master_template).to eq @template
      expect(mig.user).to eq @user
      expect(@template.active_migration).to eq mig
    end

    it "should raise an error if there's already a migration running" do
      running = @template.master_migrations.create!(:workflow_state => "exporting")
      @template.active_migration = running
      @template.save!

      expect_any_instance_of(MasterCourses::MasterMigration).to receive(:queue_export_job).never
      expect {
        MasterCourses::MasterMigration.start_new_migration!(@template, @user)
      }.to raise_error("cannot start new migration while another one is running")
    end

    it "should still allow if the 'active' migration has been running for a while (and is probably ded)" do
      running = @template.master_migrations.create!(:workflow_state => "exporting")
      @template.active_migration = running
      @template.save!

      Timecop.freeze(2.days.from_now) do
        expect_any_instance_of(MasterCourses::MasterMigration).to receive(:queue_export_job).once
        MasterCourses::MasterMigration.start_new_migration!(@template, @user)
      end
    end

    it "should queue a job" do
      expect { MasterCourses::MasterMigration.start_new_migration!(@template, @user) }.to change(Delayed::Job, :count).by(1)
      expect_any_instance_of(MasterCourses::MasterMigration).to receive(:perform_exports).once
      run_jobs
    end
  end

  describe "perform_exports" do
    before :once do
      @migration = @template.master_migrations.create!
    end

    it "shouldn't do anything if there aren't any child courses to push to" do
      expect(@migration).to receive(:create_export).never
      @migration.perform_exports
      @migration.reload
      expect(@migration).to be_completed
      expect(@migration.export_results[:message]).to eq "No child courses to export to"
    end

    it "shouldn't count deleted subscriptions" do
      other_course = course_factory
      sub = @template.add_child_course!(other_course)
      sub.destroy!

      expect(@migration).to receive(:create_export).never
      @migration.perform_exports
    end

    it "should record errors" do
      other_course = course_factory
      @template.add_child_course!(other_course)
      allow(@migration).to receive(:create_export).and_raise "oh neos"
      expect { @migration.perform_exports }.to raise_error("oh neos")

      @migration.reload
      expect(@migration).to be_exports_failed
      expect(ErrorReport.find(@migration.export_results[:error_report_id]).message).to eq "oh neos"
    end

    it "should do a full export by default" do
      new_course = course_factory
      new_sub = @template.add_child_course!(new_course)

      expect(@migration).to receive(:export_to_child_courses).with(:full, [new_sub], true)
      @migration.perform_exports
    end

    it "should do a selective export based on subscriptions" do
      old_course = course_factory
      sel_sub = @template.add_child_course!(old_course)
      sel_sub.update_attribute(:use_selective_copy, true)

      expect(@migration).to receive(:export_to_child_courses).with(:selective, [sel_sub], true)
      @migration.perform_exports
    end

    it "should do two exports if needed" do
      new_course = course_factory
      new_sub = @template.add_child_course!(new_course)
      old_course = course_factory
      sel_sub = @template.add_child_course!(old_course)
      sel_sub.update_attribute(:use_selective_copy, true)

      expect(@migration).to receive(:export_to_child_courses).twice
      @migration.perform_exports
    end
  end

  describe "all the copying" do
    before :once do
      account_admin_user(:active_all => true)
      @copy_from = @course
    end

    def mig_id(obj)
      @template.migration_id_for(obj)
    end

    def run_master_migration(opts={})
      @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @admin, opts)
      run_jobs
      @migration.reload
    end

    it "should create an export once and import in each child course" do
      @copy_to1 = course_factory
      @sub1 = @template.add_child_course!(@copy_to1)
      @copy_to2 = course_factory
      @sub2 = @template.add_child_course!(@copy_to2)

      assmt = @copy_from.assignments.create!(:name => "some assignment")
      att = Attachment.create!(:filename => '1.txt', :uploaded_data => StringIO.new('1'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)

      run_master_migration

      expect(@migration).to be_completed
      expect(@migration.imports_completed_at).to be_present

      expect(@template.master_content_tags.polymorphic_where(:content => assmt).first.restrictions).to be_empty # never mind

      [@sub1, @sub2].each do |sub|
        sub.reload
        expect(sub.use_selective_copy?).to be_truthy # should have been marked as up-to-date now
      end

      [@copy_to1, @copy_to2].each do |copy_to|
        assmt_to = copy_to.assignments.where(:migration_id => mig_id(assmt)).first
        expect(assmt_to).to be_present
        att_to = copy_to.attachments.where(:migration_id => mig_id(att)).first
        expect(att_to).to be_present
      end
    end

    it "should copy selectively on second time" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      topic = @copy_from.discussion_topics.create!(:title => "some title")
      DiscussionTopic.where(:id => topic).update_all(:updated_at => 5.seconds.ago) # just in case, to fool the selective export
      att = Attachment.create!(:filename => '1.txt', :uploaded_data => StringIO.new('1'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      Attachment.where(:id => att).update_all(:updated_at => 5.seconds.ago) # ditto

      run_master_migration
      expect(@migration.export_results.keys).to eq [:full]

      topic_to = @copy_to.discussion_topics.where(:migration_id => mig_id(topic)).first
      expect(topic_to).to be_present
      att_to = @copy_to.attachments.where(:migration_id => mig_id(att)).first
      expect(att_to).to be_present
      cm1 = @migration.migration_results.first.content_migration
      expect(cm1.migration_settings[:imported_assets]["DiscussionTopic"]).to eq topic_to.id.to_s
      expect(cm1.migration_settings[:imported_assets]["Attachment"]).to eq att_to.id.to_s

      page = @copy_from.wiki_pages.create!(:title => "another title")

      run_master_migration
      expect(@migration.export_results.keys).to eq [:selective]

      page_to = @copy_to.wiki_pages.where(:migration_id => mig_id(page)).first
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
      @template.content_tag_for(assmt).update_attribute(:restrictions, {:points => true})
      topic = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
      ann = @copy_from.announcements.create!(:message => "goodbye")
      page = @copy_from.wiki_pages.create!(:title => "wiki", :body => "ohai")
      page2 = @copy_from.wiki_pages.create!(:title => "wiki", :body => "bluh")
      quiz = @copy_from.quizzes.create!
      quiz2 = @copy_from.quizzes.create!
      bank = @copy_from.assessment_question_banks.create!(:title => 'bank')
      aq = bank.assessment_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      file = @copy_from.attachments.create!(:filename => 'blah', :uploaded_data => default_uploaded_data)
      event = @copy_from.calendar_events.create!(:title => 'thing', :description => 'blargh', :start_at => 1.day.from_now)
      tool = @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key",
        :shared_secret => "secret", :custom_fields => {'a' => '1', 'b' => '2'}, :url => "http://www.example.com")

      run_master_migration

      assmt_to = @copy_to.assignments.where(:migration_id => mig_id(assmt)).first
      topic_to = @copy_to.discussion_topics.where(:migration_id => mig_id(topic)).first
      ann_to = @copy_to.announcements.where(:migration_id => mig_id(ann)).first
      page_to = @copy_to.wiki_pages.where(:migration_id => mig_id(page)).first
      page2_to = @copy_to.wiki_pages.where(:migration_id => mig_id(page2)).first
      quiz_to = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      quiz2_to = @copy_to.quizzes.where(:migration_id => mig_id(quiz2)).first
      bank_to = @copy_to.assessment_question_banks.where(:migration_id => mig_id(bank)).first
      file_to = @copy_to.attachments.where(:migration_id => mig_id(file)).first
      event_to = @copy_to.calendar_events.where(:migration_id => mig_id(event)).first
      tool_to = @copy_to.context_external_tools.where(:migration_id => mig_id(tool)).first

      Timecop.freeze(10.minutes.from_now) do
        page2_to.update_attribute(:body, 'changed!')
        quiz2_to.update_attribute(:title, 'blargh!')
        assmt_to.update_attribute(:title, 'blergh!')

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
        expect(deletions['Assignment']).to match_array([mig_id(assmt)])
        expect(deletions['Attachment']).to match_array([mig_id(file)])
        expect(deletions['WikiPage']).to match_array([mig_id(page), mig_id(page2)])
        expect(deletions['Quizzes::Quiz']).to match_array([mig_id(quiz), mig_id(quiz2)])

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

    it "should sync deleted quiz questions (unless changed downstream)" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qq1 = quiz.quiz_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      qq2 = quiz.quiz_questions.create!(:question_data => {'question_name' => 'test question 2', 'question_type' => 'essay_question'})
      qgroup = quiz.quiz_groups.create!(:name => "group", :pick_count => 1)
      qq3 = qgroup.quiz_questions.create!(:quiz => quiz, :question_data => {'question_name' => 'test group question', 'question_type' => 'essay_question'})
      run_master_migration

      quiz_to = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      qq1_to = quiz_to.quiz_questions.where(:migration_id => mig_id(qq1)).first
      qq2_to = quiz_to.quiz_questions.where(:migration_id => mig_id(qq2)).first
      qq3_to = quiz_to.quiz_questions.where(:migration_id => mig_id(qq3)).first

      new_text = "new text"
      qq1_to.update_attribute(:question_data, qq1_to.question_data.merge('question_text' => new_text))
      Timecop.freeze(2.minutes.from_now) do
        qq2.destroy
      end
      run_master_migration

      expect(qq1_to.reload.question_data['question_text']).to eq new_text
      expect(qq2_to.reload).to_not be_deleted # should not have overwritten because downstream changes

      Timecop.freeze(4.minutes.from_now) do
        @template.content_tag_for(quiz).update_attribute(:restrictions, {:content => true})
      end
      run_master_migration

      expect(qq1_to.reload.question_data['question_text']).to_not eq new_text # should overwrite now because locked
      expect(qq2_to.reload).to be_deleted
      expect(qq3_to.reload).to_not be_deleted
    end

    it "should sync deleted quiz groups (unless changed downstream)" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qgroup1 = quiz.quiz_groups.create!(:name => "group", :pick_count => 1)
      qq1 = qgroup1.quiz_questions.create!(:quiz => quiz, :question_data => {'question_name' => 'test group question', 'question_type' => 'essay_question'})
      qgroup2 = quiz.quiz_groups.create!(:name => "group2", :pick_count => 1)
      qq2 = qgroup2.quiz_questions.create!(:quiz => quiz, :question_data => {'question_name' => 'test group question', 'question_type' => 'essay_question'})
      run_master_migration

      quiz_to = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      qgroup1_to = quiz_to.quiz_groups.where(:migration_id => mig_id(qgroup1.asset_string)).first
      qgroup2_to = quiz_to.quiz_groups.where(:migration_id => mig_id(qgroup2.asset_string)).first
      qq2_to = quiz_to.quiz_questions.where(:migration_id => mig_id(qq2)).first

      qq2_to.update_attribute(:question_data, qq2_to.question_data.merge('question_text' => 'something')) # trigger a downstream change on the quiz
      Timecop.freeze(2.minutes.from_now) do
        qgroup1.destroy
      end
      run_master_migration

      expect(quiz_to.reload.quiz_groups.to_a).to match_array([qgroup1_to, qgroup2_to]) # should not have overwritten because downstream changes

      Timecop.freeze(4.minutes.from_now) do
        @template.content_tag_for(quiz).update_attribute(:restrictions, {:content => true})
      end
      run_master_migration
      expect(quiz_to.reload.quiz_groups.to_a).to eq [qgroup2_to]
    end

    it "should sync deleted assessment bank questions (unless changed downstream)" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      bank1 = @copy_from.assessment_question_banks.create!(:title => 'bank')
      aq1 = bank1.assessment_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      aq2 = bank1.assessment_questions.create!(:question_data => {'question_name' => 'test question2', 'question_type' => 'essay_question'})
      bank2 = @copy_from.assessment_question_banks.create!(:title => 'bank')
      aq3 = bank2.assessment_questions.create!(:question_data => {'question_name' => 'test question3', 'question_type' => 'essay_question'})
      aq4 = bank2.assessment_questions.create!(:question_data => {'question_name' => 'test question4', 'question_type' => 'essay_question'})

      run_master_migration

      bank1_to = @copy_to.assessment_question_banks.where(:migration_id => mig_id(bank1)).first
      aq1_to = bank1_to.assessment_questions.where(:migration_id => mig_id(aq1)).first
      aq2_to = bank1_to.assessment_questions.where(:migration_id => mig_id(aq2)).first
      bank2_to = @copy_to.assessment_question_banks.where(:migration_id => mig_id(bank2)).first
      aq3_to = bank2_to.assessment_questions.where(:migration_id => mig_id(aq3)).first
      aq4_to = bank2_to.assessment_questions.where(:migration_id => mig_id(aq4)).first

      aq1_to.update_attribute(:question_data, aq1_to.question_data.merge('question_text' => 'something')) # trigger a downstream change on the bank
      Timecop.freeze(2.minutes.from_now) do
        aq2.destroy
        aq3.destroy
      end

      run_master_migration

      expect(aq2_to.reload).to_not be_deleted  # should not have overwritten because downstream changes
      expect(aq3_to.reload).to be_deleted # should be because no downstream changes
      expect(aq4_to.reload).to_not be_deleted # should have been left alone
    end

    it "should sync quiz group attributes (unless changed downstream)" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qgroup = quiz.quiz_groups.create!(:name => "group", :pick_count => 1)
      qq = qgroup.quiz_questions.create!(:quiz => quiz, :question_data => {'question_name' => 'test group question', 'question_type' => 'essay_question'})
      run_master_migration

      quiz_to = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      qgroup_to = quiz_to.quiz_groups.where(:migration_id => mig_id(qgroup.asset_string)).first
      qgroup_to.update_attribute(:name, "downstream") # should mark it as a downstream change
      Timecop.freeze(2.minutes.from_now) do
        qgroup.update_attribute(:name, "upstream")
        @new_qq = quiz.quiz_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      end
      run_master_migration

      expect(qgroup_to.reload.name).to eq "downstream"
      expect(quiz_to.reload.quiz_questions.where(:migration_id => mig_id(@new_qq)).first).to be_nil

      Timecop.freeze(4.minutes.from_now) do
        @template.content_tag_for(quiz).update_attribute(:restrictions, {:content => true})
      end
      run_master_migration

      expect(qgroup_to.reload.name).to eq "upstream"
      # adding new questions was borking because a method i didn't think would ever get called was getting called >.<
      expect(quiz_to.reload.quiz_questions.where(:migration_id => mig_id(@new_qq)).first).to_not be_nil
    end

    it "shouldn't delete an assignment group if it's not empty downstream" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      ag1 = @copy_from.assignment_groups.create!(:name => "group1")
      a1 = @copy_from.assignments.create!(:title => "assmt1", :assignment_group => ag1)
      ag2 = @copy_from.assignment_groups.create!(:name => "group2")
      a2 = @copy_from.assignments.create!(:title => "assmt2", :assignment_group => ag2)
      ag3 = @copy_from.assignment_groups.create!(:name => "group3")
      a3 = @copy_from.assignments.create!(:title => "assmt3", :assignment_group => ag3)

      run_master_migration

      ag1_to = @copy_to.assignment_groups.where(:migration_id => mig_id(ag1)).first
      a1_to = ag1_to.assignments.first
      ag2_to = @copy_to.assignment_groups.where(:migration_id => mig_id(ag2)).first
      a2_to = ag2_to.assignments.first
      ag3_to = @copy_to.assignment_groups.where(:migration_id => mig_id(ag3)).first
      a3_to = ag3_to.assignments.first

      Timecop.freeze(30.seconds.from_now) do
        [ag1, ag2, ag3].each(&:destroy!)
        a2_to.update_attribute(:name, "some other downstream name")
        @new_assmt = @copy_to.assignments.create!(:title => "a new assignment created downstream", :assignment_group => ag3_to)
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

    it "should sync unpublished quiz points possible" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!(:workflow_state => "unpublished")
      qq = quiz.quiz_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question', 'points_possible' => 1})
      quiz.root_entries(true)
      quiz.save!

      run_master_migration

      quiz_to = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      expect(quiz_to.points_possible).to eq 1
      qq_to = quiz_to.quiz_questions.where(:migration_id => mig_id(qq)).first

      new_text = "new text"
      Timecop.freeze(2.minutes.from_now) do
        qq.update_attribute(:question_data, qq.question_data.merge(:points_possible => 2))
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
      topic = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
      page = nil
      file = nil

      run_master_migration

      Timecop.freeze(10.minutes.from_now) do
        assmt.update_attribute(:title, 'new title eh')
        page = @copy_from.wiki_pages.create!(:title => "wiki", :body => "ohai")
        file = @copy_from.attachments.create!(:filename => 'blah', :uploaded_data => default_uploaded_data)
      end

      Timecop.travel(20.minutes.from_now) do
        mm = run_master_migration
        expect(mm.export_results[:selective][:created]['WikiPage']).to eq([mig_id(page)])
        expect(mm.export_results[:selective][:created]['Attachment']).to eq([mig_id(file)])
        expect(mm.export_results[:selective][:updated]['Assignment']).to eq([mig_id(assmt)])
      end
    end

    it "doesn't restore deleted associated content unless relocked" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      page1 = @copy_from.wiki_pages.create!(:title => "whee")
      page2 = @copy_from.wiki_pages.create!(:title => "whoo")
      quiz = @copy_from.quizzes.create!(:title => 'what')
      run_master_migration

      page1_to = @copy_to.wiki_pages.where(:migration_id => mig_id(page1)).first
      page1_to.destroy # "manually" delete it
      page2_to = @copy_to.wiki_pages.where(:migration_id => mig_id(page2)).first
      quiz_to = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      quiz_to.destroy

      Timecop.freeze(3.minutes.from_now) do
        page1.update_attribute(:title, 'new title eh')
        page2.destroy
        quiz.update_attribute(:title, 'new title wat')
      end
      run_master_migration

      expect(page1_to.reload).to be_deleted # shouldn't have restored it
      expect(page2_to.reload).to be_deleted # should still sync the original deletion
      expect(quiz_to.reload).to be_deleted # shouldn't have restored it neither

      Timecop.freeze(5.minutes.from_now) do
        page1.update_attribute(:title, 'another new title srsly')
        @template.content_tag_for(page1).update_attribute(:restrictions, {:content => true}) # lock it down
        page2.update_attribute(:workflow_state, "active") # restore the original
        quiz.update_attribute(:title, 'another new title frd pdq')
        @template.content_tag_for(quiz).update_attribute(:restrictions, {:content => true}) # lock it down
      end
      run_master_migration

      expect(page1_to.reload).to be_active # should be restored because it's locked now
      expect(page2_to.reload).to be_active # should be restored because it hadn't been deleted manually
      expect(quiz_to.reload).not_to be_deleted # should be restored because it's locked now
    end

    it "doesn't undelete modules that were deleted downstream" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      mod = @copy_from.context_modules.create! :name => 'teh'
      run_master_migration

      mod_to = @copy_to.context_modules.where(:migration_id => mig_id(mod)).first
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
        @og = @copy_from.learning_outcome_groups.create!({:title => 'outcome group'})
        root.adopt_outcome_group(@og)
        @outcome = @copy_from.created_learning_outcomes.create!({:title => 'new outcome'})
        @og.add_outcome(@outcome)
        run_master_migration

        @outcome_to = @copy_to.learning_outcomes.where(:migration_id => mig_id(@outcome)).first
        @og_to = @copy_to.learning_outcome_groups.where(:migration_id => mig_id(@og)).first
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
        expect(@og_to.child_outcome_links.not_deleted.where(content_type: 'LearningOutcome', content_id: @outcome_to)).not_to be_any
      end
    end

    it "copies links to account outcomes on rubrics" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      run_master_migration

      account = @copy_from.account
      a_group = account.root_outcome_group
      lo = account.created_learning_outcomes.create!({:title => 'new outcome'})

      root = @copy_from.root_outcome_group
      log = @copy_from.learning_outcome_groups.create!(:title => "some group")
      root.adopt_outcome_group(log)
      tag = log.add_outcome(lo)

      # don't automatically link in selective content but should still get copied because the rubric is copied
      ContentTag.where(:id => tag).update_all(:updated_at => 5.minutes.ago)

      rub = Rubric.new(:context => @copy_from)
      rub.data = [
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [{:points => 3,:description => "Rockin'",:criterion_id => 1,:id => 2}],
          :learning_outcome_id => lo.id
        }
      ]
      rub.save!
      rub.associate_with(@copy_from, @copy_from)
      Rubric.where(:id => rub.id).update_all(:updated_at => 5.minute.from_now)

      run_master_migration

      rub_to = @copy_to.rubrics.first
      expect(rub_to.data.first["learning_outcome_id"]).to eq lo.id
    end

    it "doesn't restore deleted associated files unless relocked" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      att1 = Attachment.create!(:filename => 'file1.txt', :uploaded_data => StringIO.new('1'),
        :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att2 = Attachment.create!(:filename => 'file2.txt', :uploaded_data => StringIO.new('2'),
        :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)

      run_master_migration

      att1_to = @copy_to.attachments.where(:migration_id => mig_id(att1)).first
      att1_to.destroy # "manually" delete it
      att2_to = @copy_to.attachments.where(:migration_id => mig_id(att2)).first

      Timecop.freeze(3.minutes.from_now) do
        att1.touch
        att2.destroy
      end
      run_master_migration

      expect(att1_to.reload).to be_deleted # shouldn't have restored it
      expect(att2_to.reload).to be_deleted # should still sync the original deletion

      Timecop.freeze(5.minutes.from_now) do
        att1.touch
        @template.content_tag_for(att1).update_attribute(:restrictions, {:content => true}) # lock it down

        att2.update_attribute(:file_state, "available") # restore the original
      end
      run_master_migration

      expect(att1_to.reload).to be_available # should be restored because it's locked now
      expect(att2_to.reload).to be_available # should be restored because it hadn't been deleted manually
    end

    it "limits the number of items to track" do
      Setting.set('master_courses_history_count', '2')

      @copy_to = course_factory
      @template.add_child_course!(@copy_to)
      run_master_migration

      Timecop.travel(10.minutes.from_now) do
        3.times { |x| @copy_from.wiki_pages.create! :title => "Page #{x}" }
        mm = run_master_migration
        expect(mm.export_results[:selective][:created]['WikiPage'].length).to eq 2
      end
    end

    it "should create two exports (one selective and one full) if needed" do
      @copy_to1 = course_factory
      @template.add_child_course!(@copy_to1)

      topic = @copy_from.discussion_topics.create!(:title => "some title")

      run_master_migration
      expect(@migration.export_results.keys).to eq [:full]
      topic_to1 = @copy_to1.discussion_topics.where(:migration_id => mig_id(topic)).first
      expect(topic_to1).to be_present
      new_title = "new title"
      topic_to1.update_attribute(:title, new_title)

      page = @copy_from.wiki_pages.create!(:title => "another title")

      @copy_to2 = course_factory
      @template.add_child_course!(@copy_to2) # new child course - needs full update

      run_master_migration
      expect(@migration.export_results.keys).to match_array([:selective, :full]) # should create both

      expect(@copy_to1.wiki_pages.where(:migration_id => mig_id(page)).first).to be_present # should bring the wiki page in the selective
      expect(topic_to1.reload.title).to eq new_title # should not have have overwritten the new change in the child course

      expect(@copy_to2.discussion_topics.where(:migration_id => mig_id(topic)).first).to be_present # should bring both in the full
      expect(@copy_to2.wiki_pages.where(:migration_id => mig_id(page)).first).to be_present
    end

    it "should skip master course restriction validations on import" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      assmt = @copy_from.assignments.create!
      topic = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
      ann = @copy_from.announcements.create!(:message => "goodbye")
      page = @copy_from.wiki_pages.create!(:title => "wiki", :body => "ohai")
      quiz = @copy_from.quizzes.create!
      qq = quiz.quiz_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      bank = @copy_from.assessment_question_banks.create!(:title => 'bank')
      aq = bank.assessment_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      file = @copy_from.attachments.create!(:filename => 'blah', :uploaded_data => default_uploaded_data)
      event = @copy_from.calendar_events.create!(:title => 'thing', :description => 'blargh', :start_at => 1.day.from_now)
      tool = @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key",
        :shared_secret => "secret", :custom_fields => {'a' => '1', 'b' => '2'}, :url => "http://www.example.com")

      # TODO: make sure that we skip the validations on each importer when we add the Restrictor and
      # probably add more content here
      @template.default_restrictions = {:content => true}
      @template.save!

      run_master_migration

      copied_assmt = @copy_to.assignments.where(:migration_id => mig_id(assmt)).first
      copied_topic = @copy_to.discussion_topics.where(:migration_id => mig_id(topic)).first
      copied_ann = @copy_to.announcements.where(:migration_id => mig_id(ann)).first
      copied_page = @copy_to.wiki_pages.where(:migration_id => mig_id(page)).first
      copied_quiz = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      copied_qq = copied_quiz.quiz_questions.where(:migration_id => mig_id(qq)).first
      copied_bank = @copy_to.assessment_question_banks.where(:migration_id => mig_id(bank)).first
      copied_aq = copied_bank.assessment_questions.where(:migration_id => mig_id(aq)).first
      copied_file = @copy_to.attachments.where(:migration_id => mig_id(file)).first
      copied_event = @copy_to.calendar_events.where(:migration_id => mig_id(event)).first
      copied_tool = @copy_to.context_external_tools.where(:migration_id => mig_id(tool)).first

      copied_things = [copied_assmt, copied_topic, copied_ann, copied_page, copied_quiz,
        copied_bank, copied_file, copied_event, copied_tool]
      copied_things.each do |copy|
        expect(MasterCourses::ChildContentTag.all.polymorphic_where(:content => copy).first.migration_id).to eq copy.migration_id
      end

      new_text = "<p>some text here</p>"
      assmt.update_attribute(:description, new_text)
      topic.update_attribute(:message, new_text)
      ann.update_attribute(:message, new_text)
      page.update_attribute(:body, new_text)
      quiz.update_attribute(:description, new_text)
      event.update_attribute(:description, new_text)

      plain_text = 'plain text'
      qq.question_data = qq.question_data.tap{|qd| qd['question_text'] = plain_text}
      qq.save!
      bank.update_attribute(:title, plain_text)
      aq.question_data['question_text'] = plain_text
      aq.save!
      file.update_attribute(:display_name, plain_text)
      tool.update_attribute(:name, plain_text)

      [assmt, topic, ann, page, quiz, bank, file, event, tool].each {|c| c.class.where(:id => c).update_all(:updated_at => 2.seconds.from_now)} # ensure it gets copied

      run_master_migration # re-copy all the content and overwrite the locked stuff

      expect(copied_assmt.reload.description).to eq new_text
      expect(copied_topic.reload.message).to eq new_text
      expect(copied_ann.reload.message).to eq new_text
      expect(copied_page.reload.body).to eq new_text
      expect(copied_quiz.reload.description).to eq new_text
      expect(copied_qq.reload.question_data['question_text']).to eq plain_text
      expect(copied_bank.reload.title).to eq plain_text
      expect(copied_aq.reload.question_data['question_text']).to eq plain_text
      expect(copied_file.reload.display_name).to eq plain_text
      expect(copied_event.reload.description).to eq new_text
      expect(copied_tool.reload.name).to eq plain_text
    end

    it "should not overwrite downstream changes in child course unless locked" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      # TODO: add more content here as we add the Restrictor module to more models
      old_title = "some title"
      page = @copy_from.wiki_pages.create!(:title => old_title, :body => "ohai")
      assignment = @copy_from.assignments.create!(:title => old_title, :description => "kthnx")

      run_master_migration

      # WikiPage
      copied_page = @copy_to.wiki_pages.where(:migration_id => mig_id(page)).first
      child_tag = sub.child_content_tags.polymorphic_where(:content => copied_page).first
      expect(child_tag).to be_present # should create a tag
      new_child_text = "<p>some other text here</p>"
      copied_page.update_attribute(:body, new_child_text)
      child_tag.reload
      expect(child_tag.downstream_changes).to include('body')

      new_master_text = "<p>some text or something</p>"
      page.update_attribute(:body, new_master_text)
      new_master_title = "some new title"
      page.update_attribute(:title, new_master_title)

      # Assignment
      copied_assignment = @copy_to.assignments.where(:migration_id => mig_id(assignment)).first
      child_tag = sub.child_content_tags.polymorphic_where(:content => copied_assignment).first
      expect(child_tag).to be_present # should create a tag
      new_child_text = "<p>some other text here</p>"
      copied_assignment.update_attribute(:description, new_child_text)
      child_tag.reload
      expect(child_tag.downstream_changes).to include('description')

      new_master_text = "<p>some text or something</p>"
      assignment.update_attribute(:description, new_master_text)
      new_master_title = "some new title"
      assignment.update_attribute(:title, new_master_title)

      # Ensure each object gets marked for copy
      [page, assignment].each {|c| c.class.where(:id => c).update_all(:updated_at => 2.seconds.from_now)}

      run_master_migration # re-copy all the content but don't actually overwrite the downstream change
      expect(@migration.migration_results.first.skipped_items).to match_array([mig_id(assignment), mig_id(page)])

      expect(copied_page.reload.body).to eq new_child_text # should have been left alone
      expect(copied_page.title).to eq old_title # even the title

      expect(copied_assignment.reload.description).to eq new_child_text # should have been left alone
      expect(copied_assignment.title).to eq old_title # even the title

      [page, assignment].each do |c|
        mtag = @template.content_tag_for(c)
        Timecop.freeze(2.seconds.from_now) do
          mtag.update_attribute(:restrictions, {:content => true}) # should touch the content
        end
      end

      run_master_migration # re-copy all the content but this time overwrite the downstream change because we locked it
      expect(@migration.migration_results.first.skipped_items).to be_empty

      expect(copied_assignment.reload.description).to eq new_master_text
      expect(copied_assignment.title).to eq new_master_title
      expect(copied_page.reload.body).to eq new_master_text
      expect(copied_page.title).to eq new_master_title # even the title
    end

    it "overwrites/removes availability dates and settings when pushing a locked quiz" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)
      dates1 = [1.day.ago, 1.day.from_now, 2.days.from_now].map(&:beginning_of_day)
      dates2 = [2.days.ago, 3.days.from_now, 5.days.from_now].map(&:beginning_of_day)

      quiz1 = @copy_from.quizzes.create!(:unlock_at => dates1[0], :due_at => dates1[1], :lock_at => dates1[2])
      quiz2 = @copy_from.quizzes.create!
      run_master_migration

      cq1 = @copy_to.quizzes.where(migration_id: mig_id(quiz1)).first
      cq2 = @copy_to.quizzes.where(migration_id: mig_id(quiz2)).first

      Timecop.travel(5.minutes.from_now) do
        cq1.update_attributes(:unlock_at => dates2[0], :due_at => dates2[1], :lock_at => dates2[2])
        cq2.update_attributes(:unlock_at => dates2[0], :due_at => dates2[1], :lock_at => dates2[2], :ip_filter => '10.0.0.1/24', :hide_correct_answers_at => 1.week.from_now)
      end

      Timecop.travel(10.minutes.from_now) do
        @template.content_tag_for(quiz1).update_attribute(:restrictions, {:availability_dates => true, :due_dates => true})
        @template.content_tag_for(quiz2).update_attribute(:restrictions, {:availability_dates => true, :due_dates => true, :settings => true})

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
      sub = @template.add_child_course!(@copy_to)
      assmt = @copy_from.assignments.create!(:due_at => 1.day.from_now, :unlock_at => 1.day.ago, :lock_at => 1.day.from_now)
      run_master_migration

      assmt_to = @copy_to.assignments.where(migration_id: mig_id(assmt)).first
      expect(assmt_to.due_at).not_to be_nil

      Timecop.travel(5.minutes.from_now) do
        @template.content_tag_for(assmt).update_attribute(:restrictions, {:availability_dates => true, :due_dates => true})
        assmt.update_attributes(:due_at => nil, :unlock_at => nil, :lock_at => nil)
      end

      Timecop.travel(10.minutes.from_now) do
        run_master_migration
      end

      assmt_to.reload
      expect(assmt_to.due_at).to be_nil
      expect(assmt_to.lock_at).to be_nil
      expect(assmt_to.unlock_at).to be_nil
    end

    it "should count downstream changes to quiz/assessment questions as changes in quiz/bank content" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!
      qq = quiz.quiz_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      bank = @copy_from.assessment_question_banks.create!(:title => 'bank')
      aq = bank.assessment_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})

      run_master_migration

      copied_quiz = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      copied_qq = copied_quiz.quiz_questions.where(:migration_id => mig_id(qq)).first
      copied_bank = @copy_to.assessment_question_banks.where(:migration_id => mig_id(bank)).first
      copied_aq = copied_bank.assessment_questions.where(:migration_id => mig_id(aq)).first

      new_child_text = "some childish text"
      copied_aq.question_data['question_text'] = new_child_text
      copied_aq.save!
      copied_qd = copied_qq.question_data
      copied_qd['question_text'] = new_child_text
      copied_qq.question_data = copied_qd
      copied_qq.save!

      bank_child_tag = sub.child_content_tags.polymorphic_where(:content => copied_bank).first
      expect(bank_child_tag.downstream_changes).to include("assessment_questions_content") # treats all assessment questions like a column
      quiz_child_tag = sub.child_content_tags.polymorphic_where(:content => copied_quiz).first
      expect(quiz_child_tag.downstream_changes).to include("quiz_questions_content") # treats all assessment questions like a column

      new_master_text = "some mastery text"
      bank.update_attribute(:title, new_master_text)
      aq.question_data['question_text'] = new_master_text
      aq.save!
      quiz.update_attribute(:title, new_master_text)
      qd = qq.question_data
      qd['question_text'] = new_master_text
      qq.question_data = qd
      qq.save!

      [bank, quiz].each {|c| c.class.where(:id => c).update_all(:updated_at => 2.seconds.from_now)} # ensure it gets copied

      run_master_migration # re-copy all the content - but don't actually overwrite anything because it got changed downstream

      expect(copied_bank.reload.title).to_not eq new_master_text
      expect(copied_aq.reload.question_data['question_text']).to_not eq new_master_text
      expect(copied_quiz.reload.title).to_not eq new_master_text
      expect(copied_qq.reload.question_data['question_text']).to_not eq new_master_text

      [bank, quiz].each do |c|
        mtag = @template.content_tag_for(c)
        Timecop.freeze(2.seconds.from_now) do
          mtag.update_attribute(:restrictions, {:content => true}) # should touch the content
        end
      end

      run_master_migration # re-copy all the content - and this time overwrite everything because it's locked

      expect(copied_bank.reload.title).to eq new_master_text
      expect(copied_aq.reload.question_data['question_text']).to eq new_master_text
      expect(copied_quiz.reload.title).to eq new_master_text
      expect(copied_qq.reload.question_data['question_text']).to eq new_master_text
    end

    it "should handle graded quizzes/discussions/etc better" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      old_due_at = 5.days.from_now

      quiz_assmt = @copy_from.assignments.create!(:due_at => old_due_at, :submission_types => 'online_quiz').reload
      quiz = quiz_assmt.quiz
      topic = @copy_from.discussion_topics.new
      topic.assignment = @copy_from.assignments.build(:due_at => old_due_at)
      topic.save!
      topic_assmt = topic.assignment

      run_master_migration

      copied_quiz = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      copied_quiz_assmt = copied_quiz.assignment
      expect(copied_quiz_assmt.migration_id).to eq copied_quiz.migration_id # should use the same migration id = same restrictions
      copied_topic = @copy_to.discussion_topics.where(:migration_id => mig_id(topic)).first
      copied_topic_assmt = copied_topic.assignment
      expect(copied_topic_assmt.migration_id).to eq copied_topic.migration_id # should use the same migration id = same restrictions

      new_title = "new master title"
      quiz.update_attribute(:title, new_title)
      topic.update_attribute(:title, new_title)
      [quiz, topic].each {|c| c.class.where(:id => c).update_all(:updated_at => 2.seconds.from_now)} # ensure it gets copied

      run_master_migration

      expect(copied_quiz_assmt.reload.title).to eq new_title # should carry the new title over to the assignments
      expect(copied_topic_assmt.reload.title).to eq new_title

      quiz_child_tag = sub.child_content_tags.polymorphic_where(:content => copied_quiz).first
      topic_child_tag = sub.child_content_tags.polymorphic_where(:content => copied_topic).first
      [quiz_child_tag, topic_child_tag].each do |tag|
        expect(tag.downstream_changes).to be_empty
      end

      new_child_due_at = 7.days.from_now
      copied_quiz.update_attribute(:due_at, new_child_due_at)
      copied_topic_assmt.update_attribute(:due_at, new_child_due_at)

      [quiz_child_tag, topic_child_tag].each do |tag|
        expect(tag.reload.downstream_changes).to include('due_at') # store the downstream changes on
      end

      new_master_due_at = 10.days.from_now
      quiz.update_attribute(:due_at, new_master_due_at)
      topic_assmt.update_attribute(:due_at, new_master_due_at)
      [quiz, topic].each {|c| c.class.where(:id => c).update_all(:updated_at => 2.seconds.from_now)} # ensure it gets copied

      run_master_migration # re-copy all the content - but don't actually overwrite anything because it got changed downstream

      expect(copied_quiz_assmt.reload.due_at.to_i).to eq new_child_due_at.to_i # didn't get overwritten
      expect(copied_topic_assmt.reload.due_at.to_i).to eq new_child_due_at.to_i # didn't get overwritten

      [quiz, topic].each do |c|
        mtag = @template.content_tag_for(c)
        Timecop.freeze(2.seconds.from_now) do
          mtag.update_attribute(:restrictions, {:due_dates => true}) # lock the quiz/topic master tags
        end
      end

      run_master_migration # now, overwrite the due_at's because the tags are locked

      expect(copied_quiz_assmt.reload.due_at.to_i).to eq new_master_due_at.to_i # should have gotten overwritten
      expect(copied_topic_assmt.reload.due_at.to_i).to eq new_master_due_at.to_i
    end

    it "should ignore course settings on selective export unless requested" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @copy_from.tab_configuration = [{"id"=>0}, {"id"=>14}, {"id"=>8}, {"id"=>5}, {"id"=>6}, {"id"=>2}, {"id"=>3, "hidden"=>true}]
      @copy_from.start_at = 1.month.ago.beginning_of_day
      @copy_from.conclude_at = 1.month.from_now.beginning_of_day
      @copy_from.restrict_enrollments_to_course_dates = true
      @copy_from.save!
      run_master_migration(:copy_settings => false) # initial sync with explicit false
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

      run_master_migration(:copy_settings => true) # selective with settings
      expect(@copy_to.reload.is_public).to be_truthy
      expect(@copy_to.start_at).to eq @copy_from.start_at
      expect(@copy_to.conclude_at).to eq @copy_from.conclude_at
      expect(@copy_to.restrict_enrollments_to_course_dates).to be_truthy

      run_master_migration # selective without settings
      expect(@copy_to.reload.start_at).to_not be_nil # keep the dates
      expect(@copy_to.conclude_at).to_not be_nil

      Timecop.freeze(1.minute.from_now) do
        @copy_from.update_attributes(:start_at => nil, :conclude_at => nil)
      end
      run_master_migration(:copy_settings => true) # selective with settings
      expect(@copy_to.reload.start_at).to be_nil # remove the dates
      expect(@copy_to.conclude_at).to be_nil
    end

    it "should copy front wiki pages" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @page = @copy_from.wiki_pages.create!(:title => "first page")
      @page.set_as_front_page!
      @copy_from.update_attribute(:default_view, 'wiki')

      run_master_migration(:copy_settings => true)

      expect(@copy_to.reload.default_view).to eq 'wiki'
      @page_copy = @copy_to.wiki_pages.where(:migration_id => mig_id(@page)).first
      expect(@copy_to.wiki.front_page).to eq @page_copy

      Timecop.freeze(1.minute.from_now) do
        @page2 = @copy_from.wiki_pages.create!(:title => "second page")
        @page2.set_as_front_page!
      end

      run_master_migration

      @page2_copy = @copy_to.wiki_pages.where(:migration_id => mig_id(@page2)).first
      expect(@copy_to.wiki.reload.front_page).to eq @page2_copy

      Timecop.freeze(2.minutes.from_now) do
        @copy_from.wiki.reload.unset_front_page! # should unset on associated course
      end

      run_master_migration

      expect(@copy_to.wiki.reload.front_page).to be_nil
    end

    it "should change front wiki pages unless it gets changed downstream" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @page = @copy_from.wiki_pages.create!(:title => "first page")
      @page.set_as_front_page!

      run_master_migration

      Timecop.freeze(10.seconds.from_now) do
        @page.update_attributes(:title => "new title", :url => "new_url")
        @page.set_as_front_page! # change the url but keep as front page
      end

      run_master_migration

      @page_copy = @copy_to.wiki_pages.where(:migration_id => mig_id(@page)).first
      expect(@page_copy.title).to eq "new title"
      expect(@copy_to.wiki.reload.front_page).to eq @page_copy

      @copy_to.wiki.unset_front_page! # set downstream change

      Timecop.freeze(20.seconds.from_now) do
        @page.update_attributes(:title => "another new title", :url => "another_new_url")
        @page.set_as_front_page!
      end

      run_master_migration

      expect(@copy_to.wiki.reload.front_page_url).to be nil # should leave alone
    end

    it "shouldn't overwrite syllabus body if already present or changed" do
      @copy_to1 = course_factory
      @template.add_child_course!(@copy_to1)

      @copy_to2 = course_factory
      child_syllabus1 = "<p>some child syllabus</p>"
      @template.add_child_course!(@copy_to2)
      @copy_to2.update_attribute(:syllabus_body, child_syllabus1)

      master_syllabus1 = "<p>some original syllabus</p>"
      @copy_from.update_attribute(:syllabus_body, master_syllabus1)
      run_master_migration
      expect(@copy_to1.reload.syllabus_body).to eq master_syllabus1 # use the master syllabus
      expect(@copy_to2.reload.syllabus_body).to eq child_syllabus1 # keep the existing one

      master_syllabus2 = "<p>some new syllabus</p>"
      @copy_from.update_attribute(:syllabus_body, master_syllabus2)
      run_master_migration
      expect(@copy_to1.reload.syllabus_body).to eq master_syllabus2 # keep syncing
      expect(@copy_to2.reload.syllabus_body).to eq child_syllabus1

      child_syllabus2 = "<p>syllabus is a weird word</p>"
      @copy_to1.update_attribute(:syllabus_body, child_syllabus2)
      run_master_migration
      expect(@copy_to1.reload.syllabus_body).to eq child_syllabus2 # preserve the downstream change
    end

    it "should trigger folder locking data cache invalidation" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      enable_cache do
        expect(MasterCourses::FolderHelper.locked_folder_ids_for_course(@copy_to)).to be_empty

        master_parent_folder = Folder.root_folders(@copy_from).first.sub_folders.create!(:name => "parent", :context => @copy_from)
        master_sub_folder = master_parent_folder.sub_folders.create!(:name => "child", :context => @copy_from)
        att = Attachment.create!(:filename => 'file.txt', :uploaded_data => StringIO.new('1'), :folder => master_sub_folder, :context => @copy_from)
        att_tag = @template.create_content_tag_for!(att, :restrictions => {:all => true})

        run_master_migration

        copied_att = @copy_to.attachments.where(:migration_id => att_tag.migration_id).first
        child_sub_folder = copied_att.folder
        child_parent_folder = child_sub_folder.parent_folder
        expected_ids = [child_sub_folder, child_parent_folder, Folder.root_folders(@copy_to).first].map(&:id)
        expect(Folder.connection).to receive(:select_values).never # should have already been cached in migration
        expect(MasterCourses::FolderHelper.locked_folder_ids_for_course(@copy_to)).to match_array(expected_ids)
      end
    end

    it "propagates folder name and state changes" do
      master_parent_folder = nil
      att_tag = nil
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      Timecop.travel(10.minutes.ago) do
        master_parent_folder = Folder.root_folders(@copy_from).first.sub_folders.create!(:name => "parent", :context => @copy_from)
        master_sub_folder = master_parent_folder.sub_folders.create!(:name => "child", :context => @copy_from)
        att = Attachment.create!(:filename => 'file.txt', :uploaded_data => StringIO.new('1'), :folder => master_sub_folder, :context => @copy_from)
        att_tag = @template.create_content_tag_for!(att)
        run_master_migration
      end

      master_parent_folder.update_attributes(:name => "parent RENAMED", :locked => true)
      master_parent_folder.sub_folders.create!(:name => "empty", :context => @copy_from)

      run_master_migration

      copied_att = @copy_to.attachments.where(:migration_id => att_tag.migration_id).first
      expect(copied_att.full_path).to eq "course files/parent RENAMED/child/file.txt"
      expect(@copy_to.folders.where(:name => "parent RENAMED").first.locked).to eq true
    end

    it "should baleet assignment overrides when an admin pulls a bait-n-switch with date restrictions" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      topic = @copy_from.discussion_topics.new
      topic.assignment = @copy_from.assignments.build
      topic.save!
      topic_assmt = topic.assignment
      normal_assmt = @copy_from.assignments.create!

      run_master_migration

      copied_topic = @copy_to.discussion_topics.where(:migration_id => mig_id(topic)).first
      copied_topic_assmt = copied_topic.assignment
      copied_normal_assmt = @copy_to.assignments.where(:migration_id => mig_id(normal_assmt)).first

      topic_override = create_section_override_for_assignment(copied_topic_assmt)
      normal_override = create_section_override_for_assignment(copied_normal_assmt)

      new_title = "new master title"
      topic.update_attribute(:title, new_title)
      normal_assmt.update_attribute(:title, new_title)
      [topic, normal_assmt].each {|c| c.class.where(:id => c).update_all(:updated_at => 2.seconds.from_now)} # ensure it gets copied

      run_master_migration

      expect(copied_topic_assmt.reload.title).to eq new_title
      expect(copied_normal_assmt.reload.title).to eq new_title
      [topic_override, normal_override].each { |ao| expect(ao.reload).to be_active } # leave the overrides alone

      [topic, normal_assmt].each do |c|
        Timecop.freeze(3.seconds.from_now) do
          @template.content_tag_for(c).update_attributes(:restrictions => {:content => true, :availability_dates => true}) # tightening the restrictions should touch it by default
        end
      end

      run_master_migration

      [topic_override, normal_override].each { |ao| expect(ao.reload).to be_deleted }
    end

    it "should work with a single full export for a new association" do
      @copy_to1 = course_factory
      sub1 = @template.add_child_course!(@copy_to1)
      topic = @copy_from.discussion_topics.create!(:title => "some title")

      run_master_migration

      sub1.destroy!
      @copy_to2 = course_factory
      @template.add_child_course!(@copy_to2)

      run_master_migration
      expect(@copy_to2.discussion_topics.first).to be_present
    end

    it "should link assignment rubrics on update" do
      Timecop.freeze(10.minutes.ago) do
        @copy_to = course_factory
        @template.add_child_course!(@copy_to)
        @assmt = @copy_from.assignments.create!
      end
      Timecop.freeze(8.minutes.ago) do
        run_master_migration # copy the assignment
      end

      assignment_to = @copy_to.assignments.where(:migration_id => mig_id(@assmt)).first
      expect(assignment_to).to be_present

      @course = @copy_from
      outcome_with_rubric
      @ra = @rubric.associate_with(@assmt, @copy_from, purpose: 'grading')

      run_master_migration # copy the rubric

      rubric_to = @copy_to.rubrics.where(:migration_id => mig_id(@rubric)).first
      expect(rubric_to).to be_present
      expect(assignment_to.reload.rubric).to eq rubric_to

      Timecop.freeze(5.minutes.from_now) do
        @ra.destroy # unlink the rubric
        run_master_migration
      end
      expect(assignment_to.reload.rubric).to eq nil

      # create another rubric - it should leave alone
      other_rubric = outcome_with_rubric(:course => @copy_to)
      other_rubric.associate_with(assignment_to, @copy_to, purpose: 'grading', use_for_grading: true)

      Assignment.where(:id => @assmt).update_all(:updated_at => 10.minutes.from_now)
      run_master_migration
      expect(assignment_to.reload.rubric).to eq other_rubric
    end

    it "shouldn't delete module items in associated courses" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)
      mod = @copy_from.context_modules.create!(:name => "module")

      run_master_migration

      mod_to = @copy_to.context_modules.where(:migration_id => mig_id(mod)).first
      tag = mod_to.add_item(type: 'context_module_sub_header', title: 'header')

      Timecop.freeze(2.seconds.from_now) do
        mod.update_attribute(:name, "new title")
      end
      run_master_migration
      expect(tag.reload).to_not be_deleted
    end

    it "should be able to delete modules" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)
      mod = @copy_from.context_modules.create!(:name => "module")

      run_master_migration

      mod_to = @copy_to.context_modules.where(:migration_id => mig_id(mod)).first
      expect(mod_to).to be_active

      mod.destroy

      run_master_migration
      expect(@migration).to be_completed
      expect(mod_to.reload).to be_deleted
    end

    it "should copy outcomes in selective copies" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      default = @copy_from.root_outcome_group
      log = @copy_from.learning_outcome_groups.create!(:context => @copy_from, :title => "outcome groupd")
      default.adopt_outcome_group(log)

      run_master_migration # get the full sync out of the way

      Timecop.freeze(1.minute.from_now) do
        @lo = @copy_from.created_learning_outcomes.new(:context => @copy_from, :short_description => "whee", :workflow_state => 'active')
        @lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2},
          {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
        @lo.save!
        log.reload.add_outcome(@lo)
      end

      run_master_migration
      expect(@migration).to be_completed
      lo_to = @copy_to.learning_outcomes.where(:migration_id => mig_id(@lo)).first
      expect(lo_to).to be_present
    end

    it "preserves account question bank references" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!(:title => 'quiz')
      bank = @copy_from.account.assessment_question_banks.create!(:title => 'bank')

      bank.assessment_question_bank_users.create!(:user => @user)
      group = quiz.quiz_groups.create!(:name => "group", :pick_count => 5, :question_points => 2.0)
      group.assessment_question_bank = bank
      group.save

      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      group_to = quiz_to.quiz_groups.first
      expect(group_to.assessment_question_bank_id).to eq bank.id
    end

    it "resets generated quiz questions on assessment question re-import" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!(:title => 'quiz')
      bank = @copy_from.assessment_question_banks.create!(:title => 'bank')
      aq = bank.assessment_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      group = quiz.quiz_groups.create!(:name => "group", :pick_count => 1, :question_points => 2.0)
      group.assessment_question_bank = bank
      group.save
      quiz.publish!

      run_master_migration

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      student1 = user_factory
      quiz_to.generate_submission(student1) # generates quiz questions from the bank questions

      new_text = 'something new'
      Timecop.freeze(2.minutes.from_now) do
        aq.update_attribute(:question_data, aq.question_data.merge('question_text' => new_text))
      end

      run_master_migration

      student2 = user_factory
      sub = quiz_to.generate_submission(student2)
      expect(sub.quiz_data.first["question_text"]).to eq new_text
    end

    it "syncs quiz_groups with points locked" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      quiz = @copy_from.quizzes.create!(:title => 'quiz')
      bank = @copy_from.assessment_question_banks.create!(:title => 'bank')
      aq = bank.assessment_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      group = quiz.quiz_groups.create!(:name => "group", :pick_count => 1, :question_points => 2.0)
      group.assessment_question_bank = bank
      group.save
      tag = @template.create_content_tag_for!(quiz, restrictions: {content: false, points: true})

      mm = run_master_migration
      expect(mm.migration_results.first.content_migration.warnings).to be_empty

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).take
      qg_to = quiz_to.quiz_groups.first # note: it's migration_id isn't mig_id(group) because qti_generator is an oddball. oh well.

      expect(qg_to.question_points).to eq 2.0
      qg_to.question_points = 3.0
      expect(qg_to.save).to be false
      expect(qg_to.errors.first.second).to eq "cannot change column(s): question_points - locked by Master Course"
    end

    it "copies tab configurations for account-level external tools" do
      @tool_from = @copy_from.account.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :custom_fields => {'a' => '1', 'b' => '2'}, :url => "http://www.example.com")
      @tool_from.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      @tool_from.save!

      @copy_from.tab_configuration = [{"id" =>0 }, {"id" => "context_external_tool_#{@tool_from.id}", "hidden" => true}, {"id" => 14}]
      @copy_from.save!

      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      run_master_migration
      expect(@copy_to.reload.tab_configuration).to eq @copy_from.tab_configuration
    end

    it "should not break trying to match existing attachments on cloned_item_id" do
      # this was 'fun' to debug - i'm still not quite sure how it came about
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)
      att1 = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'),
        :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)

      run_master_migration

      att_to = @copy_to.attachments.where(:migration_id => mig_id(att1)).first
      expect(att_to.cloned_item_id).to eq att1.reload.cloned_item_id # i still don't know why we set this

      sub.destroy

      @copy_from2 = course_factory
      @template2 = MasterCourses::MasterTemplate.set_as_master_course(@copy_from2)
      att2 = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'),
        :folder => Folder.unfiled_folder(@copy_from2), :context => @copy_from2, :cloned_item_id => att1.cloned_item_id)
      sub2 = @template2.add_child_course!(@copy_to)

      MasterCourses::MasterMigration.start_new_migration!(@template2, @admin)
      run_jobs

      expect(@copy_to.content_migrations.last.migration_issues).to_not be_exists
      att2_to = @copy_to.attachments.where(:migration_id => @template2.migration_id_for(att2)).first
      expect(att2_to).to be_present
    end

    it "should link to existing outcomes even when some weird migration_id thing happens" do
      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)

      allow(AcademicBenchmark).to receive(:use_new_guid_columns?).and_return(true) # what is this

      lo = @copy_from.created_learning_outcomes.new(:context => @copy_from, :short_description => "whee", :workflow_state => 'active')
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2},
        {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!
      from_root = @copy_from.root_outcome_group
      from_root.add_outcome(lo)

      LearningOutcome.where(:id => lo).update_all(:updated_at => 1.minute.ago)

      run_master_migration

      lo_to = @copy_to.created_learning_outcomes.where(:migration_id_2 => mig_id(lo)).first # what is that

      rub = Rubric.new(:context => @copy_from)
      rub.data = [{
        :points => 3, :description => "Outcome row", :id => 2,
        :ratings => [{:points => 3,:description => "meep",:criterion_id => 2,:id => 3}], :ignore_for_scoring => true,
        :learning_outcome_id => lo.id
      }]
      rub.save!
      rub.associate_with(@copy_from, @copy_from)

      run_master_migration

      rub_to = @copy_to.rubrics.where(:migration_id => mig_id(rub)).first
      expect(rub_to.data.first["learning_outcome_id"]).to eq lo_to.id
      expect(rub_to.learning_outcome_alignments.first.learning_outcome_id).to eq lo_to.id
    end

    it "should sync workflow states more betterisher" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      assmt = @copy_from.assignments.create!
      topic = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
      page = @copy_from.wiki_pages.create!(:title => "wiki", :body => "ohai")
      quiz = @copy_from.quizzes.create!(:workflow_state => 'available')
      file = @copy_from.attachments.create!(:filename => 'blah', :uploaded_data => default_uploaded_data)
      mod = @copy_from.context_modules.create!(:name => "module")
      tag = mod.add_item(type: 'context_module_sub_header', title: 'header')
      tag.publish!

      run_master_migration

      copied_assmt = @copy_to.assignments.where(:migration_id => mig_id(assmt)).first
      copied_topic = @copy_to.discussion_topics.where(:migration_id => mig_id(topic)).first
      copied_page = @copy_to.wiki_pages.where(:migration_id => mig_id(page)).first
      copied_quiz = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first
      copied_file = @copy_to.attachments.where(:migration_id => mig_id(file)).first
      copied_mod = @copy_to.context_modules.where(:migration_id => mig_id(mod)).first
      copied_tag = @copy_to.context_module_tags.where(:migration_id => mig_id(tag)).first
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
        assmt.update_attribute(:workflow_state, 'published')
        quiz.update_attribute(:workflow_state, 'available')
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

      mod1 = @copy_from.context_modules.create! :name => 'wun'
      mod2 = @copy_from.context_modules.create! :name => 'too'

      run_master_migration

      mod1_to = @copy_to.context_modules.where(:migration_id => mig_id(mod1)).first
      mod2_to = @copy_to.context_modules.where(:migration_id => mig_id(mod2)).first

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

    it "should copy the lack of a module unlock date" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      mod = @copy_from.context_modules.create!(:name => 'm', :unlock_at => 3.days.from_now)
      run_master_migration
      mod_to = @copy_to.context_modules.where(:migration_id => mig_id(mod)).first

      Timecop.freeze(1.minute.from_now) do
        mod.update_attribute(:unlock_at, nil)
      end
      run_master_migration
      expect(mod_to.reload.unlock_at).to be_nil
    end

    it "should work with links to files copied in previous sync" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      Timecop.freeze(1.minute.ago) do
        @att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      end
      run_master_migration

      @att_copy = @copy_to.attachments.where(:migration_id => mig_id(@att)).first
      expect(@att_copy).to be_present

      Timecop.freeze(1.minute.from_now) do
        @topic = @copy_from.discussion_topics.create!(:title => "some topic", :message => "<img src='/courses/#{@copy_from.id}/files/#{@att.id}/download?wrap=1'>")
      end
      run_master_migration

      @topic_copy = @copy_to.discussion_topics.where(:migration_id => mig_id(@topic)).first
      expect(@topic_copy.message).to include("/courses/#{@copy_to.id}/files/#{@att_copy.id}/download?wrap=1")
    end

    it "should replace module item contents when file is replaced" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      @mod = @copy_from.context_modules.create!
      @tag = @mod.add_item(:id => @att.id, :type => 'attachment')

      run_master_migration

      @att_copy = @copy_to.attachments.where(:migration_id => mig_id(@att)).first
      @tag_copy = @copy_to.context_module_tags.where(:migration_id => mig_id(@tag)).first
      expect(@tag_copy.content).to eq @att_copy

      Timecop.freeze(1.minute.from_now) do
        @new_att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
        @new_att.handle_duplicates(:overwrite)
      end
      expect(@tag.reload.content).to eq @new_att

      run_master_migration

      @new_att_copy = @copy_to.attachments.where(:migration_id => mig_id(@new_att)).first
      expect(@tag_copy.reload.content).to eq @new_att_copy
    end

    it "should export account-level linked outcomes in a selective migration" do
      Timecop.freeze(1.minute.ago) do
        @acc_outcome = @copy_from.account.created_learning_outcomes.create!(:short_description => "womp")
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

      ag = @copy_from.assignment_groups.create!(:name => "group")
      a = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => ag.id)
      ag.update_attribute(:rules, "drop_lowest:1\nnever_drop:#{a.id}\n")

      run_master_migration

      ag_to = @copy_to.assignment_groups.where(:migration_id => mig_id(ag)).first
      a_to = @copy_to.assignments.where(:migration_id => mig_id(a)).first

      Timecop.freeze(30.seconds.from_now) do
        ag.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{a.id}\n")
      end

      run_master_migration
      expect(ag_to.reload.rules).to eq "drop_lowest:2\nnever_drop:#{a_to.id}\n"

      Timecop.freeze(60.seconds.from_now) do
        ag.update_attribute(:rules, "never_drop:#{a.id}\n")
      end
      run_master_migration
      expect(ag_to.reload.rules).to eq nil # set to empty if there are no dropping rules
    end

    it "doesn't clear external tool config on exception" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      a = @copy_from.assignments.create!(:title => "some assignment")
      run_master_migration
      a_to = @copy_to.assignments.where(:migration_id => mig_id(a)).first

      Timecop.freeze(60.seconds.from_now) do
        a.touch
      end

      tool = @copy_to.context_external_tools.create!(:name => 'some tool', :consumer_key => 'test_key',
        :shared_secret => 'test_secret', :url => 'http://example.com/launch')
      a_to.update_attributes(:submission_types => 'external_tool', :external_tool_tag_attributes => {:content => tool})
      tag = a_to.external_tool_tag

      run_master_migration

      expect(a_to.reload.external_tool_tag).to eq tag # don't change
    end

    it "sends notifications", priority: "2", test_id: 3211103 do
      n0 = Notification.create(:name => "Blueprint Sync Complete")
      n1 = Notification.create(:name => "Blueprint Content Added")
      @admin = @user
      course_with_teacher :active_all => true
      sub = @template.add_child_course!(@course)
      cc0 = @admin.communication_channels.create(:path => "test_#{@admin.id}@example.com", :path_type => "email")
      cc0.confirm
      cc1 = @user.communication_channels.create(:path => "test_#{@user.id}@example.com", :path_type => "email")
      cc1.confirm
      run_master_migration :comment => "ohai eh", :send_notification => true
      expect(DelayedMessage.where(notification_id: n0, communication_channel_id: cc0).last.summary).to include "ohai eh"
      expect(DelayedMessage.where(notification_id: n1, communication_channel_id: cc1).last.summary).to include "ohai eh"
    end

    context "master courses + external migrations" do
      class TestExternalContentService
        cattr_reader :course, :migration, :imported_content
        def self.send_imported_content(course, migration, imported_content)
          @@course = course
          @@migration = migration
          @@imported_content = imported_content
        end
      end

      before :each do
        allow(Canvas::Migration::ExternalContent::Migrator).to receive(:registered_services).and_return({'test_service' => TestExternalContentService})
      end

      it "should work" do
        @copy_to = course_factory
        @template.add_child_course!(@copy_to)

        assmt = @copy_from.assignments.create!
        topic = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
        ann = @copy_from.announcements.create!(:message => "goodbye")
        cm = @copy_from.context_modules.create!(:name => "some module")
        item = cm.add_item(:id => assmt.id, :type => 'assignment')
        att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
        page = @copy_from.wiki_pages.create!(:title => "wiki", :body => "ohai")
        quiz = @copy_from.quizzes.create!

        allow(TestExternalContentService).to receive(:applies_to_course?).and_return(true)
        allow(TestExternalContentService).to receive(:begin_export).and_return(true)

        data = {
          '$canvas_assignment_id' => assmt.id,
          '$canvas_discussion_topic_id' => topic.id,
          '$canvas_announcement_id' => ann.id,
          '$canvas_context_module_id' => cm.id,
          '$canvas_context_module_item_id' => item.id,
          '$canvas_file_id' => att.id, # $canvas_attachment_id works too
          '$canvas_page_id' => page.id,
          '$canvas_quiz_id' => quiz.id
        }
        allow(TestExternalContentService).to receive(:export_completed?).and_return(true)
        allow(TestExternalContentService).to receive(:retrieve_export).and_return(data)

        run_master_migration

        copied_assmt = @copy_to.assignments.where(:migration_id => mig_id(assmt)).first
        copied_topic = @copy_to.discussion_topics.where(:migration_id => mig_id(topic)).first
        copied_ann = @copy_to.announcements.where(:migration_id => mig_id(ann)).first
        copied_cm = @copy_to.context_modules.where(:migration_id => mig_id(cm)).first
        copied_item = @copy_to.context_module_tags.where(:migration_id => mig_id(item)).first
        copied_att = @copy_to.attachments.where(:migration_id => mig_id(att)).first
        copied_page = @copy_to.wiki_pages.where(:migration_id => mig_id(page)).first
        copied_quiz = @copy_to.quizzes.where(:migration_id => mig_id(quiz)).first

        expect(TestExternalContentService.course).to eq @copy_to

        expected_data = {
          '$canvas_assignment_id' => copied_assmt.id,
          '$canvas_discussion_topic_id' => copied_topic.id,
          '$canvas_announcement_id' => copied_ann.id,
          '$canvas_context_module_id' => copied_cm.id,
          '$canvas_context_module_item_id' => copied_item.id,
          '$canvas_file_id' => copied_att.id, # $canvas_attachment_id works too
          '$canvas_page_id' => copied_page.id,
          '$canvas_quiz_id' => copied_quiz.id
        }
        expect(TestExternalContentService.imported_content).to eq expected_data
      end
    end
  end
end
