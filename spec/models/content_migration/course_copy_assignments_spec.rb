require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy assignments" do
    include_examples "course copy"

    it "should link assignments to account rubrics and outcomes" do
      account = @copy_from.account
      lo = create_outcome(account)

      rub = Rubric.new(:context => account)
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

      from_assign = @copy_from.assignments.create!(:title => "some assignment")
      rub.associate_with(from_assign, @copy_from, :purpose => "grading")

      run_course_copy

      to_assign = @copy_to.assignments.first
      to_assign.rubric.should == rub

      to_assign.learning_outcome_alignments.map(&:learning_outcome_id).should == [lo.id].sort
    end

    it "should copy rubric outcomes in selective copy" do
      @course = @copy_from
      outcome_with_rubric
      from_assign = @copy_from.assignments.create! title: 'some assignment'
      @rubric.associate_with(from_assign, @copy_from, purpose: 'grading')
      @cm.copy_options = {:assignments => {mig_id(from_assign) => true}}
      run_course_copy
      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_outcomes = to_assign.rubric.learning_outcome_alignments.map(&:learning_outcome).map(&:migration_id)
      to_outcomes.should eql [mig_id(@outcome)]
    end

    it "should link assignments to assignment groups on selective copy" do
      g = @copy_from.assignment_groups.create!(:name => "group")
      from_assign = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => g.id)

      @cm.copy_options = {:all_assignments => true}
      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_assign.assignment_group.should == @copy_to.assignment_groups.where(migration_id: mig_id(g)).first
    end

    it "should link assignments to assignment groups on complete export" do
      g = @copy_from.assignment_groups.create!(:name => "group")
      from_assign = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => g.id)
      run_export_and_import
      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_assign.assignment_group.should == @copy_to.assignment_groups.where(migration_id: mig_id(g)).first
    end

    it "should not link assignments to assignment groups on selective export" do
      g = @copy_from.assignment_groups.create!(:name => "group")
      from_assign = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => g.id)
      # test that we neither export nor reference the assignment group
      unrelated_group = @copy_to.assignment_groups.create! name: 'unrelated group with coincidentally matching migration id'
      unrelated_group.update_attribute :migration_id, mig_id(g)
      run_export_and_import do |export|
        export.selected_content = { 'assignments' => { mig_id(from_assign) => "1" } }
      end
      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_assign.assignment_group.should_not == unrelated_group
      unrelated_group.reload.name.should_not eql g.name
    end


    it "should copy assignment attributes" do
      assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'file_upload', :grading_type => 'points')
      @assignment.turnitin_enabled = true
      @assignment.peer_reviews = true
      @assignment.peer_review_count = 2
      @assignment.automatic_peer_reviews = true
      @assignment.anonymous_peer_reviews = true
      @assignment.allowed_extensions = ["doc", "xls"]
      @assignment.position = 2
      @assignment.muted = true

      @assignment.save!

      attrs = [:turnitin_enabled, :peer_reviews,
          :automatic_peer_reviews, :anonymous_peer_reviews,
          :grade_group_students_individually, :allowed_extensions,
          :position, :peer_review_count, :muted]

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      attrs.each do |attr|
        @assignment[attr].should == new_assignment[attr]
      end
    end

    it "should not copy peer_reviews_assigned" do
      assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'file_upload', :grading_type => 'points')
      @assignment.peer_reviews_assigned = true

      @assignment.save!

      run_course_copy

      new_assignment = @copy_to.assignments.find_by_migration_id(mig_id(@assignment))
      new_assignment.peer_reviews_assigned.should be_false
    end

    it "should include implied objects for context modules" do
      mod1 = @copy_from.context_modules.create!(:name => "some module")
      asmnt1 = @copy_from.assignments.create!(:title => "some assignment")
      mod1.add_item({:id => asmnt1.id, :type => 'assignment', :indent => 1})
      page = @copy_from.wiki.wiki_pages.create!(:title => "some page")
      page2 = @copy_from.wiki.wiki_pages.create!(:title => "some page 2")
      mod1.add_item({:id => page.id, :type => 'wiki_page'})
      att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att2 = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      mod1.add_item({:id => att.id, :type => 'attachment'})
      mod1.add_item({ :title => 'Example 1', :type => 'external_url', :url => 'http://a.example.com/' })
      mod1.add_item :type => 'context_module_sub_header', :title => "Sub Header"
      tool = @copy_from.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      tool2 = @copy_from.context_external_tools.create!(:name => "b", :url => "http://www.instructure.com", :consumer_key => '12345', :shared_secret => 'secret')
      mod1.add_item :type => 'context_external_tool', :id => tool.id, :url => tool.url
      topic = @copy_from.discussion_topics.create!(:title => "topic")
      topic2 = @copy_from.discussion_topics.create!(:title => "topic2")
      mod1.add_item :type => 'discussion_topic', :id => topic.id
      quiz = @copy_from.quizzes.create!(:title => 'quiz')
      quiz2 = @copy_from.quizzes.create!(:title => 'quiz2')
      mod1.add_item :type => 'quiz', :id => quiz.id
      mod1.save!

      mod2 = @copy_from.context_modules.create!(:name => "not copied")
      asmnt2 = @copy_from.assignments.create!(:title => "some assignment again")
      mod2.add_item({:id => asmnt2.id, :type => 'assignment', :indent => 1})
      mod2.save!

      @cm.copy_options = {
                      :context_modules => {mig_id(mod1) => "1", mig_id(mod2) => "0"},
              }
      @cm.save!

      run_course_copy

      mod1_copy = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      mod1_copy.should_not be_nil
      if Qti.qti_enabled?
        mod1_copy.content_tags.count.should == 8
      else
        mod1_copy.content_tags.count.should == 7
      end


      @copy_to.assignments.where(migration_id: mig_id(asmnt1)).first.should_not be_nil
      @copy_to.wiki.wiki_pages.where(migration_id: mig_id(page)).first.should_not be_nil
      @copy_to.attachments.where(migration_id: mig_id(att)).first.should_not be_nil
      @copy_to.context_external_tools.where(migration_id: mig_id(tool)).first.should_not be_nil
      @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first.should_not be_nil
      @copy_to.quizzes.where(migration_id: mig_id(quiz)).first.should_not be_nil if Qti.qti_enabled?

      @copy_to.context_modules.where(migration_id: mig_id(mod2)).first.should be_nil
      @copy_to.assignments.where(migration_id: mig_id(asmnt2)).first.should be_nil
      @copy_to.attachments.where(migration_id: mig_id(att2)).first.should be_nil
      @copy_to.wiki.wiki_pages.where(migration_id: mig_id(page2)).first.should be_nil
      @copy_to.context_external_tools.where(migration_id: mig_id(tool2)).first.should be_nil
      @copy_to.discussion_topics.where(migration_id: mig_id(topic2)).first.should be_nil
      @copy_to.quizzes.where(migration_id: mig_id(quiz2)).first.should be_nil
    end

    it "should copy module prerequisites" do
      enable_cache do
        mod = @copy_from.context_modules.create!(:name => "first module")
        mod2 = @copy_from.context_modules.create(:name => "next module")
        mod2.position = 2
        mod2.prerequisites = "module_#{mod.id}"
        mod2.save!

        run_course_copy

        to_mod = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
        to_mod2 = @copy_to.context_modules.where(migration_id: mig_id(mod2)).first
        to_mod2.prerequisites.should_not == []
        to_mod2.prerequisites[0][:id].should eql(to_mod.id)
      end
    end

    context "copying frozen assignments" do
      before :once do
        @setting = PluginSetting.create!(:name => "assignment_freezer", :settings => {"no_copying" => "yes"})

        @asmnt = @copy_from.assignments.create!(:title => 'lock locky')
        @asmnt.copied = true
        @asmnt.freeze_on_copy = true
        @asmnt.save!
        @quiz = @copy_from.quizzes.create(:title => "quiz", :quiz_type => "assignment")
        @quiz.workflow_state = 'available'
        @quiz.save!
        @quiz.assignment.copied = true
        @quiz.assignment.freeze_on_copy = true
        @quiz.save!
        @topic = @copy_from.discussion_topics.build(:title => "topic")
        assignment = @copy_from.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
        assignment.infer_times
        assignment.saved_by = :discussion_topic
        assignment.copied = true
        assignment.freeze_on_copy = true
        @topic.assignment = assignment
        @topic.save

        @admin = account_admin_user(opts={})
      end

      it "should copy for admin" do
        @cm.user = @admin
        @cm.save!

        run_course_copy

        @copy_to.assignments.count.should == (Qti.qti_enabled? ? 3 : 2)
        @copy_to.quizzes.count.should == 1 if Qti.qti_enabled?
        @copy_to.discussion_topics.count.should == 1
        @cm.content_export.error_messages.should == []
      end

      it "should copy for teacher if flag not set" do
        @setting.settings = {}
        @setting.save!

        run_course_copy

        @copy_to.assignments.count.should == (Qti.qti_enabled? ? 3 : 2)
        @copy_to.quizzes.count.should == 1 if Qti.qti_enabled?
        @copy_to.discussion_topics.count.should == 1
        @cm.content_export.error_messages.should == []
      end

      it "should not copy for teacher" do
        run_course_copy

        @copy_to.assignments.count.should == 0
        @copy_to.quizzes.count.should == 0
        @copy_to.discussion_topics.count.should == 0
        @cm.content_export.error_messages.should == [
                ["The assignment \"lock locky\" could not be copied because it is locked.", nil],
                ["The topic \"topic\" could not be copied because it is locked.", nil],
                ["The quiz \"quiz\" could not be copied because it is locked.", nil]]
      end

      it "should not mark assignment as copied if not set to be frozen" do
        @asmnt.freeze_on_copy = false
        @asmnt.copied = false
        @asmnt.save!

        run_course_copy

        asmnt_2 = @copy_to.assignments.where(migration_id: mig_id(@asmnt)).first
        asmnt_2.freeze_on_copy.should be_nil
        asmnt_2.copied.should be_nil
      end
    end

    describe "grading standards" do
      it "should retain reference to account grading standard" do
        gs = make_grading_standard(@copy_from.root_account)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        run_course_copy

        @copy_to.grading_standard.should == gs
      end

      it "should copy a course grading standard not owned by the copy_from course" do
        @other_course = course_model
        gs = make_grading_standard(@other_course)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        run_course_copy

        @copy_to.grading_standard_enabled.should be_true
        @copy_to.grading_standard.data.should == gs.data
      end

      it "should create a warning if an account grading standard can't be found" do
        gs = make_grading_standard(@copy_from.root_account)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        gs.delete

        run_course_copy(["Couldn't find account grading standard for the course."])

        @copy_to.grading_standard.should == nil
      end

      it "should not copy deleted grading standards" do
        gs = make_grading_standard(@copy_from)
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        gs.destroy
        @copy_from.reload

        run_course_copy

        @copy_to.grading_standards.should be_empty
      end

      it "should not copy grading standards if nothing is selected" do
        gs = make_grading_standard(@copy_from)
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { 'everything' => '0' }
        @cm.save!
        run_course_copy
        @copy_to.grading_standards.should be_empty
      end

      it "should copy the course's grading standard (once) if course_settings are selected" do
        gs = make_grading_standard(@copy_from, title: 'What')
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { 'everything' => '0', 'all_course_settings' => '1' }
        @cm.save!
        run_course_copy
        @copy_to.grading_standards.count.should eql 1 # no dupes
        @copy_to.grading_standard.title.should eql gs.title
      end

      it "should copy grading standards referenced by exported assignments" do
        gs1, gs2 = make_grading_standard(@copy_from, title: 'One'), make_grading_standard(@copy_from, title: 'Two')
        assign = @copy_from.assignments.build
        assign.grading_standard = gs2
        assign.save!
        @cm.copy_options = { 'everything' => '0', 'assignments' => { mig_id(assign) => "1" } }
        run_course_copy
        @copy_to.grading_standards.map(&:title).should eql %w(Two)
        @copy_to.assignments.first.grading_standard.title.should eql 'Two'
      end

      it "should copy referenced grading standards in complete export" do
        gs = make_grading_standard(@copy_from, title: 'GS')
        assign = @copy_from.assignments.build
        assign.grading_standard = gs
        assign.save!
        run_export_and_import
        @copy_to.assignments.first.grading_standard.title.should eql gs.title
      end

      it "should not copy referenced grading standards in selective export" do
        gs = make_grading_standard(@copy_from, title: 'One')
        assign = @copy_from.assignments.build
        assign.grading_standard = gs
        assign.save!
        # test that we neither export nor reference the grading standard
        unrelated_grading_standard = make_grading_standard(@copy_to, title: 'unrelated grading standard with coincidentally matching migration id')
        unrelated_grading_standard.update_attribute :migration_id, mig_id(gs)
        run_export_and_import do |export|
          export.selected_content = { 'assignments' => { mig_id(assign) => "1" } }
        end
        @copy_to.assignments.count.should eql 1
        @copy_to.assignments.first.grading_standard.should be_nil
        unrelated_grading_standard.reload.title.should_not eql gs.title
      end
    end
  end
end
