#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/validates_as_url.rb')

describe ContentTag do

  describe "::asset_workflow_state" do
    context "respond_to?(:published?)" do
      mock_asset = Class.new do
        def initialize(opts={})
          opts = {published: true, deleted: false}.merge(opts)
          @published = opts[:published]
          @deleted = opts[:deleted]
        end

        def published?; !!@published; end
        def unpublished?; !@published; end
        def deleted?; @deleted; end
      end

      it "returns 'deleted' for deleted assets" do
        a = mock_asset.new(deleted: true)
        ContentTag.asset_workflow_state(a).should == 'deleted'
      end

      it "returns 'active' for published assets" do
        a = mock_asset.new(published: true)
        ContentTag.asset_workflow_state(a).should == 'active'
      end

      it "returns 'unpublished' for unpublished assets" do
        a = mock_asset.new(published: false)
        ContentTag.asset_workflow_state(a).should == 'unpublished'
      end
    end

    context "respond_to?(:workflow_state)" do
      mock_asset = Class.new do
        attr_reader :workflow_state
        def initialize(workflow_state)
          @workflow_state = workflow_state
        end
      end

      it "returns 'active' for 'active' workflow_state" do
        a = mock_asset.new('active')
        ContentTag.asset_workflow_state(a).should == 'active'
      end

      it "returns 'active' for 'available' workflow_state" do
        a = mock_asset.new('available')
        ContentTag.asset_workflow_state(a).should == 'active'
      end

      it "returns 'active' for 'published' workflow_state" do
        a = mock_asset.new('published')
        ContentTag.asset_workflow_state(a).should == 'active'
      end

      it "returns 'unpublished' for 'unpublished' workflow_state" do
        a = mock_asset.new('unpublished')
        ContentTag.asset_workflow_state(a).should == 'unpublished'
      end

      it "returns 'deleted' for 'deleted' workflow_state" do
        a = mock_asset.new('deleted')
        ContentTag.asset_workflow_state(a).should == 'deleted'
      end

      it "returns nil for other workflow_state" do
        a = mock_asset.new('terrified')
        ContentTag.asset_workflow_state(a).should == nil
      end
    end
  end
  
  describe "#sync_workflow_state_to_asset?" do
    it "true when content_type is Quiz" do
      content_tag = ContentTag.new(:content_type => "Quiz")
      content_tag.sync_workflow_state_to_asset?.should be_true
    end

    it "true when content_type is Quizzes::Quiz" do
      content_tag = ContentTag.new(:content_type => "Quizzes::Quiz")
      content_tag.sync_workflow_state_to_asset?.should be_true
    end

    it "true when content_type is Assignment" do
      content_tag = ContentTag.new(:content_type => "Assignment")
      content_tag.sync_workflow_state_to_asset?.should be_true
    end

    it "true when content_type is WikiPage" do
      content_tag = ContentTag.new(:content_type => "WikiPage")
      content_tag.sync_workflow_state_to_asset?.should be_true
    end

    it "true when content_type is DiscussionTopic" do
      ContentTag.new(content_type: "DiscussionTopic").should be_sync_workflow_state_to_asset
    end
  end

  describe "#content_type_quiz?" do
    it "true when content_type is Quiz" do
      content_tag = ContentTag.new(:content_type => "Quiz")
      content_tag.content_type_quiz?.should be_true
    end

    it "true when content_type is Quizzes::Quiz" do
      content_tag = ContentTag.new(:content_type => "Quizzes::Quiz")
      content_tag.content_type_quiz?.should be_true
    end

    it "false when content_type is not valid" do
      content_tag = ContentTag.new(:content_type => "Assignment")
      content_tag.content_type_quiz?.should be_false
    end
  end

  describe "#scoreable?" do
    it "true when quiz" do
      content_tag = ContentTag.new(:content_type => "Quizzes::Quiz")

      content_tag.scoreable?.should be_true
    end

    it "true when gradeable" do
      content_tag = ContentTag.new(:content_type => "Assignment")

      content_tag.scoreable?.should be_true
    end

    it "false when neither quiz nor gradeable" do
      content_tag = ContentTag.new(:content_type => "DiscussionTopic")

      content_tag.scoreable?.should be_false
    end
  end

  it "should allow setting a valid content_asset_string" do
    tag = ContentTag.new
    tag.content_asset_string = 'discussion_topic_5'
    tag.content_type.should eql('DiscussionTopic')
    tag.content_id.should eql(5)
  end
  
  it "should not allow setting an invalid content_asset_string" do
    tag = ContentTag.new
    tag.content_asset_string = 'bad_class_41'
    tag.content_type.should eql(nil)
    tag.content_id.should eql(nil)
    
    tag.content_asset_string = 'bad_class'
    tag.content_type.should eql(nil)
    tag.content_id.should eql(nil)
    
    tag.content_asset_string = 'course_55'
    tag.content_type.should eql(nil)
    tag.content_id.should eql(nil)
  end

  it "should return content for a assignment" do
    course
    assignment = course.assignments.create!
    tag = ContentTag.new(:content => assignment, :context => @course)
    tag.assignment.should == assignment
  end

  it "should return associated assignment for a quiz" do
    course
    quiz = course.quizzes.create!
    tag = ContentTag.new(:content => quiz, :context => @course)
    tag.assignment.should == quiz.assignment
  end

  it "should return nil assignment for something else" do
    tag = ContentTag.new
    tag.assignment.should be_nil
  end

  it "should include tags from a course in the for_context named scope" do
    course
    quiz = @course.quizzes.create!
    tag = ContentTag.create!(:content => quiz, :context => @course)
    tags = ContentTag.for_context(@course)
    tags.should_not be_empty
    tags.any?{ |t| t.id == tag.id }.should be_true
  end

  it "should include tags from an account in the for_context named scope" do
    account = Account.default
    outcome = account.created_learning_outcomes.create!(:title => 'outcome', :description => '<p>This is <b>awesome</b>.</p>')
    tag = ContentTag.create!(:content => outcome, :context => account)
    tags = ContentTag.for_context(account)
    tags.should_not be_empty
    tags.any?{ |t| t.id == tag.id }.should be_true
  end

  it "should include tags from courses under an account in the for_context named scope" do
    course
    quiz = @course.quizzes.create!
    tag = ContentTag.create!(:content => quiz, :context => @course)
    tags = ContentTag.for_context(@course.account)
    tags.should_not be_empty
    tags.any?{ |t| t.id == tag.id }.should be_true
  end
  
  it "should not rename the linked external tool if the tag is renamed" do
    course
    @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
      :type => 'context_external_tool',
      :title => 'Example',
      :url => 'http://www.example.com',
      :new_tab => '0'
    })
    @tag.update_asset_name!
    @tool.reload
    @tool.name.should == "new tool"
    @tag.reload
    @tag.title.should == "Example"
  end
    
  it "should not rename the tag if the linked external tool is renamed" do
    course
    @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
      :type => 'context_external_tool',
      :title => 'Example',
      :url => 'http://www.example.com',
      :new_tab => '0'
    })
    ContentTag.update_for(@tool)
    @tool.reload
    @tool.name.should == "new tool"
    @tag.reload
    @tag.title.should == "Example"
  end

  it "should rename the linked assignment if the tag is renamed" do
    course
    @assignment = @course.assignments.create!(:title => "some assignment")
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
      :type => 'assignment',
      :title => 'some assignment (renamed)',
      :id => @assignment.id
    })
    @tag.update_asset_name!
    @tag.reload
    @tag.title.should == 'some assignment (renamed)'
    @assignment.reload
    @assignment.title.should == 'some assignment (renamed)'
  end
  
  it "should rename the tag if the linked assignment is renamed" do
    course
    @assignment = @course.assignments.create!(:title => "some assignment")
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
      :type => 'assignment',
      :title => 'some assignment',
      :id => @assignment.id
    })
    @tag.reload
    @tag.title.should == 'some assignment'
    @assignment.reload
    @assignment.title.should == 'some assignment'
    @assignment.title = "some assignment (renamed)"
    @assignment.save!
    ContentTag.update_for(@assignment)
    @tag.reload
    @tag.title.should == 'some assignment (renamed)'
    @assignment.reload
    @assignment.title.should == 'some assignment (renamed)'
  end

  describe ".update_for with draft state enabled" do
    before do
      Course.any_instance.stubs(:draft_state_enabled?).returns(true)
    end

    context "when updating a quiz" do
      before do
        course
        @quiz = course.quizzes.create!
        @module = @course.context_modules.create!(:name => "module")
        @tag = @module.add_item({
          :type => 'quiz',
          :title => 'some quiz',
          :id => @quiz.id
        })
        @tag.reload
      end

      it "syncs workflow_state transitions publishing/unpublishing" do
        @quiz.unpublish!
        @quiz.reload

        ContentTag.update_for @quiz

        @tag.reload
        @tag.workflow_state.should == "unpublished"

        @quiz.publish!
        @quiz.reload
        
        ContentTag.update_for @quiz

        @tag.reload
        @tag.workflow_state.should == "active"
      end
    end
  end

  it "should not attempt to update asset name attribute if it's over the db limit" do
    course
    @page = @course.wiki.wiki_pages.create!(:title => "some page")
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'WikiPage', :title => 'oh noes!' * 35, :id => @page.id})

    @tag.update_asset_name!

    @page.reload
    @tag.title[0, 250].should == @page.title[0, 250]
  end

  it "should properly trim asset name for assignments" do
    course
    @assign = @course.assignments.create!(:title => "some assignment")
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'Assignment', :title => 'oh noes!' * 35, :id => @assign.id})

    @tag.update_asset_name!

    @assign.reload
    @tag.title[0, 250].should == @assign.title[0, 250]
  end

  it "should publish/unpublish the tag if the linked wiki page is published/unpublished" do
    Account.default.enable_feature!(:draft_state)

    course
    @page = @course.wiki.wiki_pages.create!(:title => "some page")
    @page.workflow_state = 'unpublished'
    @page.save!
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'WikiPage', :title => 'some page', :id => @page.id})
    @tag.workflow_state.should == 'unpublished'

    @page.reload
    @page.workflow_state = 'active'
    @page.save!
    @tag.reload
    @tag.workflow_state.should == 'active'

    @page.reload
    @page.workflow_state = 'unpublished'
    @page.save!
    @tag.reload
    @tag.workflow_state.should == 'unpublished'
  end

  it "should publish/unpublish the linked wiki page (and its tags) if the tag is published/unpublished" do
    Account.default.enable_feature!(:draft_state)

    course
    @page = @course.wiki.wiki_pages.create!(:title => "some page")
    @page.workflow_state = 'unpublished'
    @page.save!
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'WikiPage', :title => 'some page', :id => @page.id})
    @tag2 = @module.add_item({:type => 'WikiPage', :title => 'some page', :id => @page.id})

    @tag.reload
    @tag.workflow_state = 'active'
    @tag.save!
    @tag.update_asset_workflow_state!
    @page.reload
    @page.workflow_state.should == 'active'
    @tag2.reload
    @tag2.workflow_state.should == 'active'

    @tag.reload
    @tag.workflow_state = 'unpublished'
    @tag.save!
    @tag.update_asset_workflow_state!
    @page.reload
    @page.workflow_state.should == 'unpublished'
    @tag2.reload
    @tag2.workflow_state.should == 'unpublished'
  end

  it "should publish content via publish!" do
    Account.default.enable_feature!(:draft_state)
    assignment_model
    @assignment.unpublish!
    @module = @course.context_modules.create!
    @tag = @module.add_item(type: 'Assignment', id: @assignment.id)
    @tag.workflow_state = 'active'
    @tag.content.expects(:publish!).once
    @tag.save!
    @tag.update_asset_workflow_state!
  end

  it "should unpublish content via unpublish!" do
    Account.default.enable_feature!(:draft_state)
    quiz_model
    @module = @course.context_modules.create!
    @tag = @module.add_item(type: 'Quiz', id: @quiz.id)
    @tag.workflow_state = 'unpublished'
    @tag.content.expects(:unpublish!).once
    @tag.save!
    @tag.update_asset_workflow_state!
  end
  
  it "should not rename tag if linked attachment is renamed" do
    course
    att = Attachment.create!(:filename => 'important title.txt', :display_name => "important title.txt", :uploaded_data => StringIO.new("It's what's on the inside of the file that doesn't matter.'"), :folder => Folder.unfiled_folder(@course), :context => @course)

    a_module = @course.context_modules.create!(:name => "module")
    tag = a_module.add_item({ :type => 'attachment', :title => 'important title.txt', :id => att.id })
    tag.update_asset_name!
    
    att.display_name = "no longer important.txt"
    ContentTag.update_for(att)
    tag.reload
    tag.title.should == 'important title.txt'
  end
  
  it "should not rename attachment if linked tag is renamed" do
    course
    att = Attachment.create!(:filename => 'important title.txt', :display_name => "important title.txt", :uploaded_data => StringIO.new("It's what's on the inside of the file that doesn't matter.'"), :folder => Folder.unfiled_folder(@course), :context => @course)

    a_module = @course.context_modules.create!(:name => "module")
    tag = a_module.add_item({ :type => 'attachment', :title => 'Differently Important Title', :id => att.id })
    tag.update_asset_name!
    
    att.reload
    att.filename.should == 'important title.txt'
    att.display_name.should == 'important title.txt'
  end

  include_examples "url validation tests"
  it "should check url validity" do
    quiz = course.quizzes.create!
    test_url_validation(ContentTag.create!(:content => quiz, :context => @course))
  end

  it "should touch the module after committing the save" do
    Rails.env.stubs(:test?).returns(false)
    course
    mod = @course.context_modules.create!
    yesterday = 1.day.ago
    ContextModule.where(:id => mod).update_all(:updated_at => yesterday)
    tag = mod.add_item :type => 'context_module_sub_header', :title => 'blah'
    mod.reload.updated_at.to_i.should == yesterday.to_i
    mod.connection.run_transaction_commit_callbacks
    mod.reload.updated_at.should > 5.seconds.ago
  end

  it "should allow skipping touches on save" do
    course
    @assignment = @course.assignments.create!(:title => "some assignment")
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
      :type => 'assignment',
      :title => 'some assignment (renamed)',
      :id => @assignment.id
    })
    @tag.update_asset_name!
    @tag.reload

    yesterday = 1.day.ago
    ContextModule.where(:id => @module).update_all(:updated_at => yesterday)

    @tag.skip_touch = true
    @tag.save

    @module.reload.updated_at.to_i.should == yesterday.to_i
  end

  describe '.content_type' do
    it 'returns the correct representation of a quiz' do
      content_tag = ContentTag.create! content: quiz_model, context: course_model
      content_tag.content_type.should == 'Quizzes::Quiz'

      content_tag.content_type = 'Quiz'
      content_tag.send(:save_without_callbacks)

      ContentTag.find(content_tag.id).content_type.should == 'Quizzes::Quiz'
    end

    it 'returns the content type attribute if not a quiz' do
      content_tag = ContentTag.create! content: assignment_model, context: course_model

      content_tag.content_type.should == 'Assignment'
    end
  end

  describe "destroy" do
    it "updates completion requirements on its associated ContextModule" do
      course_with_teacher(:active_all => true)

      @module = @course.context_modules.create!(:name => "some module")
      @assignment = @course.assignments.create!(:title => "some assignment")
      @assignment2 = @course.assignments.create!(:title => "some assignment2")

      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @tag2 = @module.add_item({:id => @assignment2.id, :type => 'assignment'})

      @module.completion_requirements = [{id: @tag.id, type: 'must_submit'},
                                         {id: @tag2.id, type: 'must_submit'}]

      @module.save

      @tag.destroy

      @module.reload.completion_requirements.should == [{id: @tag2.id, type: 'must_submit'}]
    end
  end
end
