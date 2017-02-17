require 'spec_helper'

describe MasterCourses::MasterMigration do
  before :once do
    course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
  end

  before :each do
    skip unless Qti.qti_enabled?
  end

  describe "start_new_migration!" do
    it "should queue a migration" do
      user_factory
      MasterCourses::MasterMigration.any_instance.expects(:queue_export_job).once
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

      MasterCourses::MasterMigration.any_instance.expects(:queue_export_job).never
      expect {
        MasterCourses::MasterMigration.start_new_migration!(@template)
      }.to raise_error("cannot start new migration while another one is running")
    end

    it "should still allow if the 'active' migration has been running for a while (and is probably ded)" do
      running = @template.master_migrations.create!(:workflow_state => "exporting")
      @template.active_migration = running
      @template.save!

      Timecop.freeze(2.days.from_now) do
        MasterCourses::MasterMigration.any_instance.expects(:queue_export_job).once
        MasterCourses::MasterMigration.start_new_migration!(@template)
      end
    end

    it "should queue a job" do
      expect { MasterCourses::MasterMigration.start_new_migration!(@template) }.to change(Delayed::Job, :count).by(1)
      MasterCourses::MasterMigration.any_instance.expects(:perform_exports).once
      run_jobs
    end
  end

  describe "perform_exports" do
    before :once do
      @migration = @template.master_migrations.create!
    end

    it "shouldn't do anything if there aren't any child courses to push to" do
      @migration.expects(:create_export).never
      @migration.perform_exports
      @migration.reload
      expect(@migration).to be_completed
      expect(@migration.export_results[:message]).to eq "No child courses to export to"
    end

    it "shouldn't count deleted subscriptions" do
      other_course = course_factory
      sub = @template.add_child_course!(other_course)
      sub.destroy!

      @migration.expects(:create_export).never
      @migration.perform_exports
    end

    it "should record errors" do
      other_course = course_factory
      @template.add_child_course!(other_course)
      @migration.stubs(:create_export).raises "oh neos"
      expect { @migration.perform_exports }.to raise_error("oh neos")

      @migration.reload
      expect(@migration).to be_exports_failed
      expect(ErrorReport.find(@migration.export_results[:error_report_id]).message).to eq "oh neos"
    end

    it "should do a full export by default" do
      new_course = course_factory
      new_sub = @template.add_child_course!(new_course)

      @migration.expects(:export_to_child_courses).with(:full, [new_sub], true)
      @migration.perform_exports
    end

    it "should do a selective export based on subscriptions" do
      old_course = course_factory
      sel_sub = @template.add_child_course!(old_course)
      sel_sub.update_attribute(:use_selective_copy, true)

      @migration.expects(:export_to_child_courses).with(:selective, [sel_sub], true)
      @migration.perform_exports
    end

    it "should do two exports if needed" do
      new_course = course_factory
      new_sub = @template.add_child_course!(new_course)
      old_course = course_factory
      sel_sub = @template.add_child_course!(old_course)
      sel_sub.update_attribute(:use_selective_copy, true)

      @migration.expects(:export_to_child_courses).twice
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

    def run_master_migration
      @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @admin)
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
      cm1 = ContentMigration.find(@migration.import_results.keys.first)
      expect(cm1.migration_settings[:imported_assets]["DiscussionTopic"]).to eq topic_to.id.to_s
      expect(cm1.migration_settings[:imported_assets]["Attachment"]).to eq att_to.id.to_s

      page = @copy_from.wiki.wiki_pages.create!(:title => "another title")

      run_master_migration
      expect(@migration.export_results.keys).to eq [:selective]

      page_to = @copy_to.wiki.wiki_pages.where(:migration_id => mig_id(page)).first
      expect(page_to).to be_present

      cm2 = ContentMigration.find(@migration.import_results.keys.first)
      expect(cm2.migration_settings[:imported_assets]["DiscussionTopic"]).to be_blank # should have excluded it from the selective export
      expect(cm2.migration_settings[:imported_assets]["Attachment"]).to be_blank
      expect(cm2.migration_settings[:imported_assets]["WikiPage"]).to eq page_to.id.to_s
    end

    it "should create master content tags with default restrictions on export" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      restrictions = {:content => true, :settings => false}
      @template.default_restrictions = restrictions
      @template.save!

      att = Attachment.create!(:filename => '1.txt', :uploaded_data => StringIO.new('1'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      Attachment.where(:id => att).update_all(:updated_at => 5.seconds.ago)

      run_master_migration

      att_tag = @template.master_content_tags.polymorphic_where(:content => att).first
      expect(att_tag.restrictions).to eq restrictions
      att_tag.update_attribute(:restrictions, {}) # unset them

      page = @copy_from.wiki.wiki_pages.create!(:title => "another title")

      run_master_migration
      page_tag = @template.master_content_tags.polymorphic_where(:content => page).first
      expect(page_tag.restrictions).to eq restrictions
      expect(att_tag.reload.restrictions).to be_blank # should have left the old one alone
    end

    it "should not overwrite with default restrictions on export" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      restrictions = {:content => true, :settings => false}
      @template.default_restrictions = restrictions
      @template.save!

      att = Attachment.create!(:filename => '1.txt', :uploaded_data => StringIO.new('1'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      Attachment.where(:id => att).update_all(:updated_at => 5.seconds.ago)

      run_master_migration

      att_tag = @template.master_content_tags.polymorphic_where(:content => att).first
      expect(att_tag.restrictions).to eq restrictions
      att_tag.update_attribute(:restrictions, {}) # unset them

      page = @copy_from.wiki.wiki_pages.create!(:title => "another title")

      run_master_migration
      page_tag = @template.master_content_tags.polymorphic_where(:content => page).first
      expect(page_tag.restrictions).to eq restrictions
      expect(att_tag.reload.restrictions).to be_blank # should have left the old one alone
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

      page = @copy_from.wiki.wiki_pages.create!(:title => "another title")

      @copy_to2 = course_factory
      @template.add_child_course!(@copy_to2) # new child course - needs full update

      run_master_migration
      expect(@migration.export_results.keys).to match_array([:selective, :full]) # should create both

      expect(@copy_to1.wiki.wiki_pages.where(:migration_id => mig_id(page)).first).to be_present # should bring the wiki page in the selective
      expect(topic_to1.reload.title).to eq new_title # should not have have overwritten the new change in the child course

      expect(@copy_to2.discussion_topics.where(:migration_id => mig_id(topic)).first).to be_present # should bring both in the full
      expect(@copy_to2.wiki.wiki_pages.where(:migration_id => mig_id(page)).first).to be_present
    end

    it "should skip master course restriction validations on import" do
      @copy_to = course_factory
      @template.add_child_course!(@copy_to)

      assmt = @copy_from.assignments.create!
      topic = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
      ann = @copy_from.announcements.create!(:message => "goodbye")
      page = @copy_from.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
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
      copied_page = @copy_to.wiki.wiki_pages.where(:migration_id => mig_id(page)).first
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
      page = @copy_from.wiki.wiki_pages.create!(:title => old_title, :body => "ohai")
      assignment = @copy_from.assignments.create!(:title => old_title, :description => "kthnx")

      run_master_migration

      # WikiPage
      copied_page = @copy_to.wiki.wiki_pages.where(:migration_id => mig_id(page)).first
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

      expect(copied_assignment.reload.description).to eq new_master_text
      expect(copied_assignment.title).to eq new_master_title
      expect(copied_page.reload.body).to eq new_master_text
      expect(copied_page.title).to eq new_master_title # even the title
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

      expect(sub.child_content_tags.count).to eq 2
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
          mtag.update_attribute(:restrictions, {:settings => true}) # lock the quiz/topic master tags
        end
      end

      run_master_migration # now, overwrite the due_at's because the tags are locked

      expect(copied_quiz_assmt.reload.due_at.to_i).to eq new_master_due_at.to_i # should have gotten overwritten
      expect(copied_topic_assmt.reload.due_at.to_i).to eq new_master_due_at.to_i
    end

    it "should ignore course settings" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      @copy_from.update_attribute(:is_public, true)

      run_master_migration

      expect(@copy_to.reload.is_public).to_not be_truthy
    end

    it "should trigger folder locking data cache invalidation" do
      @copy_to = course_factory
      @sub = @template.add_child_course!(@copy_to)

      enable_cache do
        expect(MasterCourses::FolderLockingHelper.locked_folder_ids_for_course(@copy_to)).to be_empty

        master_parent_folder = Folder.root_folders(@copy_from).first.sub_folders.create!(:name => "parent", :context => @copy_from)
        master_sub_folder = master_parent_folder.sub_folders.create!(:name => "child", :context => @copy_from)
        att = Attachment.create!(:filename => 'file.txt', :uploaded_data => StringIO.new('1'), :folder => master_sub_folder, :context => @copy_from)
        att_tag = @template.create_content_tag_for!(att, :restrictions => {:content => true, :settings => true})

        run_master_migration

        copied_att = @copy_to.attachments.where(:migration_id => att_tag.migration_id).first
        child_sub_folder = copied_att.folder
        child_parent_folder = child_sub_folder.parent_folder
        expected_ids = [child_sub_folder, child_parent_folder, Folder.root_folders(@copy_to).first].map(&:id)
        Folder.connection.expects(:select_values).never # should have already been cached in migration
        expect(MasterCourses::FolderLockingHelper.locked_folder_ids_for_course(@copy_to)).to match_array(expected_ids)
      end
    end

    context "master courses + external migrations" do
      class TestExternalContentService
        cattr_reader :course, :imported_content
        def self.send_imported_content(course, imported_content)
          @@course = course
          @@imported_content = imported_content
        end
      end

      before :each do
        Canvas::Migration::ExternalContent::Migrator.stubs(:registered_services).returns({'test_service' => TestExternalContentService})
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
        page = @copy_from.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
        quiz = @copy_from.quizzes.create!

        TestExternalContentService.stubs(:applies_to_course?).returns(true)
        TestExternalContentService.stubs(:begin_export).returns(true)

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
        TestExternalContentService.stubs(:export_completed?).returns(true)
        TestExternalContentService.stubs(:retrieve_export).returns(data)

        run_master_migration

        copied_assmt = @copy_to.assignments.where(:migration_id => mig_id(assmt)).first
        copied_topic = @copy_to.discussion_topics.where(:migration_id => mig_id(topic)).first
        copied_ann = @copy_to.announcements.where(:migration_id => mig_id(ann)).first
        copied_cm = @copy_to.context_modules.where(:migration_id => mig_id(cm)).first
        copied_item = @copy_to.context_module_tags.where(:migration_id => mig_id(item)).first
        copied_att = @copy_to.attachments.where(:migration_id => mig_id(att)).first
        copied_page = @copy_to.wiki.wiki_pages.where(:migration_id => mig_id(page)).first
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
