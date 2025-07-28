# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe CourseProgress do
  let(:progress_error) { { error: { message: "no progress available because this course is not module based (has modules and module completion requirements) or the user is not enrolled as a student in this course" } } }

  before do
    allow_any_instance_of(CourseProgress).to receive(:course_context_modules_item_redirect_url) do |_, opts = {}|
      "course_context_modules_item_redirect_url(:course_id => #{opts[:course_id]}, :id => #{opts[:id]}, :host => HostUrl.context_host(Course.find(#{opts[:course_id]}))"
    end
  end

  before :once do
    course_with_teacher(active_all: true)
  end

  def submit_homework(assignment, user = nil)
    user ||= @user
    assignment.submit_homework(user, submission_type: "online_text_entry", body: "42")
  end

  it "returns nil for non module_based courses" do
    user = student_in_course(active_all: true)
    progress = CourseProgress.new(@course, user).to_json
    expect(progress).to eq progress_error
  end

  it "returns nil for non student users" do
    user = user_model
    allow(@course).to receive(:module_based?).and_return(true)
    progress = CourseProgress.new(@course, user).to_json
    expect(progress).to eq progress_error
  end

  context "module based and for student" do
    before :once do
      @module = @course.context_modules.create!(name: "some module", require_sequential_progress: true, position: 1)
      @module2 = @course.context_modules.create!(name: "another module", require_sequential_progress: true, position: 2)
      @module3 = @course.context_modules.create!(name: "another module again", require_sequential_progress: true, position: 3)

      @assignment = @course.assignments.create!(title: "some assignment")
      @assignment2 = @course.assignments.create!(title: "some assignment2")
      @assignment3 = @course.assignments.create!(title: "some assignment3")
      @assignment4 = @course.assignments.create!(title: "some assignment4")
      @assignment5 = @course.assignments.create!(title: "some assignment5")

      @tag = @module.add_item({ id: @assignment.id, type: "assignment" })
      @tag2 = @module.add_item({ id: @assignment2.id, type: "assignment" })

      @tag3 = @module2.add_item({ id: @assignment3.id, type: "assignment" })
      @tag4 = @module2.add_item({ id: @assignment4.id, type: "assignment" })

      @tag5 = @module3.add_item({ id: @assignment5.id, type: "assignment" })

      @module.completion_requirements = { @tag.id => { type: "must_submit" },
                                          @tag2.id => { type: "must_submit" } }
      @module2.completion_requirements = { @tag3.id => { type: "must_submit" },
                                           @tag4.id => { type: "must_submit" } }
      @module3.completion_requirements = { @tag5.id => { type: "must_submit" } }

      [@module, @module2, @module3].each do |m|
        m.require_sequential_progress = true
        m.publish
        m.save!
      end

      student_in_course(active_all: true)
    end

    it "returns correct progress for newly enrolled student" do
      progress = CourseProgress.new(@course, @user).to_json
      expect(progress).to eq({
                               requirement_count: 5,
                               requirement_completed_count: 0,
                               next_requirement_url: "course_context_modules_item_redirect_url(:course_id => #{@course.id}, :id => #{@tag.id}, :host => HostUrl.context_host(Course.find(#{@course.id}))",
                               completed_at: nil
                             })
    end

    it "only runs item visibility methods once" do
      expect(AssignmentVisibility::AssignmentVisibilityService).to receive(:visible_assignment_ids_in_course_by_user).once.and_call_original
      progress = CourseProgress.new(@course, @user).to_json
      expect(progress[:requirement_count]).to eq 5
    end

    it "returns correct progress for student who has completed some requirements" do
      # turn in first two assignments (module 1)
      submit_homework(@assignment)
      submit_homework(@assignment2)
      progress = CourseProgress.new(@course, @user).to_json
      expect(progress).to eq({
                               requirement_count: 5,
                               requirement_completed_count: 2,
                               next_requirement_url: "course_context_modules_item_redirect_url(:course_id => #{@course.id}, :id => #{@tag3.id}, :host => HostUrl.context_host(Course.find(#{@course.id}))",
                               completed_at: nil
                             })
    end

    it "returns correct progress for student in read-only mode" do
      # turn in first two assignments (module 1)
      submit_homework(@assignment)
      submit_homework(@assignment2)

      [@module, @module2, @module3].each do |m|
        m.evaluate_for(@user)
        expect_any_instantiation_of(m).not_to receive(:evaluate_for) # shouldn't re-evaluate
      end

      progress = CourseProgress.new(@course, @user, read_only: true).to_json
      expect(progress).to eq({
                               requirement_count: 5,
                               requirement_completed_count: 2,
                               next_requirement_url: "course_context_modules_item_redirect_url(:course_id => #{@course.id}, :id => #{@tag3.id}, :host => HostUrl.context_host(Course.find(#{@course.id}))",
                               completed_at: nil
                             })
    end

    it "returns correct progress for student who has completed all requirements" do
      # turn in all assignments
      submit_homework(@assignment)
      submit_homework(@assignment2)
      submit_homework(@assignment3)
      submit_homework(@assignment4)
      submit_homework(@assignment5)

      progress = CourseProgress.new(@course, @user).to_json
      expect(progress).to eq({
                               requirement_count: 5,
                               requirement_completed_count: 5,
                               next_requirement_url: nil,
                               completed_at: @module3.context_module_progressions.first.completed_at.iso8601
                             })
    end

    it "treats a nil requirements_met as an incomplete requirement" do
      # create a progression with requirements_met uninitialized (nil)
      ContextModuleProgression.create!(user: @user, context_module: @module)
      progress = CourseProgress.new(@course, @user).to_json
      expect(progress).to eq({
                               requirement_count: 5,
                               requirement_completed_count: 0,
                               next_requirement_url: "course_context_modules_item_redirect_url(:course_id => #{@course.id}, :id => #{@tag.id}, :host => HostUrl.context_host(Course.find(#{@course.id}))",
                               completed_at: nil
                             })
    end

    describe("when the student cannot be evalualated for the course") do
      it "returns partial progress for student" do
        allow_any_instance_of(ContextModule).to receive(:evaluate_for).and_return(nil)
        progress = CourseProgress.new(@course, @user).to_json

        expect(progress).to eq({
                                 requirement_count: 5,
                                 requirement_completed_count: 0,
                                 next_requirement_url: nil,
                                 completed_at: nil
                               })
      end
    end

    describe "#current_module" do
      it "returns the first incomplete module" do
        # turn in first two assignments (module 1)
        submit_homework(@assignment)
        submit_homework(@assignment2)

        progress = CourseProgress.new(@course, @user)
        expect(progress.current_module).to eq @module2
      end
    end

    describe "#incomplete_modules" do
      it "returns all modules that are not complete" do
        # turn in first two assignments (module 1)
        submit_homework(@assignment)
        submit_homework(@assignment2)

        progress = CourseProgress.new(@course, @user)
        expect(progress.incomplete_modules).to eq [@module2, @module3]
      end
    end

    describe "#visible_tags_for_module" do
      it "returns only visible tags" do
        @tag.unpublish
        progress = CourseProgress.new(@course, @user)
        expect(progress.visible_tags_for_module(@module)).to eq [@tag2]
      end

      it "returns empty array if there are no visible tags" do
        @tag.unpublish
        @tag2.unpublish
        progress = CourseProgress.new(@course, @user)
        expect(progress.visible_tags_for_module(@module)).to eq []
      end
    end

    describe "#progress_percent" do
      it "returns 0 if there are no requirements" do
        [@module, @module2, @module3].each do |mod|
          mod.update(completion_requirements: {})
        end

        progress = CourseProgress.new(@course, @user)

        expect(progress.requirement_count).to eq 0
        expect(progress.normalized_requirement_count).to eq 0
        expect(progress.progress_percent).to eq 0
      end

      it "returns 0 if there are no visible requirements" do
        [@tag, @tag2, @tag3, @tag4, @tag5].each(&:unpublish)

        progress = CourseProgress.new(@course, @user)

        expect(progress.requirement_count).to eq 0
        expect(progress.normalized_requirement_count).to eq 0
        expect(progress.progress_percent).to eq 0
      end

      it "returns 0 if there are no requirements completed" do
        progress = CourseProgress.new(@course, @user)

        expect(progress.requirement_count).to eq 5
        expect(progress.normalized_requirement_count).to eq 5
        expect(progress.progress_percent).to eq 0
      end

      it "returns correct percentage in Float based on requirement completion" do
        # turn in first two assignments (module 1)
        submit_homework(@assignment)
        submit_homework(@assignment2)

        progress = CourseProgress.new(@course, @user)

        expect(progress.progress_percent).to eq 40.0
      end
    end

    describe "#incomplete_items_for_modules" do
      it "returns the incomplete items for each module" do
        submit_homework(@assignment)
        submit_homework(@assignment5)

        progress = CourseProgress.new(@course, @user)
        expect(progress.incomplete_items_for_modules).to eq [
          {
            module: @module,
            items: [@tag2]
          },
          {
            module: @module2,
            items: [@tag3, @tag4]
          }
        ]
      end

      it "does not return items that are not visible to the user" do
        @tag.unpublish
        @tag2.unpublish
        @tag3.unpublish
        @tag4.unpublish

        progress = CourseProgress.new(@course, @user)
        expect(progress.incomplete_items_for_modules).to eq [
          {
            module: @module3,
            items: [@tag5]
          }
        ]
      end

      it "does not return items that are not required" do
        @module.update(completion_requirements: {
                         @tag2.id => { type: "must_submit" }
                       })

        progress = CourseProgress.new(@course, @user)
        expect(progress.incomplete_items_for_modules).to include(
          {
            module: @module,
            items: [@tag2]
          }
        )
      end
    end

    describe "#can_evalute_progression?" do
      it "returns true if the user is a student in a module based course" do
        user = student_in_course(course: @course, active_all: true).user
        allow(@course).to receive(:module_based?).and_return(true)
        progress = CourseProgress.new(@course, user)
        expect(progress.can_evaluate_progression?).to be_truthy
      end

      it "returns false for non module_based courses" do
        user = student_in_course(active_all: true).user
        allow(@course).to receive(:module_based?).and_return(false)
        progress = CourseProgress.new(@course, user)
        expect(progress.can_evaluate_progression?).to be_falsy
      end

      it "returns false for non student users" do
        user = user_model
        allow(@course).to receive(:module_based?).and_return(true)
        progress = CourseProgress.new(@course, user)
        expect(progress.can_evaluate_progression?).to be_falsy
      end
    end

    it "does not count obsolete requirements" do
      # turn in first two assignments
      submit_homework(@assignment)
      submit_homework(@assignment2)

      # remove assignment 2 from the list of requirements
      @module.completion_requirements = [{ id: @tag.id, type: "must_submit" }]
      @module.save

      progress = CourseProgress.new(@course, @user).to_json

      # assert that assignment 2 is no longer a requirement (5 -> 4)
      expect(progress[:requirement_count]).to eq 4

      # assert that assignment 2 doesn't count toward the total (2 -> 1)
      expect(progress[:requirement_completed_count]).to eq 1
    end

    it "returns progress even after enrollment end date has passed" do
      e = Enrollment.last
      e.update_attribute(:end_at, 2.days.ago)
      e.update_attribute(:start_at, 5.days.ago)

      progress = CourseProgress.new(@course, @user).to_json

      expect(progress[:requirement_count]).to eq 5
      expect(progress[:error]).to be_nil
    end

    it "does not query destroyed ContentTags" do
      @tag.destroy
      progress = CourseProgress.new(@course, @user)
      expect(progress.current_content_tag.id).not_to eq @tag.id
    end

    it "does not query unpublished ContentTags" do
      @tag.unpublish
      progress = CourseProgress.new(@course, @user)
      expect(progress.current_content_tag.id).not_to eq @tag.id
    end

    it "accounts for module items that have moved between modules" do
      # complete the requirement while it's in module 1
      submit_homework(@assignment)

      # move the requirement to module 2
      @tag.context_module = @module2
      @tag.save!
      @module2.completion_requirements = { @tag.id => { type: "must_submit" } }
      @module2.save

      # check progress
      progress = CourseProgress.new(@course, @user)
      expect(progress.requirement_completed_count).to eq 0

      # complete the requirement again
      @module2.update_for(@user, :submitted, @tag)

      # check progress again
      progress = CourseProgress.new(@course, @user)
      expect(progress.requirement_completed_count).to eq 1
    end

    describe "dispatch_live_event" do
      it "dispatches course_progress if partially complete" do
        # turn in first two assignments (module 1)
        submit_homework(@assignment)
        submit_homework(@assignment2)

        progression = @module.evaluate_for(@user)
        expect(Canvas::LiveEvents).to receive(:course_progress)
        expect(Canvas::LiveEvents).not_to receive(:course_completed)
        CourseProgress.dispatch_live_event(progression)
      end

      it "dispatches course_completed if entirely complete" do
        # turn in all assignments
        submit_homework(@assignment)
        submit_homework(@assignment2)
        submit_homework(@assignment3)
        submit_homework(@assignment4)
        submit_homework(@assignment5)

        progression = @module3.evaluate_for(@user)
        expect(Canvas::LiveEvents).not_to receive(:course_progress)
        expect(Canvas::LiveEvents).to receive(:course_completed)
        CourseProgress.dispatch_live_event(progression)
      end
    end

    context "when the user is on a different shard than the course" do
      specs_require_sharding

      it "can return correct progress" do
        @shard1.activate { @shard_user = User.create!(name: "outofshard") }
        @course.enroll_student(@shard_user).accept!

        submit_homework(@assignment, @shard_user)
        submit_homework(@assignment2, @shard_user)
        progress = CourseProgress.new(@course, @shard_user)
        expect(progress.requirement_completed_count).to eq 2
      end
    end
  end

  context "module that requires only one item completed" do
    it "returns the correct course progress when completing one of the requirements" do
      @module1 = @course.context_modules.create!(name: "module 01", requirement_count: nil)
      @module2 = @course.context_modules.create!(name: "module 02", requirement_count: 1)

      @assignment1 = @course.assignments.create!(title: "some assignment1")
      @assignment2 = @course.assignments.create!(title: "some assignment2")
      @assignment3 = @course.assignments.create!(title: "some assignment3")
      @assignment4 = @course.assignments.create!(title: "some assignment4")
      @assignment5 = @course.assignments.create!(title: "some assignment5")

      @tag1 = @module1.add_item({ id: @assignment1.id, type: "assignment" })
      @tag2 = @module1.add_item({ id: @assignment2.id, type: "assignment" })
      @tag3 = @module1.add_item({ id: @assignment3.id, type: "assignment" })

      @tag4 = @module2.add_item({ id: @assignment4.id, type: "assignment" })
      @tag5 = @module2.add_item({ id: @assignment5.id, type: "assignment" })

      @module1.completion_requirements = {
        @tag1.id => { type: "must_submit" },
        @tag2.id => { type: "must_submit" },
        @tag3.id => { type: "must_submit" }
      }
      @module2.completion_requirements = {
        @tag4.id => { type: "must_submit" },
        @tag5.id => { type: "must_submit" }
      }

      [@module1, @module2].each do |m|
        m.publish
        m.save!
      end

      student_in_course(active_all: true)

      submit_homework(@assignment1)
      submit_homework(@assignment2)
      submit_homework(@assignment3)
      # skipping assignment 4 since we only need to complete 1 assignment in module 2
      submit_homework(@assignment5)

      progress = CourseProgress.new(@course, @user).to_json
      expect(progress).to eq({
                               requirement_count: 5,
                               requirement_completed_count: 4,
                               next_requirement_url: nil,
                               completed_at: @module2.context_module_progressions.first.completed_at.iso8601
                             })
    end

    it "still counts as complete if the module has no requirements to speak of" do
      @module1 = @course.context_modules.create!(name: "module 01", requirement_count: 1)
      @module2 = @course.context_modules.create!(name: "module 02", requirement_count: nil)

      @assignment1 = @course.assignments.create!(title: "some assignment1")
      @tag1 = @module2.add_item({ id: @assignment1.id, type: "assignment" })
      @module2.completion_requirements = {
        @tag1.id => { type: "must_submit" },
      }

      [@module1, @module2].each do |m|
        m.publish
        m.save!
      end

      student_in_course(active_all: true)

      submit_homework(@assignment1)

      progress = CourseProgress.new(@course, @user).to_json
      expect(progress).to eq({
                               requirement_count: 1,
                               requirement_completed_count: 1,
                               next_requirement_url: nil,
                               completed_at: @user.context_module_progressions.maximum(:completed_at).iso8601
                             })
    end

    describe("requirement counting with modules requiring one item to complete") do
      before(:once) do
        @module1 = @course.context_modules.create!(name: "module 01", requirement_count: nil)
        @module2 = @course.context_modules.create!(name: "module 02", requirement_count: 1)

        @assignment1 = @course.assignments.create!(title: "some assignment1")
        @assignment2 = @course.assignments.create!(title: "some assignment2")
        @assignment3 = @course.assignments.create!(title: "some assignment3")
        @assignment4 = @course.assignments.create!(title: "some assignment4")
        @assignment5 = @course.assignments.create!(title: "some assignment5")

        @tag1 = @module1.add_item({ id: @assignment1.id, type: "assignment" })
        @tag2 = @module1.add_item({ id: @assignment2.id, type: "assignment" })
        @tag3 = @module1.add_item({ id: @assignment3.id, type: "assignment" })

        @tag4 = @module2.add_item({ id: @assignment4.id, type: "assignment" })
        @tag5 = @module2.add_item({ id: @assignment5.id, type: "assignment" })

        @module1.completion_requirements = {
          @tag1.id => { type: "must_submit" },
          @tag2.id => { type: "must_submit" },
          @tag3.id => { type: "must_submit" }
        }
        @module2.completion_requirements = {
          @tag4.id => { type: "must_submit" },
          @tag5.id => { type: "must_submit" }
        }

        [@module1, @module2].each do |m|
          m.publish
          m.save!
        end

        student_in_course(active_all: true)
      end

      it "returns requirement count with respect to a module requiring only one item to complete" do
        progress = CourseProgress.new(@course, @user)
        expect(progress.normalized_requirement_count).to eq 3 + 1
      end

      it "does not increase completed requirements if no item was completed in the module" do
        submit_homework(@assignment1)
        submit_homework(@assignment2)
        submit_homework(@assignment3)

        progress = CourseProgress.new(@course, @user)
        expect(progress.normalized_requirement_completed_count).to eq 3 + 0
      end

      it "increases completed requirements by one if one item was completed in the module" do
        submit_homework(@assignment1)
        submit_homework(@assignment2)
        submit_homework(@assignment3)
        submit_homework(@assignment4)

        progress = CourseProgress.new(@course, @user)
        expect(progress.normalized_requirement_completed_count).to eq 3 + 1
      end

      it "increases completed requirements by one even if all items were completed in the module" do
        submit_homework(@assignment1)
        submit_homework(@assignment2)
        submit_homework(@assignment3)
        submit_homework(@assignment4)
        submit_homework(@assignment5)

        progress = CourseProgress.new(@course, @user)
        expect(progress.normalized_requirement_completed_count).to eq 3 + 1
      end
    end

    it "is not complete if not each module complete" do
      @module1 = @course.context_modules.create!(name: "module 01", requirement_count: 1)
      @module2 = @course.context_modules.create!(name: "module 02", requirement_count: 1)
      @module3 = @course.context_modules.create!(name: "module 03", requirement_count: 1)

      @assignment1 = @course.assignments.create!(title: "some assignment1")
      @assignment2 = @course.assignments.create!(title: "some assignment2")
      @assignment3 = @course.assignments.create!(title: "some assignment3")
      @assignment4 = @course.assignments.create!(title: "some assignment4")
      @assignment5 = @course.assignments.create!(title: "some assignment5")

      @tag1 = @module1.add_item({ id: @assignment1.id, type: "assignment" })
      @tag2 = @module1.add_item({ id: @assignment2.id, type: "assignment" })
      @tag3 = @module1.add_item({ id: @assignment3.id, type: "assignment" })
      @tag4 = @module2.add_item({ id: @assignment4.id, type: "assignment" })
      @tag5 = @module3.add_item({ id: @assignment5.id, type: "assignment" })

      @module1.completion_requirements = {
        @tag1.id => { type: "must_submit" },
        @tag2.id => { type: "must_submit" },
        @tag3.id => { type: "must_submit" }
      }
      @module2.completion_requirements = {
        @tag4.id => { type: "must_submit" }
      }
      @module3.completion_requirements = {
        @tag5.id => { type: "must_submit" }
      }

      [@module1, @module2, @module3].each do |m|
        m.publish
        m.save!
      end

      student_in_course(active_all: true)

      submit_homework(@assignment1)
      submit_homework(@assignment2)
      submit_homework(@assignment3)
      # skipping assignments 4 & 5 should leave only module 1 complete

      progress = CourseProgress.new(@course, @user).to_json
      expect(progress).to eq({
                               requirement_count: 5,
                               requirement_completed_count: 3,
                               next_requirement_url: nil,
                               completed_at: nil
                             })
    end
  end
end
