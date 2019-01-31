#
# Copyright (C) 2011 - present Instructure, Inc.
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
    course_with_student(active_all: true)
    @module = @course.context_modules.create!(:name => "some module")
  end

  describe "publish_items!" do
    before :once do
      course_module
      @file = @course.attachments.create!(:display_name => "some file", :uploaded_data => default_uploaded_data, :locked => true)
      @tag = @module.add_item(:id => @file.id, :type => "attachment")
    end

    context "with file usage rights required" do
      before :once do
        @course.enable_feature! :usage_rights_required
      end

      it "should not publish Attachment module items if usage rights are missing" do
        @module.publish_items!
        expect(@tag.published?).to eql(false)
        expect(@file.published?).to eql(false)
      end

      it "should publish Attachment module items if usage rights are present" do
        @file.usage_rights = @course.usage_rights.create(:use_justification => 'own_copyright')
        @file.save!

        @module.reload.publish_items!
        expect(@tag.reload.published?).to eql(true)
        expect(@file.reload.published?).to eql(true)
      end
    end

    context "without file usage rights required" do
      it "should publish Attachment module items" do
        @module.publish_items!
        expect(@tag.reload.published?).to eql(true)
        expect(@file.reload.published?).to eql(true)
      end
    end
  end

  describe "can_be_duplicated?" do
    it "forbid quiz" do
      course_module
      quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment")
      quiz.save!
      @module.add_item({:id => quiz.id, :type => 'quiz'})
      assignment = @course.assignments.create!(:title => "some assignment")
      @module.add_item({ id: assignment.id, :type => 'assignment' })
      expect(@module.can_be_duplicated?).to be_falsey
    end

    it "forbid quiz even if added as assignment" do
      course_module
      quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment")
      quiz.save!
      assignment = Assignment.find(quiz.assignment_id)
      @module.add_item({:id => assignment.id, :type => 'assignment'})
      expect(@module.can_be_duplicated?).to be_falsey
    end

    it "*deleted* quiz tags are ok" do
      course_module
      quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment")
      quiz.save!
      assignment = Assignment.find(quiz.assignment_id)
      @module.add_item({:id => assignment.id, :type => 'assignment'})
      @module.content_tags[0].workflow_state = 'deleted'
      expect(@module.can_be_duplicated?).to be_truthy
    end

    it "ok if no quiz" do
      course_module
      assignment = @course.assignments.create!(:title => "some assignment")
      @module.add_item({ id: assignment.id, :type => 'assignment' })
      expect(@module.can_be_duplicated?).to be_truthy
    end
  end

  it "duplicate" do
    course_module # name is "some module"
    assignment1 = @course.assignments.create!(:title => "assignment")
    assignment2 = @course.assignments.create!(:title => "assignment copy")
    @module.add_item(type: 'context_module_sub_header', title: 'unpublished header')
    @module.add_item({:id => assignment1.id, :type => 'assignment'})
    @module.unlock_at = Time.zone.now # doesn't matter what, just not nil
    @module.prerequisites = @module # This is silly, but just want something not nil
    quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment")
    quiz.save!
    # It is permitted to duplicate a module with a deleted quiz tag, but the deleted
    # item should not be duplicated.
    @module.add_item({:id => quiz.id, :type => 'quiz'})
    @module.content_tags[2].workflow_state = 'deleted'
    @module.add_item({:id => assignment2.id, :type => 'assignment'})

    @module.add_item(
      :type => 'external_url',
      :url => "http://www.instructure.com",
      :new_tab => true,
      :title => "Instructure",
      :indent => 0
    )

    @module.workflow_state = 'published'
    @module.save!
    new_module = @module.duplicate
    expect(new_module.name).to eq "some module Copy"
    expect(new_module.content_tags.length).to eq 4
    # Stuff with actual content should get unique names, but not stuff like headers.
    expect(new_module.content_tags[0].title).to eq('unpublished header')
    expect(new_module.content_tags[1].content.title).to eq('assignment Copy 2')
    # Respect original choice of "copy" if the thing I copied already made a decision.
    expect(new_module.content_tags[2].content.title).to eq('assignment copy 3')
    expect(new_module.workflow_state).to eq('unpublished')

    expect(new_module.content_tags[3].title).to eq('Instructure')
    expect(new_module.content_tags[3].url).to eq('http://www.instructure.com')
    expect(new_module.content_tags[3].new_tab).to eq(true)
    expect(new_module.unlock_at).to be_nil
    expect(new_module.prerequisites).to be_nil
  end

  describe "available_for?" do
    it "should return true by default" do
      course_module
      expect(@module.available_for?(nil)).to be(true)
    end

    it "returns true by default when require_sequential_progress is true and there are no requirements" do
      course_module
      @module.require_sequential_progress = true
      @module.save!
      expect(@module.available_for?(nil)).to eql(true)
    end

    it "uses provided progression in opts" do
      course_with_student(active_all: true)
      @module = @course.context_modules.create!(name: 'some module')
      @module.unlock_at = 2.months.from_now
      @module.save!
      @progression = @module.find_or_create_progression(@student)
      @progression.workflow_state = :unlocked # don't save
      expect(@module.available_for?(@student)).to be_falsey
      opts = {user_context_module_progressions: {@module.id => @progression}}
      expect(@module.available_for?(@student, opts)).to be_truthy
    end

    it "should reevaluate progressions if a tag is not provided and deep_check_if_needed is given" do
      module1 = course_module
      module1.find_or_create_progression(@student)
      module2 = course_module
      url_item = module2.content_tags.create!(content_type: 'ExternalUrl', context: @course,
        title: 'url', url: 'https://www.google.com')
      module2.completion_requirements = [{id: url_item.id, type: 'must_view'}]
      module2.prerequisites = [{id: module1.id, type: 'context_module', name: 'some module'}]
      module2.save!

      expect(module2.available_for?(@student)).to be false
      expect(module2.available_for?(@student, deep_check_if_needed: true)).to be true
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
      invalid = course_factory().context_modules.build(:name => "nope")
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
      @page = @course.wiki_pages.create!(:title => "some page")
      @tag = @module.add_item({:id => @page.id, :type => 'wiki_page'}) #@page)

      expect(@tag.content).to eql(@page)
      expect(@module.content_tags).to be_include(@tag)
    end

    it "should not add invalid wiki pages" do
      course_module
      @course.wiki
      other_course = Account.default.courses.create!
      @page = other_course.wiki_pages.create!(:title => "new page")
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
      tag = @module.add_item(type: 'context_module_sub_header', title: 'unpublished header')
      expect(tag.unpublished?).to be_truthy
    end

    it "should add an external url" do
      course_module
      @tag = @module.add_item(
        :type => 'external_url',
        :url => "http://www.instructure.com",
        :new_tab => true,
        :title => "Instructure",
        :indent => 0
      )
      @module.workflow_state = 'published'
      @module.save!

      expect(@module.content_tags).to be_include(@tag)
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
      @course.enroll_student(@user).accept!
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
      page = @course.wiki_pages.create! :title => "view this page"
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
      page = @course.wiki_pages.create!(title: 'Edit This Page')
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
      @course.enroll_student(@user).accept!

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
    end

    it "should set progression to complete for a module with 'Complete One Item' requirement when one item complete" do
      course_module
      @module.requirement_count = 1
      @quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment",
                                    :scoring_policy => 'keep_highest')
      @quiz.workflow_state = 'available'
      @quiz.save!
      @assignment = @course.assignments.create!(:title => "some assignment")

      @tag = @module.add_item({:id => @quiz.id, :type => 'quiz'})
      @tag2 = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 90},
                                         @tag2.id => {:type=> 'must_view'}}
      @module.save!

      @user = User.create!(:name => "some name")
      @course.enroll_student(@user).accept!

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_unlocked

      @module.update_for(@user, :read, @tag2)
      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed

    end

    it "should trigger completion events" do
      course_module
      @module.completion_events = [:publish_final_grade]
      @module.context = @course
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user).accept!

      allow(Canvas::Plugin.find!('grade_export')).to receive(:enabled?).and_return(true)
      expect(@course).to receive(:publish_final_grades).with(@user, @user.id).once

      @module.evaluate_for(@user)
    end

    it "should create an unlocked progression for no prerequisites" do
      course_module
      @user = User.create!(:name => "some name")
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item(:id => @assignment.id, :type => 'assignment')
      expect(@tag).not_to be_nil
      @course.enroll_student(@user).accept!
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
      @course.enroll_student(@user).accept!
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
      @course.enroll_student(@user).accept!

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
        @course.enroll_student(@user).accept!
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
      @course.enroll_student(@user).accept!

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
      @course.enroll_student(@student).accept!

      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.prerequisites = "module_#{@module.id}"
      @assignment2 = @course.assignments.create!(:title => 'a2')
      @tag2 = @module2.add_item({:id => @assignment2.id, :type => 'assignment'})
      @module2.completion_requirements = {@tag2.id => {:type => 'must_view'}}
      @module2.save!

      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.available_for?(@student, :tag => @tag2, :deep_check_if_needed => true)).to be_falsey

      @course.enroll_user(user_factory, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
      user_session(@user)

      expect(@module2.available_for?(@user, :tag => @tag2, :deep_check_if_needed => true)).to be_truthy

      @module2.update_attribute(:require_sequential_progress, true)
      expect(@module2.available_for?(@user, :tag => @tag2)).to be_truthy
    end

    it "should create an unlocked progression if there are prerequisites that are met" do
      course_module
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user).accept!
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
      @course.enroll_student(@user).accept!
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

    it "should update progression status to started if submitted for a min_score" do
      course_module
      @assignment = @course.assignments.create!(:title => "some assignment",  :submission_types => "online_text_entry")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 5.0}}
      @module.save!
      @teacher = User.create!(:name => "some teacher")
      @course.enroll_teacher(@teacher)
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user).accept!

      expect(@module.evaluate_for(@user)).to be_unlocked
      expect(@assignment.locked_for?(@user)).to eql(false)

      @assignment.submit_homework @user, :submission_type => "online_text_entry", :body => "stuff"

      prog = @module.evaluate_for(@user)
      expect(prog).to be_started
      incomplete_req = prog.incomplete_requirements.detect{|r| r[:id] == @tag.id}
      expect(incomplete_req).to be_present
      expect(incomplete_req[:score]).to be_nil

      @assignment.grade_student(@user, :grade => "4", :grader => @teacher)

      prog = @module.evaluate_for(@user)
      expect(prog).to be_started
      incomplete_req = prog.incomplete_requirements.detect{|r| r[:id] == @tag.id}
      expect(incomplete_req).to be_present
      expect(incomplete_req[:score]).to eq 4

      @assignment.grade_student(@user, :grade => "6", :grader => @teacher)
      expect(@module.evaluate_for(@user)).to be_completed
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
      @course.enroll_student(@user).accept!

      expect(@module.evaluate_for(@user)).to be_unlocked
      expect(@assignment.locked_for?(@user)).to eql(false)
      expect(@assignment2.locked_for?(@user)).to eql(false)

      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!

      expect(@module2.prerequisites).not_to be_empty
      expect(@module2.evaluate_for(@user)).to be_locked

      @assignment.context_module_action(@user, :read, nil)

      expect(@module2.reload.evaluate_for(@user)).to be_completed
      expect(@module.evaluate_for(@user)).to be_completed

      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 5}}
      @module.save!

      expect(@module2.evaluate_for(@user)).to be_completed
      @module.reload.relock_progressions
      expect(@module2.evaluate_for(@user)).to be_locked

      expect(@module.evaluate_for(@user)).to be_unlocked

      @assignment.reload
      @assignment.grade_student(@user, :grade => "10", :grader => @teacher)

      @progression = @module2.evaluate_for(@user)
      expect(@progression).to be_completed, "should be completed, is #{@progression.workflow_state}"
      expect(@module.evaluate_for(@user)).to be_completed

      @submissions = @assignment.reload.grade_student(@user, :grade => "4", :grader => @teacher)

      expect(@module2.evaluate_for(@user)).to be_completed
      @module.reload.relock_progressions
      expect(@module2.evaluate_for(@user)).to be_locked
      expect(@module.evaluate_for(@user)).to be_started

      @submissions[0].score = 10
      @submissions[0].save!

      expect(@module2.evaluate_for(@user)).to be_completed
      expect(@module.evaluate_for(@user)).to be_completed
    end

    it "should fulfill all assignment requirements on excused submission" do
      course_module
      student_in_course course: @course, active_all: true

      @teacher = User.create!(:name => "some teacher")
      @course.enroll_teacher(@teacher)

      @assign = @course.assignments.create!(title: 'title', submission_types: 'online_text_entry')
      @tag1 = @module.add_item({id: @assign.id, type: 'assignment'})
      @tag2 = @module.add_item({id: @assign.id, type: 'assignment'})
      @tag3 = @module.add_item({id: @assign.id, type: 'assignment'})

      @module.completion_requirements = {
        @tag1.id => {type: 'must_mark_done'},
        @tag2.id => {type: 'min_score', score: 5},
        @tag3.id => {type: 'must_view'}
      }
      @module.save!

      expect(@module.evaluate_for(@student)).to be_unlocked

      @assign.reload
      @assign.grade_student(@student, :grader => @teacher, :excuse => true)
      expect(@module.evaluate_for(@student)).to be_completed
    end

    describe "must_submit requirement" do
      before :once do
        course_module
        student_in_course course: @course, active_all: true

        @teacher = User.create!(:name => "some teacher")
        @course.enroll_teacher(@teacher)
      end

      it "should not fulfill assignment must_submit requirement on manual grade" do
        @assign = @course.assignments.create!(title: 'how many roads must a man walk down?', submission_types: 'online_text_entry')
        @tag = @module.add_item({id: @assign.id, type: 'assignment'})
        @module.completion_requirements = {@tag.id => {type: 'must_submit'}}
        @module.save!

        expect(@module.evaluate_for(@student)).to be_unlocked

        @assign.reload
        @assign.grade_student(@student, :grade => "5", :grader => @teacher)
        expect(@module.evaluate_for(@student)).to be_unlocked

        @assign.reload
        @assign.grade_student(@student, :grade => nil, :grader => @teacher)
        # removing the grade manually shouldn't mark as completed either
        expect(@module.evaluate_for(@student)).to be_unlocked
      end

      it "should not fulfill quiz must_submit requirement on manual grade" do
        @quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :scoring_policy => 'keep_highest')
        @quiz.workflow_state = 'available'
        @quiz.save!
        @tag = @module.add_item({:id => @quiz.id, :type => 'quiz'})
        @module.completion_requirements = {@tag.id => {:type => 'must_submit'}}
        @module.save!

        @quiz.assignment.grade_student(@student, :grade => "4", :grader => @teacher)
        expect(@module.evaluate_for(@student)).to be_unlocked
      end

      it "should fulfill assignment must_submit requirement on excused submission" do
        @assign = @course.assignments.create!(title: 'how many roads must a man walk down?', submission_types: 'online_text_entry')
        @tag = @module.add_item({id: @assign.id, type: 'assignment'})
        @module.completion_requirements = {@tag.id => {type: 'must_submit'}}
        @module.save!

        expect(@module.evaluate_for(@student)).to be_unlocked

        @assign.reload
        @assign.grade_student(@student, :grader => @teacher, :excuse => true)
        expect(@module.evaluate_for(@student)).to be_completed
      end

      it "should fulfill quiz must_submit requirement on excused submission" do
        @quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :scoring_policy => 'keep_highest')
        @quiz.workflow_state = 'available'
        @quiz.save!
        @tag = @module.add_item({:id => @quiz.id, :type => 'quiz'})
        @module.completion_requirements = {@tag.id => {:type => 'must_submit'}}
        @module.save!

        @quiz.assignment.grade_student(@student, :grader => @teacher, :excuse => true)
        expect(@module.evaluate_for(@student)).to be_completed
      end

      it "should fulfill quiz must_submit requirement on 0 score attempt" do
        @quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :scoring_policy => 'keep_highest')
        @quiz.workflow_state = 'available'
        @quiz.save!
        @q1 = @quiz.quiz_questions.create!(:question_data => {:name => 'question 1', :points_possible => 1,
            'question_type' => 'multiple_choice_question',
            'answers' => [{'answer_text' => '1', 'answer_weight' => '100'}, {'answer_text' => '2'}]})
        @quiz.generate_quiz_data(:persist => true)
        wrong_answer = @q1.question_data[:answers].detect{|a| a[:weight] != 100 }[:id]

        @tag = @module.add_item({:id => @quiz.id, :type => 'quiz'})
        @module.completion_requirements = {@tag.id => {:type => 'must_submit'}}
        @module.save!

        @sub = @quiz.generate_submission(@student)
        @sub.submission_data = {"question_#{@q1.data[:id]}" => wrong_answer}
        Quizzes::SubmissionGrader.new(@sub).grade_submission
        expect(@sub.score).to eq 0
        expect(@module.evaluate_for(@student)).to be_completed
      end
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

        @student_1.enrollments.each(&:destroy_permanently!)
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
        it "should properly require differentiated assignments" do
          expect(@module.evaluate_for(@student_1)).to be_unlocked
          @submission = @assign.submit_homework(@student_1, submission_type: 'online_text_entry', body: '42')
          @module.reload
          expect(@module.evaluate_for(@student_1)).to be_completed
          expect(@module.evaluate_for(@student_2)).to be_completed
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
      @course.enroll_student(@user).accept!

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
      expect(@module2.reload.evaluate_for(@user)).to be_completed

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
      expect(@progression.current_position).to eql(@tag2.position)
      expect(@assignment.reload.locked_for?(@user)).to be_falsey
      expect(@assignment2.reload.locked_for?(@user)).to be_falsey

      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 5}}
      @module.save
      @module2.reload
      expect(@module2.evaluate_for(@user)).to be_completed
      @module.reload.relock_progressions
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

      expect(@module2.evaluate_for(@user)).to be_completed
      @module.reload.relock_progressions
      expect(@module2.evaluate_for(@user)).to be_locked

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_started
      expect(@progression.current_position).to eql(@tag.position)

      @submissions[0].score = 10
      @submissions[0].save!

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
      expect(@progression.current_position).to eql(@tag2.position)

      expect(@module2.evaluate_for(@user)).to be_completed
    end

    it "should update quiz progression status on assignment manual grading" do
      course_module
      @module.require_sequential_progress = true
      @module.save!
      @quiz = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :scoring_policy => 'keep_highest')
      @quiz.workflow_state = 'available'
      @quiz.save!

      @tag = @module.add_item({:id => @quiz.id, :type => 'quiz'})
      @module.completion_requirements = {@tag.id => {:type => 'min_score', :min_score => 90}}
      @module.save!

      @teacher = User.create!(:name => "some teacher")
      @course.enroll_teacher(@teacher)
      @user = User.create!(:name => "some name")
      @course.enroll_student(@user).accept!

      @quiz.assignment.grade_student(@user, grade: 100, grader: @teacher)

      @progression = @module.evaluate_for(@user)
      expect(@progression).to be_completed
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
      @course.enroll_student(@user).accept!

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
    before :once do
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
    end

    it 'should not prevent a student from completing a module' do
      @other_assignment.grade_student(@student, grade: '95', grader: @teacher)
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
    before :once do
      course_module
      @student_1 = student_in_course(course: @course, active_all: true).user
      @student_2 = student_in_course(course: @course, active_all: true).user

      @student_1.enrollments.each(&:destroy_permanently!)
      @overriden_section = @course.course_sections.create!(name: "test section")
      student_in_section(@overriden_section, user: @student_1)

      @assignment = @course.assignments.create!(title: 'how many roads must a man walk down?', submission_types: 'online_text_entry')
      @assignment.only_visible_to_overrides = true
      @assignment.save!
      create_section_override_for_assignment(@assignment, {course_section: @overriden_section})

      @tag = @module.add_item({id: @assignment.id, type: 'assignment'})
      @module.reload
    end

    context "differentiated_assignments enabled" do
      it "should properly return differentiated assignments" do
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@assignment)).to be_truthy
        expect(@module.content_tags_visible_to(@student_1).map(&:content).include?(@assignment)).to be_truthy
        expect(@module.content_tags_visible_to(@student_2).map(&:content).include?(@assignment)).to be_falsey
      end

      it "should also have the right assignment_and_quiz_visibilities" do
        expect(@teacher.assignment_and_quiz_visibilities(@course)[:assignment_ids].include?(@assignment.id)).to be_truthy
        expect(@student_1.assignment_and_quiz_visibilities(@course)[:assignment_ids].include?(@assignment.id)).to be_truthy
        expect(@student_2.assignment_and_quiz_visibilities(@course)[:assignment_ids].include?(@assignment.id)).to be_falsey
      end

      it "should properly return differentiated assignments for teacher even without update rights" do
        @course.account.role_overrides.create!(role: teacher_role, enabled: false, permission: :manage_content)
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@assignment)).to be_truthy
      end

      it "should properly return unpublished assignments" do
        @assignment.workflow_state = "unpublished"
        @assignment.save!
        @module.reload
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@assignment)).to be_truthy
        expect(@module.content_tags_visible_to(@student_1).map(&:content).include?(@assignment)).to be_falsey
        expect(@module.content_tags_visible_to(@student_2).map(&:content).include?(@assignment)).to be_falsey
      end
      it "should not reload the tags if already loaded" do
        expect(ContentTag).to receive(:visible_to_students_in_course_with_da).never
        ActiveRecord::Associations::Preloader.new.preload(@module, content_tags: :content)
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
      it "should filter differentiated pages" do
        @page_assignment = wiki_page_assignment_model(course: @course, only_visible_to_overrides: true)
        create_section_override_for_assignment(@page_assignment, {course_section: @overriden_section})
        @module.add_item({id: @page.id, type: 'wiki_page'})
        expect(@module.content_tags_visible_to(@teacher).map(&:content).include?(@page)).to be_truthy
        expect(@module.content_tags_visible_to(@student_1).map(&:content).include?(@page)).to be_truthy
        expect(@module.content_tags_visible_to(@student_2).map(&:content).include?(@page)).to be_falsey
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
        @module.reload
        expect(@module.content_tags_visible_to(@observer).map(&:content).include?(@assignment)).to be_truthy
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
    it "should restore to unpublished state" do
      course_factory
      @module = @course.context_modules.create!
      @module.destroy
      @module.restore
      expect(@module.reload).to be_unpublished
    end
  end

  describe "#relock_warning?" do
    before :once do
      course_factory(active_all: true)
    end

    it "should be true when adding a prerequisite" do
      mod1 = @course.context_modules.create!(:name => "some module")
      mod2 = @course.context_modules.create!(:name => "some module2")

      mod2.prerequisites = "module_#{mod1.id}"
      mod2.save!

      expect(mod2.relock_warning?).to be_truthy

      mod2.prerequisites = ""
      mod2.save!

      expect(mod2.relock_warning?).to be_falsey
    end

    it "should be true when adding a completion requirement" do
      mod = @course.context_modules.create!(:name => "some module")

      quiz = @course.quizzes.create!(title: "some quiz")
      quiz.publish!
      tag = mod.add_item({id: quiz.id, type: 'quiz'})
      mod.completion_requirements = {tag.id => {type: 'must_submit'}}
      mod.save!

      expect(mod.relock_warning?).to be_truthy

      mod.completion_requirements = []
      mod.save!

      expect(mod.relock_warning?).to be_falsey
    end

    it "should be true when publishing a prerequisite" do
      mod1 = @course.context_modules.new(:name => "some module")
      mod1.workflow_state = "unpublished"
      mod1.save!

      mod2 = @course.context_modules.new(:name => "some module2")
      mod2.prerequisites = "module_#{mod1.id}"
      mod2.workflow_state = "unpublished"
      mod2.save!

      mod1.publish!
      expect(mod1.relock_warning?).to be_falsey # mod2 is not active

      mod2.publish!
      mod1.unpublish!; mod1.publish!
      expect(mod1.relock_warning?).to be_truthy # now mod2 is active

      mod2.prerequisites = ""
      mod2.save!
      mod1.unpublish!; mod1.publish!
      expect(mod1.relock_warning?).to be_falsey
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

  it "allows teachers with concluded enrollments to :read unpublished modules" do
    course_with_teacher.complete!
    m = @course.context_modules.create!
    m.workflow_state = 'unpublished'
    m.save!
    expect(m.grants_right?(@teacher, :read)).to eq true
    expect(m.grants_right?(@teacher, :read_as_admin)).to eq true
    expect(m.grants_right?(@teacher, :manage_content)).to eq false
  end

  it "should only load visibility and progression information once when calculating prerequisites" do
    course_factory(:active_all => true)
    student_in_course(:course => @course)
    m1 = @course.context_modules.create!(:name => "m1")
    m2 = @course.context_modules.create!(:name => "m2", :prerequisites => [{id: m1.id, type: 'context_module', name: m1.name}])

    [m1, m2].each do |m|
      assmt = @course.assignments.create!(:title => "assmt", :submission_types => "online_text_entry")
      assmt.submit_homework(@student, :body => "bloop")
      tag = m.add_item({:id => assmt.id, :type => 'assignment'})
      m.update_attribute(:completion_requirements, {tag.id => {:type => "must_submit"}})
    end

    expect(AssignmentStudentVisibility).to receive(:visible_assignment_ids_in_course_by_user).once.and_call_original
    expect(ContextModuleProgressions::Finder).to receive(:find_or_create_for_context_and_user).once.and_call_original

    m2.evaluate_for(@student)
  end
end
