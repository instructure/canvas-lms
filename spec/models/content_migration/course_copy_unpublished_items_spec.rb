require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy unpublished items" do
    include_examples "course copy"

    before :once do
      Account.default.enable_feature!(:draft_state)
    end

    it "should copy unpublished modules" do
      cm = @copy_from.context_modules.create!(:name => "some module")
      cm.publish
      cm2 = @copy_from.context_modules.create!(:name => "another module")
      cm2.unpublish

      run_course_copy

      @copy_to.context_modules.count.should == 2
      cm_2 = @copy_to.context_modules.where(migration_id: mig_id(cm)).first
      cm_2.workflow_state.should == 'active'
      cm2_2 = @copy_to.context_modules.where(migration_id: mig_id(cm2)).first
      cm2_2.workflow_state.should == 'unpublished'
    end

    it "should copy links to unpublished items in modules" do
      mod1 = @copy_from.context_modules.create!(:name => "some module")
      page = @copy_from.wiki.wiki_pages.create(:title => "some page")
      page.workflow_state = :unpublished
      page.save!
      mod1.add_item({:id => page.id, :type => 'wiki_page'})

      asmnt1 = @copy_from.assignments.create!(:title => "some assignment")
      asmnt1.workflow_state = :unpublished
      asmnt1.save!
      mod1.add_item({:id => asmnt1.id, :type => 'assignment', :indent => 1})

      run_course_copy

      mod1_copy = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      mod1_copy.content_tags.count.should == 2

      mod1_copy.content_tags.each do |tag_copy|
        tag_copy.unpublished?.should == true
        tag_copy.content.unpublished?.should == true
      end
    end

    it "should copy unpublished discussion topics" do
      dt1 = @copy_from.discussion_topics.create!(:message => "hideeho", :title => "Blah")
      dt1.workflow_state = :unpublished
      dt1.save!
      dt2 = @copy_from.discussion_topics.create!(:message => "asdf", :title => "qwert")
      dt2.workflow_state = :active
      dt2.save!

      run_course_copy

      dt1_copy = @copy_to.discussion_topics.where(migration_id: mig_id(dt1)).first
      dt1_copy.workflow_state.should == 'unpublished'
      dt2_copy = @copy_to.discussion_topics.where(migration_id: mig_id(dt2)).first
      dt2_copy.workflow_state.should == 'active'
    end

    it "should copy unpublished wiki pages" do
      wiki = @copy_from.wiki.wiki_pages.create(:title => "wiki", :body => "ohai")
      wiki.workflow_state = :unpublished
      wiki.save!

      run_course_copy

      wiki2 = @copy_to.wiki.wiki_pages.where(migration_id: mig_id(wiki)).first
      wiki2.workflow_state.should == 'unpublished'
    end

    it "should copy unpublished quiz assignments" do
      pending unless Qti.qti_enabled?
      @quiz = @copy_from.quizzes.create!
      @quiz.did_edit
      @quiz.offer!
      @quiz.unpublish!
      @quiz.assignment.should be_unpublished

      @cm.copy_options = {
          :assignments => {mig_id(@quiz.assignment) => "0"},
          :quizzes => {mig_id(@quiz) => "1"},
      }
      @cm.save!

      run_course_copy

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(@quiz)).first
      quiz_to.should_not be_nil
      quiz_to.assignment.should_not be_nil
      quiz_to.assignment.should be_unpublished
      quiz_to.assignment.migration_id.should == mig_id(@quiz.assignment)
    end
  end
end
