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
      expect(@module.available_for?(nil)).to eql(true)
    end
  end
  
  describe "prerequisites=" do
    it "should assign prerequisites" do
      course_module
      @module2 = @course.context_modules.create!(:name => "next module")
      @module2.prerequisites = "module_#{@module.id}"
      expect(@module2.prerequisites).to be_is_a(Array)
      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.prerequisites[0][:id]).to eql(@module.id)
    end

    it "should add prereqs to new module" do
      course_module
      @module2 = @course.context_modules.build(:name => "next module")
      @module2.prerequisites = "module_#{@module.id}"

      expect(@module2.prerequisites).to be_is_a(Array)
      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.prerequisites[0][:id]).to eql(@module.id)
    end
      
    it "should remove invalid prerequisites" do
      course_module
      @module2 = @course.context_modules.create!(:name => "next module")
      @module2.prerequisites = "module_#{@module.id}"
      expect(@module2.prerequisites).to be_is_a(Array)
      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.prerequisites[0][:id]).to eql(@module.id)
      
      pres = @module2.prerequisites
      @module2.prerequisites = pres + [{:id => -1, :type => 'asdf'}]
      expect(@module2.prerequisites).to eql(pres)
    end
    
    it "should not allow looping prerequisites" do
      course_module
      @module2 = @course.context_modules.build(:name => "next module")
      @module2.prerequisites = "module_#{@module.id}"
      expect(@module2.prerequisites).to be_is_a(Array)
      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.prerequisites[0][:id]).to eql(@module.id)

      @module.prerequisites = "module_#{@module2.id}"
      expect(@module2.prerequisites).to be_is_a(Array)
      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.prerequisites[0][:id]).to eql(@module.id)
      expect(@module.prerequisites).to be_is_a(Array)
      expect(@module.prerequisites).to be_empty
    end
    
    it "should not allow adding invalid prerequisites" do
      course_module
      @module2 = @course.context_modules.build(:name => "next module")
      invalid = course().context_modules.build(:name => "nope")
      @module2.prerequisites = "module_#{@module.id},module_#{invalid.id}"

      expect(@module2.prerequisites).to be_is_a(Array)
      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.prerequisites[0][:id]).to eql(@module.id)
      expect(@module2.prerequisites.length).to eql(1)
    end
  end
  
  describe "add_item" do
    it "should add an assignment" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'}) #@assignment)

      expect(@tag.content).to eql(@assignment)
      expect(@module.content_tags).to be_include(@tag)
    end
    
    it "should not add an invalid assignment" do
      course_module
      @tag = @module.add_item({:id => 21, :type => 'assignment'})
      expect(@tag).to be_nil
    end
    
    it "should add a wiki page" do
      course_module
      @page = @course.wiki.wiki_pages.create!(:title => "some page")
      @tag = @module.add_item({:id => @page.id, :type => 'wiki_page'}) #@page)

      expect(@tag.content).to eql(@page)
      expect(@module.content_tags).to be_include(@tag)
    end

    it "should not add invalid wiki pages" do
      course_module
      @course.wiki
      @wiki = Wiki.create!(:title => "new wiki")
      @page = @wiki.wiki_pages.create!(:title => "new page")
      @tag = @module.add_item({:id => @page.id, :type => 'wiki_page'})
      expect(@tag).to be_nil
    end
    
    it "should add an attachment" do
      course_module
      @file = @course.attachments.create!(:display_name => "some file", :uploaded_data => default_uploaded_data)
      @tag = @module.add_item({:id => @file.id, :type => 'attachment'}) #@file)

      expect(@tag.content).to eql(@file)
      expect(@module.content_tags).to be_include(@tag)
    end

    it "should allow adding items more than once" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag1 = @module.add_item(:id => @assignment.id, :type => "assignment")
      @tag2 = @module.add_item(:id => @assignment.id, :type => "assignment")
      expect(@tag1).not_to eq @tag2
      expect(@module.content_tags).to be_include(@tag1)
      expect(@module.content_tags).to be_include(@tag2)

      @mod2 = @course.context_modules.create!(:name => "mod2")
      @tag3 = @mod2.add_item(:id => @assignment.id, :type => "assignment")
      expect(@tag3).not_to eq @tag1
      expect(@tag3).not_to eq @tag2
      expect(@mod2.content_tags).to eq [@tag3]
    end

    it "should add a header as unpublished" do
      course_module
      @course.enable_feature!(:draft_state)
      tag = @module.add_item(type: 'context_module_sub_header', title: 'unpublished header')
      expect(tag.unpublished?).to be_truthy
    end

    context "when draft state is enabled" do
      before do
        Course.any_instance.stubs(:feature_enabled?).with(:draft_state).returns(true)
        Course.any_instance.stubs(:feature_enabled?).with(:differentiated_assignments).returns(false)
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
        expect(@tag.unpublished?).to be_truthy
      end

      it "adds external_url with a default workflow_state of unpublished" do
        course_module
        @tag = @module.add_item(:type => 'external_url', :url => 'http://example.com/lolcats', :title => 'pls view', :indent => 1)
        expect(@tag.unpublished?).to be_truthy
      end

      it "should add a header as unpublished" do
        course_module
        tag = @module.add_item(type: 'context_module_sub_header', title: 'unpublished header')
        expect(tag.unpublished?).to be_truthy
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

      completion_requirements = @module.completion_requirements
      expect(completion_requirements[0][:id]).to eql(@tag.id)
      expect(completion_requirements[0][:type]).to eql('must_view')
    end
      
    it "should remove invalid requirements" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'}) #@assignment)
      req = {}
      req[@tag.id] = {:type => 'must_view'}

      @module.completion_requirements = req
      
      reqs = @module.completion_requirements
      expect(reqs[0][:id]).to eql(@tag.id)
      expect(reqs[0][:type]).to eql('must_view')

      @module.completion_requirements = reqs + [{:id => -1, :type => 'asdf'}]
      expect(@module.completion_requirements).to eql(reqs)
    end

    it 'should ignore invalid requirements' do
      course_module
      @module.completion_requirements = {"none"=>"none"} # the front-end likes to pass this in...

      expect(@module.completion_requirements).to be_empty
    end

    it 'should not remove unpublished requirements' do
      course_module
      @assignment = @course.assignments.create!(title: 'some assignment')
      @assignment.workflow_state = 'unpublished'

      @tag = @module.add_item({id: @assignment.id, type: 'assignment'})
      @module.completion_requirements = { @tag.id => {type: 'must_view'} }

      expect(@module.completion_requirements).to eql([id: @tag.id, type: 'must_view'])
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
      expect(@progression.requirements_met[0][:id]).to eql(@tag.id)
    end

    it "should return nothing if the user isn't a part of the context" do
      course_module
      @user = User.create!(:name => "some name")
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item(:id => @assignment.id, :type => 'assignment')
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @progression = @module.update_for(@user, :read, @tag)
      expect(@progression).to be_nil
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
      expect(mods_with_progressions).not_to be_include othermods[1].id
      expect(mods_with_progressions).not_to be_include othermods[2].id
    end

    it 'should not remove completed contribution requirements when viewed' do
      student_in_course(active_all: true)
      mod = @course.context_modules.create!(name: 'Module')
      page = @course.wiki.wiki_pages.create!(title: 'Edit This Page')
      tag = mod.add_item(id: page.id, type: 'wiki_page')
      mod.completion_requirements = [{ id: tag.id, type: 'must_contribute' }]
      mod.workflow_state = 'active'
      mod.save!

      progression = mod.update_for(@student, :contributed, tag)
      reqs_met = progression.requirements_met.map{ |r| { id: r[:id], type: r[:type] } }
      expect(reqs_met).to eq [{ id: tag.id, type: 'must_contribute' }]

      progression = mod.update_for(@student, :read, tag)
      reqs_met = progression.requirements_met.map{ |r| { id: r[:id], type: r[:type] } }
      expect(reqs_met).to eq [{ id: tag.id, type: 'must_contribute' }]
    end
  end
  
  describe "evaluate_for" do
    it "should create a completed progression for no prerequisites and no requirements" do
      course_module
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
    end

    it "should trigger completion events" do
      course_module
      @module.completion_events = [:publish_final_grade]
      @module.context = @course
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)

      @course.expects(:publish_final_grades).with(@user, @user.id).once

      @module.evaluate_for(@user)
    end

    it "should create an unlocked progression for no prerequisites" do
      course_module
      @user = User.create!(:name => "some name")
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item(:id => @assignment.id, :type => 'assignment')
      expect(@tag).not_to be_nil
      @course.enroll_student(@user)
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_unlocked
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

      expect(@module2.prerequisites).not_to be_empty
      @progression = @module2.evaluate_for(@user)
      expect(@progression).to be_locked
      @progression.destroy

      @progression = @module2.evaluate_for(@user)
      expect(@progression).to be_locked
    end

    it "should create an unlocked progression if prerequisites is unpublished" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module.workflow_state = 'unpublished'
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)

      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.publish
      @module2.prerequisites = "module_#{@module.id}"
      expect(@module2.prerequisites).not_to be_empty

      @progression = @module2.evaluate_for(@user)
      expect(@progression).not_to be_locked
      @progression.destroy

      @progression = @module2.evaluate_for(@user)
      expect(@progression).not_to be_locked
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
        expect(@a2.locked_for?(@user)).to be_falsey
        @tag2 = @module.add_item({:id => @a2.id, :type => 'assignment'})
        expect(@a2.reload.locked_for?(@user)).to be_truthy

        @mod2 = @course.context_modules.create!(:name => "mod2")
        @tag3 = @mod2.add_item({:id => @a2.id, :type => 'assignment'})
        # not locked, because the second tag allows access
        expect(@a2.reload.locked_for?(@user)).to be_falsey
        @mod2.prerequisites = "module_#{@module.id}"
        @mod2.save!
        # now locked, because mod2 is locked
        expect(@a2.reload.locked_for?(@user)).to be_truthy
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

      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.available_for?(@user, :tag => @tag2, :deep_check_if_needed => true)).to be_falsey

      # same with sequential progress enabled
      @module2.update_attribute(:require_sequential_progress, true)
      expect(@module2.available_for?(@user, :tag => @tag2)).to be_falsey
      expect(@module2.available_for?(@user, :tag => @tag2, :deep_check_if_needed => true)).to be_falsey
      @module.update_attribute(:require_sequential_progress, true)
      expect(@module2.available_for?(@user, :tag => @tag2)).to be_falsey
      expect(@module2.available_for?(@user, :tag => @tag2, :deep_check_if_needed => true)).to be_falsey
    end

    it "should be available to observers" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module.save!
      @student = User.create!(:name => "some name")
      @course.enroll_student(@student)

      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.prerequisites = "module_#{@module.id}"
      @assignment2 = @course.assignments.create!(:title => 'a2')
      @tag2 = @module2.add_item({:id => @assignment2.id, :type => 'assignment'})
      @module2.completion_requirements = {@tag2.id => {:type => 'must_view'}}
      @module2.save!

      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.available_for?(@student, :tag => @tag2, :deep_check_if_needed => true)).to be_falsey

      @course.enroll_user(user, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
      user_session(@user)

      expect(@module2.available_for?(@user, :tag => @tag2, :deep_check_if_needed => true)).to be_truthy

      @module2.update_attribute(:require_sequential_progress, true)
      expect(@module2.available_for?(@user, :tag => @tag2)).to be_truthy
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

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed

      @progression = @module2.evaluate_for(@user)
      expect(@progression).to be_unlocked
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
      expect(@progression).to be_completed

      @progression = @module2.evaluate_for(@user)
      expect(@progression).to be_completed
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

      expect(@module.evaluate_for(@user)).to be_unlocked
      expect(@assignment.locked_for?(@user)).to eql(false)
      expect(@assignment2.locked_for?(@user)).to eql(false)
      
      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!

      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.evaluate_for(@user)).to be_locked

      @assignment.context_module_action(@user, :read, nil)

      expect(@module2.evaluate_for(@user)).to be_completed
      expect(@module.evaluate_for(@user)).to be_completed
      
      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 5}}
      @module.save!

      expect(@module2.evaluate_for(@user)).to be_locked
      expect(@module.evaluate_for(@user)).to be_unlocked
      
      @assignment.reload
      @assignment.grade_student(@user, :grade => "10", :grader => @teacher)

      @progression = @module2.evaluate_for(@user)
      expect(@progression).to be_completed, "should be completed, is #{@progression.workflow_state}"
      expect(@module.evaluate_for(@user)).to be_completed

      @submissions = @assignment.reload.grade_student(@user, :grade => "4", :grader => @teacher)

      expect(@module2.evaluate_for(@user)).to be_locked
      expect(@module.evaluate_for(@user)).to be_unlocked
      
      @submissions[0].score = 10
      @submissions[0].save!

      expect(@module2.evaluate_for(@user)).to be_completed
      expect(@module.evaluate_for(@user)).to be_completed
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
      
      p = mod.evaluate_for(@student)
      expect(p.requirements_met).to be_empty
      expect(p).to be_unlocked

      topic.discussion_entries.create!(:message => "hi", :user => @student)
      
      sub = asmnt.reload.submissions.first
      sub.score = 5
      sub.workflow_state = 'graded'
      sub.save!
      
      p = mod.evaluate_for(@student)
      expect(p.requirements_met).to eq [{:type=>"min_score", :min_score=>5, :id=>tag.id}]
      expect(p).to be_completed
    end

    it "should not fulfill 'must_submit' requirement with 'untaken' quiz submission" do
      course_module
      student_in_course course: @course, active_all: true
      @quiz = @course.quizzes.create!(title: "some quiz")
      @tag = @module.add_item({id: @quiz.id, type: 'quiz'})
      @tag.publish!
      @module.completion_requirements = {@tag.id => {type: 'must_submit'}}
      @module.save!

      @submission = @quiz.generate_submission(@student)
      expect(@module.evaluate_for(@student)).to be_unlocked

      @submission.update_attribute(:workflow_state, 'complete')
      expect(@module.evaluate_for(@student)).to be_completed
    end

    it "should not fulfill 'must_submit' requirement with 'unsubmitted' assignment submission" do
      course_module
      student_in_course course: @course, active_all: true
      @assign = @course.assignments.create!(title: 'how many roads must a man walk down?', submission_types: 'online_text_entry')
      @tag = @module.add_item({id: @assign.id, type: 'assignment'})
      @module.completion_requirements = {@tag.id => {type: 'must_submit'}}
      @module.save!

      @submission = @assign.submit_homework(@student)
      expect(@module.evaluate_for(@student)).to be_unlocked

      @submission = @assign.submit_homework(@student, submission_type: 'online_text_entry', body: '42')
      expect(@module.evaluate_for(@student)).to be_completed
    end

    context "differentiated assignements" do
      before do
        course_module
        @student_1 = student_in_course(course: @course, active_all: true).user
        @student_2 = student_in_course(course: @course, active_all: true).user

        @student_1.enrollments.each(&:destroy!)
        @overriden_section = @course.course_sections.create!(name: "test section")
        student_in_section(@overriden_section, user: @student_1)

        @assign = @course.assignments.create!(title: 'how many roads must a man walk down?', submission_types: 'online_text_entry')
        @assign.only_visible_to_overrides = true
        @assign.save!
        create_section_override_for_assignment(@assign, {course_section: @overriden_section})

        @tag = @module.add_item({id: @assign.id, type: 'assignment'})
        @module.completion_requirements = {@tag.id => {type: 'must_submit'}}
        @module.save!
      end

      context "enabled" do
        before {@course.enable_feature!(:differentiated_assignments)}
        it "should properly require differentiated assignments" do
          expect(@module.evaluate_for(@student_1)).to be_unlocked
          @submission = @assign.submit_homework(@student_1, submission_type: 'online_text_entry', body: '42')
          expect(@module.evaluate_for(@student_1)).to be_completed
          expect(@module.evaluate_for(@student_2)).to be_completed
        end
      end

      context "disabled" do
        before {@course.disable_feature!(:differentiated_assignments)}
        it "should properly require all assignments" do
          expect(@module.evaluate_for(@student_1)).to be_unlocked
          @submission = @assign.submit_homework(@student_1, submission_type: 'online_text_entry', body: '42')
          expect(@module.evaluate_for(@student_1)).to be_completed
          expect(@module.evaluate_for(@student_2)).to be_unlocked
        end
      end
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
      expect(@progression).to be_unlocked
      expect(@progression.current_position).to eql(@tag.position)
      expect(@assignment.reload.locked_for?(@user)).to be_falsey
      expect(@assignment2.reload.locked_for?(@user)).not_to be_falsey
      
      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!
      expect(@module2.prerequisites).not_to be_empty

      expect(@module2.evaluate_for(@user)).to be_locked

      @assignment.context_module_action(@user, :read, nil)
      expect(@module2.evaluate_for(@user)).to be_completed

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
      expect(@progression.current_position).to eql(@tag2.position)
      expect(@assignment.reload.locked_for?(@user)).to be_falsey
      expect(@assignment2.reload.locked_for?(@user)).to be_falsey
      
      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 5}}
      @module.save
      @module2.reload
      expect(@module2.evaluate_for(@user)).to be_locked

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_unlocked
      expect(@progression.current_position).to eql(@tag.position)
      
      expect(@assignment.reload.locked_for?(@user)).to be_falsey
      expect(@assignment2.reload.locked_for?(@user)).to be_truthy

      @assignment.reload.grade_student(@user, :grade => "10", :grader => @teacher)
      expect(@module2.evaluate_for(@user)).to be_completed

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
      expect(@progression.current_position).to eql(@tag2.position)

      @submissions = @assignment.reload.grade_student(@user, :grade => "4", :grader => @teacher)

      expect(@module2.evaluate_for(@user)).to be_locked

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_unlocked
      expect(@progression.current_position).to eql(@tag.position)
      
      @submissions[0].score = 10
      @submissions[0].save!

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
      expect(@progression.current_position).to eql(@tag2.position)

      expect(@module2.evaluate_for(@user)).to be_completed
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
      expect(@progression).to be_unlocked
      expect(@progression.current_position).to eql(@tag.position)

      expect(@quiz.reload.locked_for?(@user)).to be_falsey
      expect(@assignment.reload.locked_for?(@user)).to be_truthy
      
      @submission = @quiz.generate_submission(@user)
      @submission.score = 100
      @submission.workflow_state = 'complete'
      @submission.submission_data = nil
      @submission.with_versioning(&:save)

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
      expect(@progression.current_position).to eql(@tag2.position)

      expect(@quiz.reload.locked_for?(@user)).to be_falsey
      expect(@assignment.reload.locked_for?(@user)).to be_falsey

      # the quiz keeps the highest score; should still be unlocked
      @submission.score = 50
      @submission.attempt = 2
      @submission.with_versioning(&:save)
      expect(@submission.kept_score).to eq 100

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
      expect(@progression.current_position).to eql(@tag2.position)

      expect(@quiz.reload.locked_for?(@user)).to be_falsey
      expect(@assignment.reload.locked_for?(@user)).to be_falsey

      # the quiz keeps the highest score; should still be unlocked
      @submission.update_scores(nil)
      expect(@submission.score).to eq 0
      expect(@submission.kept_score).to eq 100

      # update_for was called; don't re-evaluate
      expect(@progression.reload).to be_completed
      expect(@progression.current_position).to eql(@tag2.position)

      expect(@quiz.reload.locked_for?(@user)).to be_falsey
      expect(@assignment.reload.locked_for?(@user)).to be_falsey
    end

    it "should progress on pre-refactor quiz tags" do
      course_module
      student_in_course course: @course, active_all: true
      @quiz = @course.quizzes.build(title: "some quiz")
      @quiz.workflow_state = 'available'
      @quiz.save!
      @tag = @module.add_item({id: @quiz.id, type: 'quiz'})
      @module.completion_requirements = {@tag.id => {type: 'must_submit'}}
      @module.save!
      @submission = @quiz.generate_submission(@student)
      @submission.workflow_state = 'complete'
      @submission.save!
      expect(@module.evaluate_for(@student).requirements_met).to be_include({id: @tag.id, type: 'must_submit'})
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

      expect(@module.completion_requirements.include?({id: @assignment_tag.id, type: 'min_score', min_score: 90})).to be_truthy
      expect(@module.completion_requirements.include?({id: @other_assignment_tag.id, type: 'min_score', min_score: 90})).to be_truthy
    end

    it 'should not prevent a student from completing a module' do
      @other_assignment.grade_student(@student, :grade => '95')
      expect(@module.evaluate_for(@student)).to be_completed
    end
  end

  describe "#completion_events" do
    it "should serialize correctly" do
      cm = ContextModule.new
      cm.completion_events = []
      expect(cm.completion_events).to eq []

      cm.completion_events = ['publish_final_grade']
      expect(cm.completion_events).to eq [:publish_final_grade]
    end

    it "should generate methods correctly" do
      cm = ContextModule.new
      expect(cm.publish_final_grade?).to be_falsey
      cm.publish_final_grade = true
      expect(cm.publish_final_grade?).to be_truthy
      cm.publish_final_grade = false
      expect(cm.publish_final_grade?).to be_falsey
    end
  end

  describe "content_tags_visible_to" do
    before do
      course_module
      @student_1 = student_in_course(course: @course, active_all: true).user
      @student_2 = student_in_course(course: @course, active_all: true).user

      @student_1.enrollments.each(&:destroy!)
      @overriden_section = @course.course_sections.create!(name: "test section")
      student_in_section(@overriden_section, user: @student_1)

      @assignment = @course.assignments.create!(title: 'how many roads must a man walk down?', submission_types: 'online_text_entry')
      @assignment.only_visible_to_overrides = true
      @assignment.save!
      create_section_override_for_assignment(@assignment, {course_section: @overriden_section})

      @tag = @module.add_item({id: @assignment.id, type: 'assignment'})
    end

    context "differentiated_assignments enabled" do
      before {@course.enable_feature!(:differentiated_assignments)}
      it "should properly return differentiated assignments" do
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@assignment)).to be_truthy
        expect(@module.content_tags_visible_to(@student_1).map(&:content).include?(@assignment)).to be_truthy
        expect(@module.content_tags_visible_to(@student_2).map(&:content).include?(@assignment)).to be_falsey
      end
      it "should properly return unpublished assignments" do
        @assignment.workflow_state = "unpublished"
        @assignment.save!
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@assignment)).to be_truthy
        expect(@module.content_tags_visible_to(@student_1).map(&:content).include?(@assignment)).to be_falsey
        expect(@module.content_tags_visible_to(@student_2).map(&:content).include?(@assignment)).to be_falsey
      end
      # if tags are preloaded we shouldn't filter by a scope (as that requires re-fetching the tags)
      it "should not reload the tags if already loaded" do
        ContentTag.expects(:visible_to_students_in_course_with_da).never
        ActiveRecord::Associations::Preloader.new(@module, content_tags: :content).run
        @module.content_tags_visible_to(@student_1)
      end
      # if tags are not preloaded we should filter by a scope (as will be quicker than filtering an array)
      it "should filter use a cope to filter content tags if they arent already loaded" do
        ContentTag.expects(:visible_to_students_in_course_with_da).once
        @module.content_tags_visible_to(@student_1)
      end
      it "should filter differentiated discussions" do
        discussion_topic_model(:user => @teacher, :context => @course)
        @discussion_assignment = @course.assignments.create!(:title => "some discussion assignment",only_visible_to_overrides: true)
        @discussion_assignment.submission_types = 'discussion_topic'
        @discussion_assignment.save!
        @topic.assignment_id = @discussion_assignment.id
        @topic.save!
        create_section_override_for_assignment(@discussion_assignment, {course_section: @overriden_section})
        @module.add_item({id: @topic.id, type: 'discussion_topic'})
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@topic)).to be_truthy
        expect(@module.content_tags_visible_to(@student_1).map(&:content).include?(@topic)).to be_truthy
        expect(@module.content_tags_visible_to(@student_2).map(&:content).include?(@topic)).to be_falsey
      end
      it "should filter differentiated quizzes" do
        @quiz = Quizzes::Quiz.create!({
          context: @course,
          description: 'descript foo',
          only_visible_to_overrides: true,
          points_possible: rand(1000),
          title: "differentiated quiz title"
        })
        @quiz.publish
        @quiz.save!
        create_section_override_for_quiz(@quiz, {course_section: @overriden_section})
        @module.add_item({id: @quiz.id, type: 'quiz'})
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@quiz)).to be_truthy
        expect(@module.content_tags_visible_to(@student_1).map(&:content).include?(@quiz)).to be_truthy
        expect(@module.content_tags_visible_to(@student_2).map(&:content).include?(@quiz)).to be_falsey
      end
      it "should work for observers" do
        @observer = User.create
        @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @overriden_section, :enrollment_state => 'active')
        @observer_enrollment.update_attribute(:associated_user_id, @student_2.id)
        expect(@module.content_tags_visible_to(@observer).map(&:content).include?(@assignment)).to be_falsey
        @observer_enrollment.update_attribute(:associated_user_id, @student_1.id)
        expect(@module.content_tags_visible_to(@observer).map(&:content).include?(@assignment)).to be_truthy
      end
    end

    context "differentiated_assignments disabled" do
      before {@course.disable_feature!(:differentiated_assignments)}
      it "should return all published assignments" do
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@assignment)).to be_truthy
        expect(@module.content_tags_visible_to(@student_1).map(&:content).include?(@assignment)).to be_truthy
        expect(@module.content_tags_visible_to(@student_2).map(&:content).include?(@assignment)).to be_truthy
      end
      it "should not return unpublished assignments" do
        @assignment.workflow_state = "unpublished"
        @assignment.save!
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@assignment)).to be_truthy
        expect(@module.content_tags_visible_to(@student_1).map(&:content).include?(@assignment)).to be_falsey
        expect(@module.content_tags_visible_to(@student_2).map(&:content).include?(@assignment)).to be_falsey
      end
    end
  end

  describe "#find_or_create_progression" do
    it "should not create progressions for non-enrolled users" do
      course = Course.create!
      cm = course.context_modules.create!
      user = User.create!
      expect(cm.find_or_create_progression(user)).to eq nil
    end
  end

  describe "restore" do
    it "should restore to unpublished state if draft_state is enabled" do
      course(draft_state: true)
      @module = @course.context_modules.create!
      @module.destroy
      @module.restore
      expect(@module.reload).to be_unpublished
    end
  end

  it "evaluates progressions after save" do
    course_module
    course_with_student(course: @course, user: @student, active_all: true)
    expect(@module.evaluate_for(@student)).to be_completed

    quiz = @course.quizzes.build(title: "some quiz")
    quiz.workflow_state = 'available'
    quiz.save!

    @tag = @module.add_item({id: quiz.id, type: 'quiz'})
    @module.completion_requirements = {@tag.id => {type: 'must_submit'}}

    @module.save!

    expect(@module.context_module_progressions.reload.size).to eq 1
    expect(@module.context_module_progressions.first).to be_unlocked
  end
end
