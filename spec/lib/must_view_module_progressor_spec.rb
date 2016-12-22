#
# Copyright (C) 2016-2017 Instructure, Inc.
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

describe "MustViewModuleProgressor" do
  def create_item(item_type)
    case item_type
    when :page
      @course.wiki.wiki_pages.create!(title: 'some page')
    when :assignment
      @course.assignments.create!(title: 'some assignment')
    when :discussion
      @course.discussion_topics.create!(title: 'some discussion')
    when :attachment
      @course.attachments.create!(uploaded_data: stub_png_data('my-pic.png'))
    else
      raise "unrecognized item type: #{item_type}"
    end
  end

  def item_type_of(item)
    case item
    when WikiPage then 'page'
    when Assignment then 'assignment'
    when DiscussionTopic then 'discussion'
    when Attachment then 'attachment'
    else raise "unknown item type: #{item.class}"
    end
  end

  def add_module_item(mod, item, requirement_type = 'must_view')
    item_tag = mod.add_item(id: item.id, type: item_type_of(item))
    mod.completion_requirements = mod.completion_requirements + [{id: item_tag.id, type: requirement_type.to_s}]
    mod.save!
    item_tag
  end

  def module_with_item_return_all(item_type, requirement_type = 'must_view')
    mod = @course.context_modules.create!(name: 'some module')
    item = create_item(item_type)
    item_tag = add_module_item(mod, item, requirement_type)
    [mod, item, item_tag]
  end

  def module_with_item(item_type, requirement_type = 'must_view')
    module_with_item_return_all(item_type, requirement_type).first
  end

  def sequential_module_progression_fixture(assignment_requirement_type: 'must_view')
    mod = @course.context_modules.create!(name: 'some module')
    initial_page = @course.wiki.wiki_pages.create!(title: "initial page")
    initial_page_tag = mod.add_item(id: initial_page.id, type: 'page')
    assignment = @course.assignments.create!(title: "some assignment")
    assignment_tag = mod.add_item(id: assignment.id, type: 'assignment')
    final_page = @course.wiki.wiki_pages.create!(title: "some page")
    final_page_tag = mod.add_item(id: final_page.id, type: 'page')
    mod.completion_requirements = {
      initial_page_tag.id => {type: 'must_view'},
      assignment_tag.id => {type: assignment_requirement_type},
      final_page_tag.id => {type: 'must_view'},
    }
    mod.require_sequential_progress = true
    mod.save!
    {
      mod: mod,
      initial_page: {item: initial_page, tag: initial_page_tag},
      assignment: {item: assignment, tag: assignment_tag},
      final_page: {item: final_page, tag: final_page_tag},
    }
  end

  describe "#make_progress" do
    before(:once) do
      course_with_student(active_all: true)
    end

    # needed to get updated info as progress is made
    it "calls evaluate_for on modules" do
      @course.context_modules.create!(name: 'some module')
      ContextModule.any_instance.expects(:evaluate_for)
      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress
    end

    it "marks several must_view requirements in random access module as viewed" do
      mod, _, first_page_tag = module_with_item_return_all(:page)
      add_module_item(mod, create_item(:assignment), 'must_submit')
      second_page_tag = add_module_item(mod, create_item(:page))

      progression = mod.find_or_create_progression(@student)
      expect(progression.requirements_met).to be_empty

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress
      progression.reload

      actual = progression.requirements_met.sort_by { |req| req[:id] }
      expected = [
        {id: first_page_tag.id, type: 'must_view'},
        {id: second_page_tag.id, type: 'must_view'},
      ].sort_by { |ex| ex[:id] }
      expect(actual).to eq(expected)
    end

    it "follows module prerequisites" do
      mods = [
        module_with_item(:page),
        module_with_item(:page),
      ]

      mods[1].prerequisites = [{id: mods[0].id, name: mods[0].name, type: 'context_module'}]
      mods[1].save!

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      @course.context_modules.each do |mod|
        progression = mod.find_or_create_progression(@student)
        tag = mod.content_tags.first
        expect(progression.requirements_met).to eq([{id: tag.id, type: 'must_view'}])
      end
    end

    it "is blocked by prerequisites" do
      mods = (1..2).map do |i|
        @course.context_modules.create!(name: "module #{i}")
      end
      add_module_item(mods[0], create_item(:assignment), 'must_submit')
      add_module_item(mods[1], create_item(:page))

      mods[1].prerequisites = [{id: mods[0].id, name: mods[0].name, type: 'context_module'}]
      mods[1].save!

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mods[1].reload.find_or_create_progression(@student)
      expect(progression.requirements_met).to eq([])
    end

    it "is blocked by sequential progress" do
      sequence = sequential_module_progression_fixture(
        assignment_requirement_type: 'must_contribute',
      )
      mod = sequence[:mod]
      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met).to eq([
        {id: sequence[:initial_page][:tag].id, type: 'must_view'}
      ])
    end

    it "can follow sequential progress" do
      sequence = sequential_module_progression_fixture
      mod = sequence[:mod]

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met.size).to eq(3)
    end

    it "can follow sequential progress through already completed non-must-view items" do
      sequence = sequential_module_progression_fixture(
        assignment_requirement_type: 'must_contribute',
      )
      mod = sequence[:mod]
      mod.update_for(@student, :contributed, sequence[:assignment][:tag])

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met.size).to eq(3)
    end

    it "does not mark locked assignment as complete" do
      mod, assignment = module_with_item_return_all(:assignment)
      assignment.lock_at = Time.now.utc - 2.days
      assignment.save!
      @course.reload

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met).to eq([])
    end

    it "does not mark locked discussion as complete" do
      mod, discussion = module_with_item_return_all(:discussion)
      discussion.lock_at = Time.now.utc - 2.days
      discussion.save!
      @course.reload

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met).to eq([])
    end

    it "does not mark locked file as complete" do
      mod, att = module_with_item_return_all(:attachment)
      att.lock_at = Time.now.utc - 2.days
      att.save!
      @course.reload

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met).to eq([])
    end

    # testing assignments should cover other unpublished things too
    it "does not mark unpublished assignments as complete" do
      mod, assignment = module_with_item_return_all(:assignment)
      assignment.unpublish!
      @course.reload

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met).to eq([])
    end

    it "proceeds through unpublished assignments for sequential modules" do
      sequence = sequential_module_progression_fixture(
        assignment_requirement_type: 'must_contribute',
      )
      mod = sequence[:mod]

      sequence[:assignment][:item].unpublish!
      @course.reload

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mod.reload.find_or_create_progression(@student)
      reqs = progression.requirements_met.sort_by { |req| req[:id] }
      expected = [
        {id: sequence[:initial_page][:tag].id, type: 'must_view'},
        {id: sequence[:final_page][:tag].id, type: 'must_view'},
      ].sort_by { |ex| ex[:id] }
      expect(reqs).to eq expected
    end

    # items can be unpublished separately from their content
    it "proceeds through modules with unpublished content tags" do
      sequence = sequential_module_progression_fixture(
        assignment_requirement_type: 'must_contribute',
      )
      mod = sequence[:mod]

      sequence[:assignment][:tag].unpublish!
      @course.reload

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met.size).to eq 2
    end

    it "proceeds through modules with unpublished assignments" do
      first_mod, assignment = module_with_item_return_all(:assignment, 'must_contribute')
      first_page = create_item(:page)
      first_page_tag = add_module_item(first_mod, first_page)

      second_mod, _, second_page_tag = module_with_item_return_all(:page)
      second_mod.prerequisites = [{id: first_mod.id, name: first_mod.name, type: 'context_module'}]
      second_mod.save!

      assignment.unpublish!
      @course.reload

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      first_progression = first_mod.find_or_create_progression(@student)
      expect(first_progression.requirements_met).to eq([{id: first_page_tag.id, type: 'must_view'}])

      second_progression = second_mod.find_or_create_progression(@student)
      expect(second_progression.requirements_met).to eq([{id: second_page_tag.id, type: 'must_view'}])
    end

    it "triggers completion events" do
      ContextModuleProgression.any_instance.expects(:trigger_completion_events)
      module_with_item(:page)
      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress
    end

    it "ignores assignments that are hidden by overrides" do
      first_student = @student
      course_with_student(course: @course, active_all: true)
      second_student = @student

      sequence = sequential_module_progression_fixture(
        assignment_requirement_type: 'must_contribute',
      )
      mod = sequence[:mod]
      assignment = sequence[:assignment][:item]
      create_adhoc_override_for_assignment(assignment, second_student)
      assignment.reload
      assignment.only_visible_to_overrides = true
      assignment.save!
      expect(assignment.visible_to_user?(first_student)).to be_falsy
      expect(assignment.visible_to_user?(second_student)).to be_truthy

      progressor = MustViewModuleProgressor.new(first_student, @course)
      progressor.make_progress
      progression = mod.reload.find_or_create_progression(first_student)
      expect(progression.requirements_met.size).to eq 2

      progressor = MustViewModuleProgressor.new(second_student, @course)
      progressor.make_progress
      progression = mod.reload.find_or_create_progression(second_student)
      expect(progression.requirements_met.size).to eq 1
    end

    it "does not progress items in unpublished modules" do
      mod = module_with_item(:page)
      mod.unpublish!
      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress
      progression = mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met.size).to eq 0
    end

    it "does not progress items in locked modules" do
      first_mod = module_with_item(:page)
      second_mod = module_with_item(:page)
      second_mod.prerequisites = [{id: first_mod.id, name: first_mod.name, type: 'context_module'}]
      second_mod.save!

      first_mod.unlock_at = Time.now.utc + 2.days
      first_mod.save!

      progressor = MustViewModuleProgressor.new(@student, @course)
      progressor.make_progress

      progression = first_mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met).to eq []

      progression = second_mod.reload.find_or_create_progression(@student)
      expect(progression.requirements_met).to eq []
    end
  end
end
