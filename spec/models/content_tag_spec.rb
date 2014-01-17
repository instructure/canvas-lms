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
  
  describe "#sync_workflow_state_to_asset?" do
    it "true when content_type is Quiz" do
      content_tag = ContentTag.new(:content_type => "Quiz")
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

  it_should_behave_like "url validation tests"
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

end
