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

describe ContextModuleProgression do
  before do
    @course = course_factory(active_all: true)
    @module = @course.context_modules.create!(name: "some module")

    @user = User.create!(name: "some name")
    @course.enroll_student(@user).accept!
  end

  it "populates root_account_id" do
    progression = @module.evaluate_for(@user)
    expect(progression.root_account).to eq @course.root_account
  end

  def setup_modules
    @assignment = @course.assignments.create!(title: "some assignment")
    @tag = @module.add_item({ id: @assignment.id, type: "assignment" })
    @module.completion_requirements = { @tag.id => { type: "must_view" } }
    @module.workflow_state = "unpublished"
    @module.save!

    @module2 = @course.context_modules.create!(name: "another module")
    @module2.publish
    @module2.prerequisites = "module_#{@module.id}"
    @module2.save!

    @module3 = @course.context_modules.create!(name: "another module again")
    @module3.publish
    @module3.save!
  end

  context "prerequisites_satisfied?" do
    before do
      setup_modules
    end

    it "ignores already-calculated context_module_prerequisites correctly" do
      mp = @user.context_module_progressions.create!(context_module: @module2)
      mp.workflow_state = "locked"
      mp.save!
      mp2 = @user.context_module_progressions.create!(context_module: @module)
      mp2.workflow_state = "locked"
      mp2.save!

      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module2)).to be true
    end

    it "is satisfied if no prereqs" do
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module3)).to be true
    end

    it "is satisfied if prereq is unpublished" do
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module2)).to be true
    end

    it "is satisfied if prereq's prereq is unpublished" do
      @module3.prerequisites = "module_#{@module2.id}"
      @module3.save!
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module3)).to be true
    end

    it "is satisfied if dependent on both a published and unpublished module" do
      @module3.prerequisites = "module_#{@module.id}"
      @module3.prerequisites = [{ type: "context_module", id: @module.id, name: @module.name }, { type: "context_module", id: @module2.id, name: @module2.name }]
      @module3.save!
      @module3.reload
      expect(@module3.prerequisites.count).to eq 2

      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module3)).to be true
    end

    it "skips incorrect prereq hashes" do
      @module3.prerequisites = [{ type: "context_module", id: @module.id },
                                { type: "not_context_module", id: @module2.id, name: @module2.name }]
      @module3.save!

      expect(@module3.prerequisites.count).to eq 0
    end

    it "updates when publishing or unpublishing" do
      @module.publish
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module2)).to be false
      @module.unpublish
      @module2.reload
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module2)).to be true
    end
  end

  describe "#evaluate" do
    let(:module_progression) do
      p = @module.context_module_progressions.create!(
        context_module: @module,
        user: @user,
        current: true,
        evaluated_at: 5.minutes.ago
      )
      p.workflow_state = "bogus"
      p
    end

    context "does not evaluate" do
      before { module_progression.evaluated_at = Time.zone.now }

      it "when current" do
        module_progression.evaluate

        expect(module_progression.workflow_state).to eq "bogus"
      end

      it "when current and the module has not yet unlocked" do
        @module.unlock_at = 10.minutes.from_now
        module_progression.evaluate

        expect(module_progression.workflow_state).to eq "bogus"
      end
    end

    context "does evaluate" do
      it "when not current" do
        module_progression.current = false
        module_progression.evaluate

        expect(module_progression.workflow_state).not_to eq "bogus"
      end

      it "when current, but the evaluated_at stamp is missing" do
        module_progression.evaluated_at = nil
        module_progression.evaluate

        expect(module_progression.workflow_state).not_to eq "bogus"
      end

      it "when current, but the module has since unlocked" do
        @module.unlock_at = 1.minute.ago
        module_progression.evaluate

        expect(module_progression.workflow_state).not_to eq "bogus"
      end

      it "when current, but the module has been updated" do
        module_progression.evaluated_at = 1.minute.ago
        module_progression.evaluate

        expect(module_progression.workflow_state).not_to eq "bogus"
      end
    end

    context "when post policies enabled" do
      let(:assignment) { @course.assignments.create! }
      let(:tag) { @module.add_item({ id: assignment.id, type: "assignment" }) }

      it "doesn't mark students that haven't submitted as in-progress" do
        other_student = student_in_course(course: @course, active_all: true).user
        progression = @module.evaluate_for(other_student)
        # yes technically the requirement is "incomplete" if they haven't done anything
        # and the jerk who named the column should feel bad
        # but we actually use it for marking requirements that they've done something for
        # and either need to wait for grading or improve their score to continue (hence the "i" icon)
        expect(progression.incomplete_requirements).to be_empty
      end

      context "evaluate min_score requirement type" do
        let(:min_score) { 90 }

        before do
          @module.update!(completion_requirements: { tag.id => { type: "min_score", min_score: } })
          @submission = assignment.submit_homework(@user, body: "my homework")
        end

        context "when the score is close enough" do
          let(:min_score) { 1 }
          let(:score) { 0.9999999999999999 } # eg 0.3 + 0.3 + 0.3 + 0.1

          it "evaluates requirement as complete" do
            @submission.update!(score:, posted_at: 1.second.ago)
            progression = @module.context_module_progressions.find_by(user: @user)
            requirement = { id: tag.id, type: "min_score", min_score: }
            expect(progression.requirements_met).to include requirement
          end

          it "works if score is nil" do
            @submission.update!(score: nil, posted_at: 1.second.ago)
            progression = @module.context_module_progressions.find_by(user: @user)
            requirement = { id: tag.id, type: "min_score", min_score: }
            expect(progression.requirements_met).not_to include requirement
          end
        end

        it "does not evaluate requirements when grade has not posted" do
          @submission.update!(score: 100, posted_at: nil)
          progression = @module.context_module_progressions.find_by(user: @user)
          requirement = { id: tag.id, type: "min_score", min_score: 90.0, score: nil }
          expect(progression.incomplete_requirements).to include requirement
        end

        it "evaluates requirements when grade has posted" do
          @submission.update!(score: 100, posted_at: 1.second.ago)
          progression = @module.context_module_progressions.find_by(user: @user)
          requirement = { id: tag.id, type: "min_score", min_score: 90.0 }
          expect(progression.requirements_met).to include requirement
        end
      end

      context "evaluate min_percentage requirement type" do
        let(:min_percentage) { 75 }

        before do
          assignment.update!(points_possible: 200)
          @module.update!(completion_requirements: { tag.id => { type: "min_percentage", min_percentage: } })
          @submission = assignment.submit_homework(@user, body: "my homework")
        end

        it "does not evaluate requirements when grade has not posted" do
          @submission.update!(score: 100, posted_at: nil)
          progression = @module.context_module_progressions.find_by(user: @user)
          requirement = { id: tag.id, type: "min_percentage", min_percentage: 75.0, score: nil }
          expect(progression.incomplete_requirements).to include requirement
        end

        it "evaluates requirements when grade has posted" do
          @submission.update!(score: 160, posted_at: 1.second.ago)
          progression = @module.context_module_progressions.find_by(user: @user)
          requirement = { id: tag.id, type: "min_percentage", min_percentage: 75.0 }
          expect(progression.requirements_met).to include requirement
        end

        it "assignment points_possible not present" do
          assignment.update!(points_possible: nil)
          @submission.update!(score: 160, posted_at: 1.second.ago)
          progression = @module.context_module_progressions.find_by(user: @user)
          requirement = { id: tag.id, type: "min_percentage", min_percentage: 75.0, score: 160 }
          expect(progression.incomplete_requirements).to include requirement
        end
      end
    end
  end

  context "optimistic locking" do
    def stale_progression
      progression = @user.context_module_progressions.create!(context_module: @module)
      ContextModuleProgression.find(progression.id).update_attribute(:updated_at, 10.seconds.ago)
      progression
    end

    it "raises a stale object error during save" do
      progression = stale_progression
      expect { progression.update_attribute(:updated_at, 10.seconds.from_now) }.to raise_error(ActiveRecord::StaleObjectError)
      expect { progression.reload.update_attribute(:updated_at, 10.seconds.from_now) }.to_not raise_error
    end

    it "raises a stale object error during evaluate" do
      progression = stale_progression
      expect { progression.evaluate }.to raise_error(ActiveRecord::StaleObjectError)
      expect { progression.reload.evaluate }.to_not raise_error
    end

    it "does not raise a stale object error during evaluate!" do
      progression = stale_progression
      expect { progression.evaluate! }.to_not raise_error
    end

    it "does not raise a stale object error during catastrophic evaluate!" do
      progression = stale_progression
      allow(progression).to receive(:save).at_least(:once).and_raise(ActiveRecord::StaleObjectError.new(progression, "Save"))

      new_progression = nil
      expect { new_progression = progression.evaluate! }.to_not raise_error
      expect(new_progression.workflow_state).to eq "locked"
    end
  end

  it "does not invalidate progressions if a prerequisite changes, until manually relocked" do
    @module.unpublish!
    setup_modules
    @module3.prerequisites = "module_#{@module2.id}"
    @module3.save!
    progression2 = @module2.evaluate_for(@user)
    progression3 = @module3.evaluate_for(@user)

    @module.reload
    @module.publish!
    progression2.reload
    progression3.reload
    expect(progression2).to be_completed
    expect(progression3).to be_completed

    @module.relock_progressions

    progression2.reload
    progression3.reload
    expect(progression2).to be_locked
    expect(progression3).to be_locked
  end

  it "relock_progressions changes state from completed to unlock when wiki page requirement added" do
    context_module = @course.context_modules.create!(name: "Module 1")
    context_module.publish
    context_module.save!

    students_array = (1..6).map do |i|
      student = User.create!(name: "Student #{i}")
      @course.enroll_student(student).accept!
      student
    end
    students_array.each do |student|
      progression = context_module.evaluate_for(student)
      expect(progression.workflow_state).to eq "completed"
    end

    wiki_page = @course.wiki_pages.create!(title: "mark_as_done page", body: "")
    wiki_page.workflow_state = "active"
    wiki_page.save!

    assignment = @course.assignments.create!(
      title: "mark_as_done assignment",
      points_possible: 10,
      submission_types: "online_text_entry"
    )
    assignment.workflow_state = "active"
    assignment.save!

    @tag = context_module.add_item(id: wiki_page.id, type: "wiki_page")
    context_module.completion_requirements = {
      @tag.id => { type: "must_view" },
    }
    context_module.save!

    context_module.relock_progressions
    context_module.context_module_progressions.each do |progression|
      expect(progression.workflow_state).to eq "unlocked"
    end
  end

  describe "#uncomplete_requirement" do
    it "uncompletes the requirement" do
      setup_modules
      @module.publish!
      progression = @tag.context_module_action(@user, :read)
      progression.uncomplete_requirement(@tag.id)
      expect(progression.requirements_met.length).to be(0)
    end

    it "does not change anything when given an ID that does not exist" do
      setup_modules
      @module.publish!
      progression = @tag.context_module_action(@user, :read)
      progression.uncomplete_requirement(-1)
      expect(progression.requirements_met.length).to be(1)
    end
  end

  it "updates progressions when adding a must_contribute requirement on a topic" do
    @assignment = @course.assignments.create!
    @tag1 = @module.add_item({ id: @assignment.id, type: "assignment" })
    @topic = @course.discussion_topics.create!
    @topic.discussion_entries.create!(user: @user)
    @module.completion_requirements = { @tag1.id => { type: "must_view" } }

    progression = @module.evaluate_for(@user)
    expect(progression).to be_unlocked

    @tag2 = @module.add_item({ id: @topic.id, type: "discussion_topic" })
    @module.update_attribute(:completion_requirements, { @tag1.id => { type: "must_view" }, @tag2.id => { type: "must_contribute" } })

    progression.reload
    expect(progression).to be_started

    expect_any_instantiation_of(@topic).not_to receive(:recalculate_context_module_actions!) # doesn't recalculate unless it's a new requirement
    @module.update_attribute(:completion_requirements, { @tag1.id => { type: "must_submit" }, @tag2.id => { type: "must_contribute" } })
  end

  context "assignment muting" do
    it "works with muted assignments" do
      assignment = @course.assignments.create(title: "some assignment", points_possible: 100, submission_types: "online_text_entry")
      assignment.ensure_post_policy(post_manually: true)
      tag = @module.add_item({ id: assignment.id, type: "assignment" })
      @module.completion_requirements = { tag.id => { type: "min_score", min_score: 90 } }
      @module.save!

      progression = @module.evaluate_for(@user)
      expect(progression).to be_unlocked

      assignment.submit_homework(@user, body: "blah")
      assignment.grade_student(@user, score: 85, grader: @teacher)
      expect(progression.reload).to be_started
      expect(progression.requirements_met).to be_blank
      assignment.grade_student(@user, score: 95, grader: @teacher)
      expect(progression.reload).to be_started
      expect(progression.requirements_met).to be_blank

      assignment.unmute!
      expect(progression.reload).to be_completed
    end

    it "completes when the assignment is unmuted after a grade is assigned without a submission" do
      assignment = @course.assignments.create(title: "some assignment", points_possible: 100, submission_types: "online_text_entry")
      assignment.ensure_post_policy(post_manually: true)
      tag = @module.add_item({ id: assignment.id, type: "assignment" })
      @module.completion_requirements = { tag.id => { type: "min_score", min_score: 90 } }
      @module.save!

      progression = @module.evaluate_for(@user)
      expect(progression).to be_unlocked

      # no submission here
      assignment.grade_student(@user, score: 100, grader: @teacher)
      expect(progression.reload).to be_started
      expect(progression.requirements_met).to be_blank

      assignment.unmute!
      expect(progression.reload).to be_completed
    end

    it "works with muted quiz assignments" do
      quiz = @course.quizzes.create(title: "some quiz", quiz_type: "assignment", scoring_policy: "keep_highest", workflow_state: "available")
      quiz.assignment.ensure_post_policy(post_manually: true)
      tag = @module.add_item({ id: quiz.id, type: "quiz" })
      @module.completion_requirements = { tag.id => { type: "min_score", min_score: 90 } }
      @module.save!

      progression = @module.evaluate_for(@user)
      expect(progression).to be_unlocked

      quiz_sub = quiz.generate_submission(@user)
      quiz_sub.update(score: 100, workflow_state: "complete", submission_data: nil)
      quiz_sub.with_versioning(&:save)
      expect(progression.reload).to be_started

      quiz.assignment.unmute!
      expect(progression.reload).to be_completed
    end

    it "works with muted discussion assignments" do
      topic = @course.discussion_topics.create(title: "some topic")
      assignment = assignment_model(course: @course, points_possible: 100)
      topic.assignment = assignment
      topic.save!
      assignment.reload

      assignment.ensure_post_policy(post_manually: true)
      tag = @module.add_item({ id: topic.id, type: "discussion_topic" })
      @module.completion_requirements = { tag.id => { type: "min_score", min_score: 90 } }
      @module.save!

      progression = @module.evaluate_for(@user)
      expect(progression).to be_unlocked

      topic.reply_from(user: @user, text: "entry")
      expect(progression.reload).to be_started
      assignment.grade_student(@user, score: 100, grader: @teacher)
      expect(progression.reload).to be_started

      assignment.unmute!
      expect(progression.reload).to be_completed
    end
  end

  describe "tweaking collapsed state" do
    it "flips the state back and forth" do
      progression = @module.evaluate_for(@user)
      progression.collapse!
      expect(progression.collapsed?).to be_truthy
      progression.uncollapse!
      expect(progression.collapsed?).to be_falsey
    end

    it "doesn't bother if the state is already in the right place" do
      progression = @module.evaluate_for(@user)
      progression.collapse!
      expect(progression.collapsed?).to be_truthy
      expect(progression).not_to receive(:save)
      progression.collapse!
      expect(progression.collapsed?).to be_truthy
    end

    it "doesn't persist if you force it to skip" do
      progression = @module.evaluate_for(@user)
      progression.collapse!
      expect(progression.collapsed?).to be_truthy
      expect(progression).not_to receive(:save)
      progression.uncollapse!(skip_save: true)
      expect(progression.collapsed?).to be_falsey
    end
  end

  describe "live events" do
    before do
      @progression = @module.evaluate_for(@user)
    end

    it "sends live event when requirements_met is updated" do
      expect(Canvas::LiveEvents).to receive(:course_progress).once
      @progression.requirements_met = ["yay"]
      @progression.save!
    end

    it "does not trigger live event when requirement_met isn't changed" do
      expect(Canvas::LiveEvents).not_to receive(:course_progress)
      @progression.workflow_state = "completed"
      @progression.save!
    end

    it "does not trigger live event if requirements_met gets smaller" do
      @progression.requirements_met = %w[yay woohoo]
      @progression.save!

      expect(Canvas::LiveEvents).not_to receive(:course_progress)
      @progression.workflow_state = "completed"
      @progression.requirements_met = ["woohoo"]
      @progression.save!
    end
  end

  describe "for_course" do
    before do
      @course1 = @course
      @course2 = course_factory(active_all: true)
      @course2.context_modules.create!(name: "another module")
    end

    it "returns only progressions for the provided course" do
      cmp1 = ContextModuleProgression.create!(user: @user, context_module: @course1.context_modules.first)
      cmp2 = ContextModuleProgression.create!(user: @user, context_module: @course2.context_modules.first)
      expect(ContextModuleProgression.for_course(@course1).first.id).to be(cmp1.id)
      expect(ContextModuleProgression.for_course(@course2).first.id).to be(cmp2.id)
    end
  end
end
