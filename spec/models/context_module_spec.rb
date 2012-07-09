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
      @module2.prerequisites = "module_#{@module.id},module_99"
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
    
    it "should add pages from secondary wikis" do
      course_module
      @course.wiki
      @wiki = Wiki.create!(:title => "new wiki")
      @namespace = @course.wiki_namespaces.build
      @namespace.wiki = @wiki
      @namespace.save!
      @page = @wiki.wiki_pages.create!(:title => "new page")
      @tag = @module.add_item({:id => @page.id, :type => 'wiki_page'})
      @tag.should_not be_nil
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
  end
  
  describe "evaluate_for" do
    it "should create a completed progression for no prerequisites and no requirements" do
      course_module
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)
      @progression = @module.evaluate_for(@user)
      @progression.should_not be_nil
      @progression.should be_completed
    end

    it "should create an unlocked progression for no prerequisites" do
      course_module
      @user = User.create!(:name => "some name")
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item(:id => @assignment.id, :type => 'assignment')
      @tag.should_not be_nil
      @course.enroll_student(@user)
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @progression = @module.evaluate_for(@user)
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
      # @progression = @module.evaluate_for(@user, true)
      # @progression.should_not be_nil
      # @progression.should be_unlocked
      # @progression.destroy
      
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
      @module2.available_for?(@user, @tag2, true).should be_false

      # same with sequential progress enabled
      @module2.update_attribute(:require_sequential_progress, true)
      @module2.available_for?(@user, @tag2).should be_false
      @module2.available_for?(@user, @tag2, true).should be_false
      @module.update_attribute(:require_sequential_progress, true)
      @module2.available_for?(@user, @tag2).should be_false
      @module2.available_for?(@user, @tag2, true).should be_false
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
      @progression = @module.evaluate_for(@user)
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
      course_with_student(:active_all => true, :course => @course)
      mod = @course.context_modules.create!(:name => "some module")
      
      tag = mod.add_item({:id => topic.id, :type => 'discussion_topic'})
      mod.completion_requirements = {tag.id => {:type => 'min_score', :min_score => 5}}
      mod.save!
      
      p = mod.evaluate_for(@student)
      p.requirements_met.should == []
      p.workflow_state.should == 'unlocked'
      
      entry = topic.discussion_entries.create!(:message => "hi", :user => @student)
      asmnt.reload
      sub = asmnt.submissions.first
      sub.score = 5
      sub.workflow_state = 'graded'
      sub.save!
      
      p = mod.evaluate_for(@student)
      p.requirements_met.should == [{:type=>"min_score", :min_score=>5, :max_score=>nil, :id=>tag.id}]
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
      @progression = @module.evaluate_for(@user)
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
      
      @progression = @module.evaluate_for(@user)
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

      @progression = @module.evaluate_for(@user, true, true)
      @progression.should_not be_nil
      @progression.should be_completed
      @progression.current_position.should eql(@tag2.position)
      @quiz.reload; @assignment = Assignment.find(@assignment.id)
      @quiz.locked_for?(@user).should be_false
      @assignment.locked_for?(@user).should be_false

      # the quiz keeps the highest score; should still be unlocked
      @submission.score = 50
      @submission.with_versioning(&:save)
      @submission.kept_score.should == 100

      @progression = @module.evaluate_for(@user, true, true)
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
  describe "clone_for" do
    it "should clone a context module" do
      course_module
      @old_course = @course
      @old_module = @module
      course_model
      @module = @old_module.clone_for(@course)
      @module.should_not eql(@old_module)
      @module.cloned_item_id.should eql(@old_module.cloned_item_id)
      @module.name.should eql(@old_module.name)
      @module.context.should eql(@course)
    end
    
    it "should clone all tags inside a context module and their associated content" do
      course_module
      @old_course = @course
      @old_module = @module
      @old_assignment = @course.assignments.create!(:title => "my assignment")
      @old_tag = @old_module.add_item({:type => 'assignment', :id => @old_assignment.id})
      ct = @old_module.add_item({ :title => 'Broken url example', :type => 'external_url', :url => 'http://example.com/with%20space' })
      ContentTag.update_all({:url => "http://example.com/with space"}, "id=#{ct.id}")
      @old_module.reload
      @old_module.content_tags.length.should eql(2)
      course_model
      @module = @old_module.clone_for(@course)
      @module.should_not eql(@old_module)
      @module.cloned_item_id.should eql(@old_module.cloned_item_id)
      @module.name.should eql(@old_module.name)
      @module.context.should eql(@course)
      @module.reload
      @course.reload
      @old_tag.reload
      
      @module.content_tags.length.should eql(2)
      @tag = @module.content_tags.first
      @tag.should_not eql(@old_tag)
      @tag.cloned_item_id.should eql(@old_tag.cloned_item_id)
      @tag.content.should_not eql(@old_tag.content)
      @tag.content.should eql(@course.assignments.first)
      @tag.content.cloned_item_id.should eql(@old_tag.content.cloned_item_id)
      ct2 = @module.content_tags[1]
      ct2.url.should == 'http://example.com/with%20space'
    end
    
    it "should update module requirements to reflect new tag id's" do
      course_module
      @old_course = @course
      @old_module = @module
      @old_assignment = @course.assignments.create!(:title => "my assignment")
      @old_tag = @old_module.add_item({:type => 'assignment', :id => @old_assignment.id})
      @old_module.reload
      @old_module.content_tags.length.should eql(1)
      reqs = {}
      reqs[@old_tag.id.to_s] = {:type => "must_view"}
      @old_module.completion_requirements = reqs
      @old_module.completion_requirements.should_not be_nil
      @old_module.completion_requirements.length.should eql(1)
      course_model
      @module = @old_module.clone_for(@course)
      @module.save!
      @module.should_not eql(@old_module)
      @module.cloned_item_id.should eql(@old_module.cloned_item_id)
      @module.name.should eql(@old_module.name)
      @module.context.should eql(@course)
      @module.reload
      @course.reload
      @old_tag.reload
      @module.content_tags.length.should eql(1)
      @tag = @module.content_tags.first
      @tag.should_not eql(@old_tag)
      @tag.cloned_item_id.should eql(@old_tag.cloned_item_id)
      @tag.content.should_not eql(@old_tag.content)
      @tag.content.should eql(@course.assignments.first)
      @tag.content.cloned_item_id.should eql(@old_tag.content.cloned_item_id)
      @module.completion_requirements.length.should eql(1)
      @module.completion_requirements[0][:id].should eql(@tag.id)
    end
    it "should update module prerequisites to reflect new module id's" do
      course_module
      @old_course = @course
      @old_module = @module
      @old_module_2 = @course.context_modules.create!(:name => "another module")
      @old_module_3 = @course.context_modules.create!(:name => "another module")
      @old_module_3.prerequisites = [{:type => 'context_module', :id => @old_module.id}, {:type => 'context_module', :id => @old_module_2.id}]
      @old_module_3.save!
      course_module
      @module = @old_module.clone_for(@course)
      @module.save!
      @course.reload
      @course.context_modules.count.should eql(2)
      @module_3 = @old_module_3.clone_for(@course)
      @module_3.save!
      @module_3.prerequisites.length.should eql(1)
      @module_3.prerequisites[0][:id].should eql(@module.id)
    end
  end
end
