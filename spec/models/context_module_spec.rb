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

describe ContextModule do
  def course_module
    @course = course(:active_all => true)
    @module = @course.context_modules.create!(:name => "some module")
  end

  describe "available_for?" do
    it "should return true by default" do
      course_module
      @module.available_for?(nil).should eql(true)
    end
  end
  
  describe "prerequisites=" do
    it "should assign prerequisites" do
      course_module
      @module2 = @course.context_modules.create!(:name => "next module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.prerequisites.should be_is_a(Array)
      @module2.prerequisites.should_not be_empty
      @module2.prerequisites[0][:id].should eql(@module.id)
    end

    it "should add prereqs to new module" do
      course_module
      @module2 = @course.context_modules.build(:name => "next module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!
      @module2.prerequisites.should be_is_a(Array)
      @module2.prerequisites.should_not be_empty
      @module2.prerequisites[0][:id].should eql(@module.id)
    end
      
    it "should remove invalid prerequisites" do
      course_module
      @module2 = @course.context_modules.create!(:name => "next module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.prerequisites.should be_is_a(Array)
      @module2.prerequisites.should_not be_empty
      @module2.prerequisites[0][:id].should eql(@module.id)
      
      pres = @module2.prerequisites
      @module2.prerequisites = pres + [{:id => -1, :type => 'asdf'}]
      @module2.prerequisites.should eql(pres)
    end
    
    it "should not allow looping prerequisites" do
      course_module
      @module2 = @course.context_modules.create!(:name => "next module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!
      @module2.prerequisites.should be_is_a(Array)
      @module2.prerequisites.should_not be_empty
      @module2.prerequisites[0][:id].should eql(@module.id)
      @module.prerequisites = "module_#{@module2.id}"
      @module.save!
      @module2.prerequisites.should be_is_a(Array)
      @module2.prerequisites.should_not be_empty
      @module2.prerequisites[0][:id].should eql(@module.id)
      @module.prerequisites.should be_is_a(Array)
      @module.prerequisites.should be_empty
    end
    
    it "should not allow adding invalid prerequisites" do
      course_module
      @module2 = @course.context_modules.create!(:name => "next module")
      invalid = course().context_modules.create!(:name => "nope")
      @module2.prerequisites = "module_#{@module.id},module_#{invalid.id}"
      @module2.save!
      @module2.prerequisites.should be_is_a(Array)
      @module2.prerequisites.should_not be_empty
      @module2.prerequisites[0][:id].should eql(@module.id)
      @module2.prerequisites.length.should eql(1)
    end
  end
  
  describe "add_item" do
    it "should add an assignment" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'}) #@assignment)
      @tag.content.should eql(@assignment)
      @module.content_tags.should be_include(@tag)
    end
    
    it "should not add an invalid assignment" do
      course_module
      @tag = @module.add_item({:id => 21, :type => 'assignment'})
      @tag.should be_nil
    end
    
    it "should add a wiki page" do
      course_module
      @page = @course.wiki.wiki_pages.create!(:title => "some page")
      @tag = @module.add_item({:id => @page.id, :type => 'wiki_page'}) #@page)
      @tag.content.should eql(@page)
      @module.content_tags.should be_include(@tag)
    end

    it "should not add invalid wiki pages" do
      course_module
      @course.wiki
      @wiki = Wiki.create!(:title => "new wiki")
      @page = @wiki.wiki_pages.create!(:title => "new page")
      @tag = @module.add_item({:id => @page.id, :type => 'wiki_page'})
      @tag.should be_nil
    end
    
    it "should add an attachment" do
      course_module
      @file = @course.attachments.create!(:display_name => "some file", :uploaded_data => default_uploaded_data)
      @tag = @module.add_item({:id => @file.id, :type => 'attachment'}) #@file)
      @tag.content.should eql(@file)
      @module.content_tags.should be_include(@tag)
    end

    it "should allow adding items more than once" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag1 = @module.add_item(:id => @assignment.id, :type => "assignment")
      @tag2 = @module.add_item(:id => @assignment.id, :type => "assignment")
      @tag1.should_not == @tag2
      @module.content_tags.should be_include(@tag1)
      @module.content_tags.should be_include(@tag2)

      @mod2 = @course.context_modules.create!(:name => "mod2")
      @tag3 = @mod2.add_item(:id => @assignment.id, :type => "assignment")
      @tag3.should_not == @tag1
      @tag3.should_not == @tag2
      @mod2.content_tags.should == [@tag3]
    end

    context "when draft state is enabled" do
      before do
        Course.any_instance.stubs(:feature_enabled?).with(:draft_state).returns(true)
      end

      it "adds external tools with a default workflow_state of anonymous" do
        course_module
        course_with_student(:active_all => true)
        @external_tool = @course.context_external_tools.create!(
          :url => "http://example.com/ims/lti",
          :consumer_key => "asdf",
          :shared_secret => "hjkl",
          :name => "external tool",
          :course_navigation => {
            :text => "blah",
            :url =>  "http://example.com/ims/lti",
            :default => false
          }
        )
        @tag = @module.add_item(:id => @external_tool.id, :type => "external_tool")
        @tag.unpublished?.should be_true
      end

      it "adds external_url with a default workflow_state of unpublished" do
        course_module
        @tag = @module.add_item(:type => 'external_url', :url => 'http://example.com/lolcats', :title => 'pls view', :indent => 1)
        @tag.unpublished?.should be_true
      end
    end
  end
  
  describe "completion_requirements=" do
    it "should assign completion requirements" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'}) #@assignment)
      req = {}
      req[@tag.id] = {:type => 'must_view'}
      @module.completion_requirements = req
      @module.completion_requirements.should_not be_nil
      @module.completion_requirements.should be_is_a(Array)
      @module.completion_requirements.should_not be_empty
      @module.completion_requirements[0][:id].should eql(@tag.id)
      @module.completion_requirements[0][:type].should eql('must_view')
    end
      
    it "should remove invalid requirements" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'}) #@assignment)
      req = {}
      req[@tag.id] = {:type => 'must_view'}
      @module.completion_requirements = req
      @module.completion_requirements.should_not be_nil
      @module.completion_requirements.should be_is_a(Array)
      @module.completion_requirements.should_not be_empty
      @module.completion_requirements[0][:id].should eql(@tag.id)
      @module.completion_requirements[0][:type].should eql('must_view')
      
      reqs = @module.completion_requirements
      @module.completion_requirements = reqs + [{:id => -1, :type => 'asdf'}]
      @module.completion_requirements.should eql(reqs)
    end

    it 'should ignore invalid requirements' do
      course_module
      @module.completion_requirements = {"none"=>"none"} # the front-end likes to pass this in...
      @module.save!

      @module.completion_requirements.should be_empty
    end

    it 'should not remove unpublished requirements' do
      course_module
      @assignment = @course.assignments.create!(title: 'some assignment')
      @assignment.workflow_state = 'unpublished'
      @assignment.save!

      @tag = @module.add_item({id: @assignment.id, type: 'assignment'})
      @module.completion_requirements = { @tag.id => {type: 'must_view'} }
      @module.save!

      @module.completion_requirements.should eql([id: @tag.id, type: 'must_view'])
    end
  end
  
  describe "update_for" do
    it "should update for a user" do
      course_module
      @user = User.create!(:name => "some name")
      @assignment = @course.assignments.create!(:title => "some assignment")
      @course.enroll_student(@user)
      @tag = @module.add_item(:id => @assignment.id, :type => 'assignment')
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @progression = @module.update_for(@user, :read, @tag)
      @progression.should_not be_nil
      @progression.requirements_met.should_not be_nil
      @progression.requirements_met.should be_is_a(Array)
      @progression.requirements_met.should_not be_empty
      @progression.requirements_met[0][:id].should eql(@tag.id)
    end

    it "should return nothing if the user isn't a part of the context" do
      course_module
      @user = User.create!(:name => "some name")
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item(:id => @assignment.id, :type => 'assignment')
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @progression = @module.update_for(@user, :read, @tag)
      @progression.should be_nil
    end

    it "should not generate progressions for non-active modules" do
      student_in_course :active_all => true
      tehmod = @course.context_modules.create! :name => "teh module"
      page = @course.wiki.wiki_pages.create! :title => "view this page"
      tag = tehmod.add_item(:id => page.id, :type => 'wiki_page')
      tehmod.completion_requirements = { tag.id => {:type => 'must_view'} }
      tehmod.workflow_state = 'active'
      tehmod.save!

      othermods = %w(active unpublished deleted).collect do |state|
        mod = @course.context_modules.build :name => "other module in state #{state}"
        mod.workflow_state = state
        mod.save!
        mod
      end

      tehmod.update_for(@student, :read, tag)
      mods_with_progressions = @student.context_module_progressions.collect(&:context_module_id)
      mods_with_progressions.should_not be_include othermods[1].id
      mods_with_progressions.should_not be_include othermods[2].id
    end
  end
  
  describe "evaluate_for" do
    it "should create a completed progression for no prerequisites and no requirements" do
      course_module
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)
      @progression = @module.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_completed
    end

    it "should trigger completion events" do
      course_module
      @module.completion_events = [:publish_final_grade]
      @module.context = @course
      @module.save!
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)
      @course.expects(:publish_final_grades).with(@user, @user.id).once
      @progression = @module.evaluate_for(@user, true)
    end

    it "should create an unlocked progression for no prerequisites" do
      course_module
      @user = User.create!(:name => "some name")
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item(:id => @assignment.id, :type => 'assignment')
      @tag.should_not be_nil
      @course.enroll_student(@user)
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @progression = @module.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_unlocked
    end
    
    it "should create a locked progression if there are prerequisites unmet" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module.save!
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)

      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!
      @module2.prerequisites.should_not be_nil
      @module2.prerequisites.should_not be_empty
      @progression = @module2.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_locked
      @progression.destroy
      @progression = @module2.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_locked
    end

    it "should create an unlocked progression if prerequisites is unpublished" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module.workflow_state = 'unpublished'
      @module.save!

      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)

      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.publish
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!
      @module2.prerequisites.should_not be_nil
      @module2.prerequisites.should_not be_empty

      @progression = @module2.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should_not be_locked
      @progression.destroy
      @progression = @module2.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should_not be_locked
    end

    describe "multi-items" do
      it "should be locked if all tags are locked" do
        course_module
        @user = User.create!(:name => "some name")
        @course.enroll_student(@user)
        @a1 = @course.assignments.create!(:title => "some assignment")
        @tag1 = @module.add_item({:id => @a1.id, :type => 'assignment'})
        @module.require_sequential_progress = true
        @module.completion_requirements = {@tag1.id => {:type => 'must_submit'}}
        @module.save!
        @a2 = @course.assignments.create!(:title => "locked assignment")
        @a2.locked_for?(@user).should be_false
        @tag2 = @module.add_item({:id => @a2.id, :type => 'assignment'})
        @a2.reload.locked_for?(@user).should be_true

        @mod2 = @course.context_modules.create!(:name => "mod2")
        @tag3 = @mod2.add_item({:id => @a2.id, :type => 'assignment'})
        # not locked, because the second tag allows access
        @a2.reload.locked_for?(@user).should be_false
        @mod2.prerequisites = "module_#{@module.id}"
        @mod2.save!
        # now locked, because mod2 is locked
        @a2.reload.locked_for?(@user).should be_true
      end
    end

    it "should not be available if previous module is incomplete" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module.save!
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)

      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.prerequisites = "module_#{@module.id}"
      @assignment2 = @course.assignments.create!(:title => 'a2')
      @tag2 = @module2.add_item({:id => @assignment2.id, :type => 'assignment'})
      @module2.completion_requirements = {@tag2.id => {:type => 'must_view'}}
      @module2.save!
      @module2.prerequisites.should_not be_nil
      @module2.prerequisites.should_not be_empty
      @module2.available_for?(@user, :tag => @tag2, :deep_check_if_needed => true).should be_false

      # same with sequential progress enabled
      @module2.update_attribute(:require_sequential_progress, true)
      @module2.available_for?(@user, :tag => @tag2).should be_false
      @module2.available_for?(@user, :tag => @tag2, :deep_check_if_needed => true).should be_false
      @module.update_attribute(:require_sequential_progress, true)
      @module2.available_for?(@user, :tag => @tag2).should be_false
      @module2.available_for?(@user, :tag => @tag2, :deep_check_if_needed => true).should be_false
    end

    it "should create an unlocked progression if there are prerequisites that are met" do
      course_module
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @module2 = @course.context_modules.create!(:name => "another module")
      @tag = @module2.add_item(:id => @assignment.id, :type => 'assignment')
      @module2.prerequisites = "module_#{@module.id}"
      @module2.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module2.save!
      @progression = @module.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.reload
      @progression.should be_completed
      @user.reload
      @progression = @module2.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_unlocked
    end
    
    it "should create a completed progression if there are prerequisites and requirements met" do
      course_module
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @module2 = @course.context_modules.create!(:name => "another module")
      @tag = @module2.add_item(:id => @assignment.id, :type => 'assignment')
      @module2.prerequisites = "module_#{@module.id}"
      @module2.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module2.save!
      @module2.update_for(@user, :read, @tag)
      @progression = @module.evaluate_for(@user)
      @progression.should_not be_nil
      @progression.should be_completed
      @user.reload
      @progression = @module2.evaluate_for(@user)
      @progression.should_not be_nil
      @progression.should be_completed
    end
    it "should update progression status on grading and view events" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @assignment2 = @course.assignments.create!(:title => "another assignment")
      @tag2 = @module.add_item({:id => @assignment2.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module.save!
      @teacher = User.create!(:name => "some teacher")
      @course.enroll_teacher(@teacher)
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)
      @progression = @module.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_unlocked
      @assignment.locked_for?(@user).should eql(false)
      @assignment2.locked_for?(@user).should eql(false)
      
      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!
      @module2.prerequisites.should_not be_nil
      @module2.prerequisites.should_not be_empty
      @progression = @module2.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_locked
      @assignment.context_module_action(@user, :read, nil)
      @progression = @module2.evaluate_for(@user)
      @progression.should be_completed
      @progression = @module.evaluate_for(@user)
      @progression.should be_completed
      
      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 5}}
      @module.save
      @module2.reload
      @progression = @module2.evaluate_for(@user)
      @progression.should be_locked
      @progression = @module.evaluate_for(@user)
      @progression.should be_unlocked
      
      @assignment.reload
      @assignment.grade_student(@user, :grade => "10", :grader => @teacher)
      @progression = @module2.evaluate_for(@user)
      @progression.should be_completed
      @progression = @module.evaluate_for(@user)
      @progression.should be_completed

      @assignment.reload
      @module2.reload
      @module.reload
      @submissions = @assignment.grade_student(@user, :grade => "4", :grader => @teacher)
      @user.reload
      @progression = @module2.evaluate_for(@user)
      @progression.should be_locked
      @progression = @module.evaluate_for(@user)
      @progression.should be_unlocked
      
      @submissions[0].score = 10
      @submissions[0].save!
      @module2.reload
      @module.reload
      @progression = @module2.evaluate_for(@user)
      @progression.should be_completed
      @progression = @module.evaluate_for(@user)
      @progression.should be_completed
    end
    
    it "should mark progression completed for min_score on discussion topic assignment" do
      asmnt = assignment_model(:submission_types => "discussion_topic", :points_possible => 10)
      topic = asmnt.discussion_topic
      @course.offer
      course_with_student(:active_all => true, :course => @course)
      mod = @course.context_modules.create!(:name => "some module")
      
      tag = mod.add_item({:id => topic.id, :type => 'discussion_topic'})
      mod.completion_requirements = {tag.id => {:type => 'min_score', :min_score => 5}}
      mod.save!
      
      p = mod.evaluate_for(@student, true)
      p.requirements_met.should == []
      p.workflow_state.should == 'unlocked'
      
      entry = topic.discussion_entries.create!(:message => "hi", :user => @student)
      asmnt.reload
      sub = asmnt.submissions.first
      sub.score = 5
      sub.workflow_state = 'graded'
      sub.save!
      
      p = mod.evaluate_for(@student)
      p.requirements_met.should == [{:type=>"min_score", :min_score=>5, :id=>tag.id}]
      p.workflow_state.should == 'completed'
    end
  end
  describe "require_sequential_progress" do
    it "should update progression status on grading and view events" do
      course_module
      @module.require_sequential_progress = true
      @module.save!
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @assignment2 = @course.assignments.create!(:title => "another assignment")
      @tag2 = @module.add_item(:id => @assignment2.id, :type => 'assignment')
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module.save!
      @teacher = User.create!(:name => "some teacher")
      @course.enroll_teacher(@teacher)
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)
      @progression = @module.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_unlocked
      @progression.current_position.should eql(@tag.position)
      @assignment.reload; @assignment2.reload
      @assignment.locked_for?(@user).should eql(false)
      @assignment2.locked_for?(@user).should_not eql(false)
      
      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!
      @module2.prerequisites.should_not be_nil
      @module2.prerequisites.should_not be_empty
      @progression = @module2.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_locked
      @assignment.context_module_action(@user, :read, nil)
      @progression = @module2.evaluate_for(@user)
      @progression.should be_completed
      @progression = @module.evaluate_for(@user)
      @progression.should be_completed
      @progression.current_position.should eql(@tag2.position)
      @assignment.reload; @assignment2.reload
      @assignment.locked_for?(@user).should eql(false)
      @assignment2.locked_for?(@user).should eql(false)
      
      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 5}}
      @module.save
      @module2.reload
      @progression = @module2.evaluate_for(@user)
      @progression.should be_locked
      @progression = @module.evaluate_for(@user)
      @progression.should be_unlocked
      @progression.current_position.should eql(@tag.position)
      @assignment.reload; @assignment2.reload
      @assignment.locked_for?(@user).should eql(false)
      @assignment2.locked_for?(@user).should_not eql(false)
      
      @assignment.reload
      @assignment.grade_student(@user, :grade => "10", :grader => @teacher)
      @progression = @module2.evaluate_for(@user)
      @progression.should be_completed
      @progression = @module.evaluate_for(@user)
      @progression.should be_completed
      @progression.current_position.should eql(@tag2.position)

      @assignment.reload
      @module2.reload
      @module.reload
      @submissions = @assignment.grade_student(@user, :grade => "4", :grader => @teacher)
      @user.reload
      @progression = @module2.evaluate_for(@user)
      @progression.should be_locked
      @progression = @module.evaluate_for(@user)
      @progression.should be_unlocked
      @progression.current_position.should eql(@tag.position)
      
      @submissions[0].score = 10
      @submissions[0].save!
      @module2.reload
      @module.reload
      @progression = @module2.evaluate_for(@user)
      @progression.should be_completed
      @progression = @module.evaluate_for(@user)
      @progression.should be_completed
      @progression.current_position.should eql(@tag2.position)
    end
    
    it "should update progression status on grading and view events for quizzes too" do
      course_module
      @module.require_sequential_progress = true
      @module.save!
      @quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :scoring_policy => 'keep_highest')
      @quiz.workflow_state = 'available'
      @quiz.save!
      @assignment = @course.assignments.create!(:title => "some assignment")
      
      @tag = @module.add_item({:id => @quiz.id, :type => 'quiz'})
      @tag2 = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 90}}
      @module.save!
      
      @teacher = User.create!(:name => "some teacher")
      @course.enroll_teacher(@teacher)
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)
      
      @progression = @module.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_unlocked
      @progression.current_position.should eql(@tag.position)
      @quiz.reload; @assignment.reload
      @quiz.locked_for?(@user).should be_false
      @assignment.locked_for?(@user).should be_true
      
      @submission = @quiz.generate_submission(@user)
      @submission.score = 100
      @submission.workflow_state = 'complete'
      @submission.submission_data = nil
      @submission.with_versioning(&:save)

      @progression = @module.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_completed
      @progression.current_position.should eql(@tag2.position)
      @quiz.reload; @assignment = Assignment.find(@assignment.id)
      @quiz.locked_for?(@user).should be_false
      @assignment.locked_for?(@user).should be_false

      # the quiz keeps the highest score; should still be unlocked
      @submission.score = 50
      @submission.attempt = 2
      @submission.with_versioning(&:save)
      @submission.kept_score.should == 100

      @progression = @module.evaluate_for(@user, true)
      @progression.should_not be_nil
      @progression.should be_completed
      @progression.current_position.should eql(@tag2.position)
      @quiz.reload; @assignment = Assignment.find(@assignment.id)
      @quiz.locked_for?(@user).should be_false
      @assignment.locked_for?(@user).should be_false

      # the quiz keeps the highest score; should still be unlocked
      @submission.update_scores(nil)
      @submission.score.should == 0
      @submission.kept_score.should == 100

      # update_for was called; don't re-evaluate
      @progression.reload
      @progression.should_not be_nil
      @progression.should be_completed
      @progression.current_position.should eql(@tag2.position)
      @quiz.reload; @assignment = Assignment.find(@assignment.id)
      @quiz.locked_for?(@user).should be_false
      @assignment.locked_for?(@user).should be_false
    end
  end

  context 'unpublished completion requirements' do
    before do
      course_module
      course_with_student(course: @course, user: @student, active_all: true)

      @assignment = @course.assignments.create!(title: 'some assignment')
      @assignment.workflow_state = 'unpublished'
      @assignment.save!
      @assignment_tag = @module.add_item({id: @assignment.id, type: 'assignment'})

      @other_assignment = @course.assignments.create!(title: 'other assignment')
      @other_assignment_tag = @module.add_item({id: @other_assignment.id, type: 'assignment'})

      @module.completion_requirements = [
        {id: @assignment_tag.id, type: 'min_score', min_score: 90},
        {id: @other_assignment_tag.id, type: 'min_score', min_score: 90},
      ]
      @module.save!

      @module.completion_requirements.include?({id: @assignment_tag.id, type: 'min_score', min_score: 90}).should be_true
      @module.completion_requirements.include?({id: @other_assignment_tag.id, type: 'min_score', min_score: 90}).should be_true
    end

    it 'should not prevent a student from completing a module' do
      @other_assignment.grade_student(@student, :grade => '95')
      @module.evaluate_for(@student).should be_completed
    end
  end

  describe "after_save" do
    before do
      course_module
      course_with_student(:course => @course, :active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 90}}
      @module.save!
    end

    it "should not recompute everybody's progressions" do
      new_module = @course.context_modules.build :name => 'new module'
      new_module.prerequisites = "context_module_#{@module.id}"

      ContextModule.any_instance.expects(:re_evaluate_for).never
      new_module.save!
      run_jobs
    end
  end

  describe "#completion_events" do
    it "should serialize correctly" do
      cm = ContextModule.new
      cm.completion_events = []
      cm.completion_events.should == []

      cm.completion_events = ['publish_final_grade']
      cm.completion_events.should == [:publish_final_grade]
    end

    it "should generate methods correctly" do
      cm = ContextModule.new
      cm.publish_final_grade?.should be_false
      cm.publish_final_grade = true
      cm.publish_final_grade?.should be_true
      cm.publish_final_grade = false
      cm.publish_final_grade?.should be_false
    end
  end

  describe "#find_or_create_progression" do
    it "should not create progressions for non-enrolled users" do
      course = Course.create!
      cm = course.context_modules.create!
      user = User.create!
      cm.find_or_create_progression(user).should == nil
    end
  end

  describe "restore" do
    it "should restore to unpublished state if draft_state is enabled" do
      course(draft_state: true)
      @module = @course.context_modules.create!
      @module.destroy
      @module.restore
      @module.reload.should be_unpublished
    end
  end
end
