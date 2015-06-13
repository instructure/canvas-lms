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
        expect(ContentTag.asset_workflow_state(a)).to eq 'deleted'
      end

      it "returns 'active' for published assets" do
        a = mock_asset.new(published: true)
        expect(ContentTag.asset_workflow_state(a)).to eq 'active'
      end

      it "returns 'unpublished' for unpublished assets" do
        a = mock_asset.new(published: false)
        expect(ContentTag.asset_workflow_state(a)).to eq 'unpublished'
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
        expect(ContentTag.asset_workflow_state(a)).to eq 'active'
      end

      it "returns 'active' for 'available' workflow_state" do
        a = mock_asset.new('available')
        expect(ContentTag.asset_workflow_state(a)).to eq 'active'
      end

      it "returns 'active' for 'published' workflow_state" do
        a = mock_asset.new('published')
        expect(ContentTag.asset_workflow_state(a)).to eq 'active'
      end

      it "returns 'unpublished' for 'unpublished' workflow_state" do
        a = mock_asset.new('unpublished')
        expect(ContentTag.asset_workflow_state(a)).to eq 'unpublished'
      end

      it "returns 'deleted' for 'deleted' workflow_state" do
        a = mock_asset.new('deleted')
        expect(ContentTag.asset_workflow_state(a)).to eq 'deleted'
      end

      it "returns nil for other workflow_state" do
        a = mock_asset.new('terrified')
        expect(ContentTag.asset_workflow_state(a)).to eq nil
      end
    end
  end
  
  describe "#sync_workflow_state_to_asset?" do
    it "true when content_type is Quiz" do
      content_tag = ContentTag.new(:content_type => "Quiz")
      expect(content_tag.sync_workflow_state_to_asset?).to be_truthy
    end

    it "true when content_type is Quizzes::Quiz" do
      content_tag = ContentTag.new(:content_type => "Quizzes::Quiz")
      expect(content_tag.sync_workflow_state_to_asset?).to be_truthy
    end

    it "true when content_type is Assignment" do
      content_tag = ContentTag.new(:content_type => "Assignment")
      expect(content_tag.sync_workflow_state_to_asset?).to be_truthy
    end

    it "true when content_type is WikiPage" do
      content_tag = ContentTag.new(:content_type => "WikiPage")
      expect(content_tag.sync_workflow_state_to_asset?).to be_truthy
    end

    it "true when content_type is DiscussionTopic" do
      expect(ContentTag.new(content_type: "DiscussionTopic")).to be_sync_workflow_state_to_asset
    end
  end

  describe "#content_type_quiz?" do
    it "true when content_type is Quiz" do
      content_tag = ContentTag.new(:content_type => "Quiz")
      expect(content_tag.content_type_quiz?).to be_truthy
    end

    it "true when content_type is Quizzes::Quiz" do
      content_tag = ContentTag.new(:content_type => "Quizzes::Quiz")
      expect(content_tag.content_type_quiz?).to be_truthy
    end

    it "false when content_type is not valid" do
      content_tag = ContentTag.new(:content_type => "Assignment")
      expect(content_tag.content_type_quiz?).to be_falsey
    end
  end

  describe "#scoreable?" do
    it "true when quiz" do
      content_tag = ContentTag.new(:content_type => "Quizzes::Quiz")

      expect(content_tag.scoreable?).to be_truthy
    end

    it "true when gradeable" do
      content_tag = ContentTag.new(:content_type => "Assignment")

      expect(content_tag.scoreable?).to be_truthy
    end

    it "false when neither quiz nor gradeable" do
      content_tag = ContentTag.new(:content_type => "DiscussionTopic")

      expect(content_tag.scoreable?).to be_falsey
    end
  end

  it "should allow setting a valid content_asset_string" do
    tag = ContentTag.new
    tag.content_asset_string = 'discussion_topic_5'
    expect(tag.content_type).to eql('DiscussionTopic')
    expect(tag.content_id).to eql(5)
  end
  
  it "should not allow setting an invalid content_asset_string" do
    tag = ContentTag.new
    tag.content_asset_string = 'bad_class_41'
    expect(tag.content_type).to eql(nil)
    expect(tag.content_id).to eql(nil)
    
    tag.content_asset_string = 'bad_class'
    expect(tag.content_type).to eql(nil)
    expect(tag.content_id).to eql(nil)
    
    tag.content_asset_string = 'course_55'
    expect(tag.content_type).to eql(nil)
    expect(tag.content_id).to eql(nil)
  end

  it "should return content for a assignment" do
    course
    assignment = course.assignments.create!
    tag = ContentTag.new(:content => assignment, :context => @course)
    expect(tag.assignment).to eq assignment
  end

  it "should return associated assignment for a quiz" do
    course
    quiz = course.quizzes.create!
    tag = ContentTag.new(:content => quiz, :context => @course)
    expect(tag.assignment).to eq quiz.assignment
  end

  it "should return nil assignment for something else" do
    tag = ContentTag.new
    expect(tag.assignment).to be_nil
  end

  it "should include tags from a course in the for_context named scope" do
    course
    quiz = @course.quizzes.create!
    tag = ContentTag.create!(:content => quiz, :context => @course)
    tags = ContentTag.for_context(@course)
    expect(tags).not_to be_empty
    expect(tags.any?{ |t| t.id == tag.id }).to be_truthy
  end

  it "should include tags from an account in the for_context named scope" do
    account = Account.default
    outcome = account.created_learning_outcomes.create!(:title => 'outcome', :description => '<p>This is <b>awesome</b>.</p>')
    tag = ContentTag.create!(:content => outcome, :context => account)
    tags = ContentTag.for_context(account)
    expect(tags).not_to be_empty
    expect(tags.any?{ |t| t.id == tag.id }).to be_truthy
  end

  it "should include tags from courses under an account in the for_context named scope" do
    course
    quiz = @course.quizzes.create!
    tag = ContentTag.create!(:content => quiz, :context => @course)
    tags = ContentTag.for_context(@course.account)
    expect(tags).not_to be_empty
    expect(tags.any?{ |t| t.id == tag.id }).to be_truthy
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
    expect(@tool.name).to eq "new tool"
    @tag.reload
    expect(@tag.title).to eq "Example"
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
    expect(@tool.name).to eq "new tool"
    @tag.reload
    expect(@tag.title).to eq "Example"
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
    expect(@tag.title).to eq 'some assignment (renamed)'
    @assignment.reload
    expect(@assignment.title).to eq 'some assignment (renamed)'
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
    expect(@tag.title).to eq 'some assignment'
    @assignment.reload
    expect(@assignment.title).to eq 'some assignment'
    @assignment.title = "some assignment (renamed)"
    @assignment.save!
    ContentTag.update_for(@assignment)
    @tag.reload
    expect(@tag.title).to eq 'some assignment (renamed)'
    @assignment.reload
    expect(@assignment.title).to eq 'some assignment (renamed)'
  end

  describe ".update_for" do
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
        expect(@tag.workflow_state).to eq "unpublished"

        @quiz.publish!
        @quiz.reload
        
        ContentTag.update_for @quiz

        @tag.reload
        expect(@tag.workflow_state).to eq "active"
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
    expect(@tag.title[0, 250]).to eq @page.title[0, 250]
  end

  it "should properly trim asset name for assignments" do
    course
    @assign = @course.assignments.create!(:title => "some assignment")
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'Assignment', :title => 'oh noes!' * 35, :id => @assign.id})

    @tag.update_asset_name!

    @assign.reload
    expect(@tag.title[0, 250]).to eq @assign.title[0, 250]
  end

  it "should publish/unpublish the tag if the linked wiki page is published/unpublished" do
    course
    @page = @course.wiki.wiki_pages.create!(:title => "some page")
    @page.workflow_state = 'unpublished'
    @page.save!
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'WikiPage', :title => 'some page', :id => @page.id})
    expect(@tag.workflow_state).to eq 'unpublished'

    @page.reload
    @page.workflow_state = 'active'
    @page.save!
    @tag.reload
    expect(@tag.workflow_state).to eq 'active'

    @page.reload
    @page.workflow_state = 'unpublished'
    @page.save!
    @tag.reload
    expect(@tag.workflow_state).to eq 'unpublished'
  end

  it "should publish/unpublish the linked wiki page (and its tags) if the tag is published/unpublished" do
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
    expect(@page.workflow_state).to eq 'active'
    @tag2.reload
    expect(@tag2.workflow_state).to eq 'active'

    @tag.reload
    @tag.workflow_state = 'unpublished'
    @tag.save!
    @tag.update_asset_workflow_state!
    @page.reload
    expect(@page.workflow_state).to eq 'unpublished'
    @tag2.reload
    expect(@tag2.workflow_state).to eq 'unpublished'
  end

  it "should publish content via publish!" do
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
    expect(tag.title).to eq 'important title.txt'
  end
  
  it "should not rename attachment if linked tag is renamed" do
    course
    att = Attachment.create!(:filename => 'important title.txt', :display_name => "important title.txt", :uploaded_data => StringIO.new("It's what's on the inside of the file that doesn't matter.'"), :folder => Folder.unfiled_folder(@course), :context => @course)

    a_module = @course.context_modules.create!(:name => "module")
    tag = a_module.add_item({ :type => 'attachment', :title => 'Differently Important Title', :id => att.id })
    tag.update_asset_name!
    
    att.reload
    expect(att.display_name).to eq 'important title.txt'
  end

  include_examples "url validation tests"
  it "should check url validity" do
    quiz = course.quizzes.create!
    test_url_validation(ContentTag.create!(:content => quiz, :context => @course))
  end

  it "should touch the module after committing the save" do
    course
    mod = @course.context_modules.create!
    yesterday = 1.day.ago
    ContextModule.where(:id => mod).update_all(:updated_at => yesterday)
    ContextModule.transaction do
      tag = mod.add_item :type => 'context_module_sub_header', :title => 'blah'
      expect(mod.reload.updated_at.to_i).to eq yesterday.to_i
    end
    expect(mod.reload.updated_at).to be > 5.seconds.ago
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

    expect(@module.reload.updated_at.to_i).to eq yesterday.to_i
  end

  describe '.content_type' do
    it 'returns the correct representation of a quiz' do
      content_tag = ContentTag.create! content: quiz_model, context: course_model
      expect(content_tag.content_type).to eq 'Quizzes::Quiz'

      content_tag.content_type = 'Quiz'
      content_tag.send(:save_without_callbacks)

      expect(ContentTag.find(content_tag.id).content_type).to eq 'Quizzes::Quiz'
    end

    it 'returns the content type attribute if not a quiz' do
      content_tag = ContentTag.create! content: assignment_model, context: course_model

      expect(content_tag.content_type).to eq 'Assignment'
    end
  end

  describe "visible_to_students_in_course_with_da" do
    before do
      course_with_student(active_all: true)
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student)
    end
    context "assignments" do
      before do
        @assignment = @course.assignments.create!(:title => "some assignment", :only_visible_to_overrides => true)
        @module = @course.context_modules.create!(:name => "module")
        @tag = @module.add_item({
          :type => 'assignment',
          :title => 'some assignment',
          :id => @assignment.id
        })
      end
      it "returns assignments if there is visibility" do
        create_section_override_for_assignment(@assignment, {course_section: @section})
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end
      it "does not return assignments if there is no visibility" do
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).not_to include(@tag)
      end
    end
    context "discussions" do
      def attach_assignment_to_discussion
        @assignment = @course.assignments.create!(:title => "some discussion assignment",only_visible_to_overrides: true)
        @assignment.submission_types = 'discussion_topic'
        @assignment.save!
        @topic.assignment_id = @assignment.id
        @topic.save!
      end
      before do
        discussion_topic_model(:user => @course.instructors.first, :context => @course)
        @module = @course.context_modules.create!(:name => "module")
        @tag = @module.add_item({
          :type => 'discussion_topic',
          :title => 'some discussion',
          :id => @topic.id
        })
      end
      it "returns discussions without attached assignments" do
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end
      it "returns discussions with attached assignments if there is visibility" do
        attach_assignment_to_discussion
        create_section_override_for_assignment(@assignment, {course_section: @section})
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end
      it "does not return discussions with attached assignments if there is no visibility" do
        attach_assignment_to_discussion
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).not_to include(@tag)
      end
    end
    context "quizzes" do
      before do
        @quiz = @course.quizzes.create!(only_visible_to_overrides: true)
        @module = @course.context_modules.create!(:name => "module")
        @tag = @module.add_item({
          :type => 'quiz',
          :title => 'some quiz',
          :id => @quiz.id
        })
      end
      it "returns a quiz if there is visibility" do
        create_section_override_for_quiz(@quiz, course_section: @section)
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end
      it "does not return quiz if there is not visibility" do
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).not_to include(@tag)
      end
    end
    context "other" do
      it "it properly returns wiki pages" do
        @page = @course.wiki.wiki_pages.create!(:title => "some page")
        @module = @course.context_modules.create!(:name => "module")
        @tag = @module.add_item({:type => 'WikiPage', :title => 'oh noes!' * 35, :id => @page.id})
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end
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

      expect(@module.reload.completion_requirements).to eq [{id: @tag2.id, type: 'must_submit'}]
    end
  end

  it "should sync tag published state with attachment locked state" do
    course
    att = Attachment.create!(:filename => 'blah.txt', :uploaded_data => StringIO.new("blah"),
                             :folder => Folder.unfiled_folder(@course), :context => @course)
    att.locked = true
    att.save!

    a_module = @course.context_modules.create!(:name => "module")
    tag = a_module.add_item({ :type => 'attachment', :id => att.id })
    expect(tag.unpublished?).to be_truthy

    att.locked = false
    att.save!
    tag.reload
    expect(tag.unpublished?).to be_falsey

    att.locked = true
    att.save!
    tag.reload
    expect(tag.unpublished?).to be_truthy
  end
end
