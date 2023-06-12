# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../../conditional_release_spec_helper"

describe ConditionalRelease::Service do
  def enable_service
    allow(described_class).to receive(:enabled_in_context?).and_return(true)
  end

  context "configuration" do
    it "reports enabled as true when enabled" do
      context = Course.create!
      context.conditional_release = true
      context.save!
      env = described_class.env_for(context)
      expect(env[:CONDITIONAL_RELEASE_SERVICE_ENABLED]).to be true
    end

    it "reports enabled as false if the context is an Account" do
      context = Account.create!
      context.settings[:conditional_release] = { value: true }
      context.save!
      env = described_class.env_for(context)
      expect(env[:CONDITIONAL_RELEASE_SERVICE_ENABLED]).to be false
    end

    it "reports enabled as false if feature flag is off" do
      context = Course.create!
      env = described_class.env_for(context)
      expect(env[:CONDITIONAL_RELEASE_SERVICE_ENABLED]).to be false
    end
  end

  describe "env_for" do
    before do
      enable_service
      allow(described_class).to receive(:active_rules).and_return([])
      course_with_student(active_all: true)
    end

    it "returns no env if not enabled" do
      allow(described_class).to receive(:enabled_in_context?).and_return(false)
      env = described_class.env_for(@course, @student)
      expect(env).not_to have_key :CONDITIONAL_RELEASE_ENV
    end

    it "returns no env if user not specified" do
      env = described_class.env_for(@course)
      expect(env).not_to have_key :CONDITIONAL_RELEASE_ENV
    end

    it "returns an env if everything enabled" do
      env = described_class.env_for(@course, @student)
      expect(env[:CONDITIONAL_RELEASE_ENV][:stats_url]).to eq "/api/v1/courses/#{@course.id}/mastery_paths/stats"
    end

    it "includes assignment data when an assignment is specified" do
      assignment_model course: @course
      env = described_class.env_for(@course, @student, assignment: @assignment)
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env[:assignment][:id]).to eq @assignment.id
      expect(cr_env[:assignment][:title]).to eq @assignment.title
      expect(cr_env[:assignment][:points_possible]).to eq @assignment.points_possible
      expect(cr_env[:assignment][:grading_type]).to eq @assignment.grading_type
      expect(cr_env[:assignment][:submission_types]).to eq @assignment.submission_types
    end

    it "excludes assignment data when an assignment is locked" do
      assignment_model course: @course, unlock_at: 1.day.from_now, due_at: 2.days.from_now
      env = described_class.env_for(@course, @student, assignment: @assignment)
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env[:assignment]).to be_nil
    end

    it "includes a grading scheme when assignment uses it" do
      standard = grading_standard_for(@course)
      assignment_model course: @course, grading_type: "letter_grade", grading_standard: standard
      env = described_class.env_for(@course, @student, assignment: @assignment)
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env[:assignment][:grading_scheme]).to eq standard.grading_scheme
    end

    it "includes a default grading scheme even when the assignment does not use it" do
      grading_standard_for(@course)
      assignment_model course: @course, grading_type: "points"
      env = described_class.env_for(@course, @student, assignment: @assignment)
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env[:assignment][:grading_scheme]).to eq GradingStandard.default_instance.grading_scheme
    end

    it "includes a relevant rule if includes :rule" do
      assignment_model course: @course
      allow(described_class).to receive(:rule_triggered_by).and_return(nil)
      env = described_class.env_for(@course, @student, assignment: @assignment, includes: [:rule])
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env).to have_key :rule
    end

    it "includes a active rules if includes :active_rules" do
      assignment_model course: @course
      allow(described_class).to receive(:rule_triggered_by).and_return(nil)
      env = described_class.env_for(@course, @student, assignment: @assignment, includes: [:active_rules])
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env).to have_key :active_rules
    end
  end

  context "native conditional release" do
    before :once do
      setup_course_with_native_conditional_release
    end

    context "active_rules" do
      it "shows all the rules in the course to teachers" do
        data = described_class.active_rules(@course, @teacher, nil)
        # basically it's just the same thing as returned by the api
        expect(data.first["scoring_ranges"].first["assignment_sets"].first["assignment_set_associations"].first["assignment_id"]).to eq @set1_assmt1.id
        expect(data.first["trigger_assignment_model"]["points_possible"]).to eq @trigger_assmt.points_possible
      end

      context "caching" do
        specs_require_cache(:redis_cache_store)

        it "caches across admins" do
          old_teacher = @teacher
          teacher_in_course(course: @course)
          data = described_class.active_rules(@course, old_teacher, nil)
          @course.conditional_release_rules.update_all(deleted_at: Time.now.utc) # skip callbacks
          expect(described_class.active_rules(@course, @teacher, nil)).to eq data # doesn't matter who accesses it if they have rights
        end

        it "invalidates cache when a rule is saved" do
          described_class.active_rules(@course, @teacher, nil)
          @rule.update_attribute(:deleted_at, Time.now.utc)
          expect(described_class.active_rules(@course, @teacher, nil)).to eq []
        end

        it "invalidates cache when a trigger assignment is deleted" do
          described_class.active_rules(@course, @teacher, nil)
          @trigger_assmt.destroy
          expect(described_class.active_rules(@course, @teacher, nil)).to eq []
        end

        it "invalidates cache when a releasable assignment is deleted" do
          old_data = described_class.active_rules(@course, @teacher, nil)
          @set1_assmt1.destroy
          data = described_class.active_rules(@course, @teacher, nil)
          expect(data).to_not eq old_data
          expect(data.first["scoring_ranges"].first["assignment_sets"].first["assignment_set_associations"]).to eq []
        end
      end
    end

    context "rules_for" do
      it "returns no assignment set data for unreleased rules" do
        data = described_class.rules_for(@course, @student, nil)
        expect(data.count).to eq 1
        rule_hash = data.first
        expect(rule_hash["trigger_assignment_id"]).to eq @trigger_assmt.id
        expect(rule_hash["locked"]).to be true
        expect(rule_hash["selected_set_id"]).to be_nil
        expect(rule_hash["assignment_sets"]).to eq []
      end

      it "returns data about released assignment sets" do
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
        rule_hash = described_class.rules_for(@course, @student, nil).first
        expect(rule_hash["trigger_assignment_id"]).to eq @trigger_assmt.id
        expect(rule_hash["locked"]).to be false
        released_set = @set1_assmt1.conditional_release_associations.first.assignment_set
        expect(rule_hash["selected_set_id"]).to eq released_set.id
        expect(rule_hash["assignment_sets"].count).to eq 1
        set_hash = rule_hash["assignment_sets"].first
        expect(set_hash["assignment_set_associations"].first["model"]).to eq @set1_assmt1
      end

      it "returns data about multiple assignment set choices" do
        @trigger_assmt.grade_student(@student, grade: 2, grader: @teacher) # has two choices now
        rule_hash = described_class.rules_for(@course, @student, nil).first
        expect(rule_hash["trigger_assignment_id"]).to eq @trigger_assmt.id
        expect(rule_hash["locked"]).to be false
        expect(rule_hash["selected_set_id"]).to be_nil # neither one was picked yet
        expect(rule_hash["assignment_sets"].count).to eq 2
        expect(rule_hash["assignment_sets"].map { |s| s["assignment_set_associations"].first["model"] }).to match_array([@set3a_assmt, @set3b_assmt])
      end

      context "caching" do
        specs_require_cache(:redis_cache_store)

        it "caches" do
          data = described_class.rules_for(@course, @student, nil)
          @course.conditional_release_rules.update_all(deleted_at: Time.now.utc) # skip callbacks
          expect(described_class.rules_for(@course, @student, nil)).to eq data
        end

        it "invalidates cache on rule change" do
          described_class.rules_for(@course, @student, nil)
          @rule.update_attribute(:deleted_at, Time.now.utc)
          expect(described_class.rules_for(@course, @student, nil)).to eq []
        end

        it "invalidates cache on submission change" do
          data = described_class.rules_for(@course, @student, nil)
          @trigger_assmt.grade_student(@student, grade: 8, grader: @teacher)
          expect(described_class.rules_for(@course, @student, nil)).to_not eq data
        end
      end
    end

    context "releasing content after disabling feature flag" do
      before :once do
        account = Account.default
        account.settings[:conditional_release_enabled] = { value: false, locked: false }
        account.save!
        course_with_student(active_all: true)
        @course.conditional_release = true
        @course.save!
        @module = @course.context_modules.create!(workflow_state: "active")
      end

      def release_content
        ConditionalRelease::Service.release_mastery_paths_content_in_course(@course)
      end

      it "releases mastery paths assigned assignments" do
        assmt = assignment_model(course: @course, workflow_state: "published", only_visible_to_overrides: true)
        assignment_override_model(assignment: assmt,
                                  set_type: AssignmentOverride::SET_TYPE_NOOP,
                                  set_id: AssignmentOverride::NOOP_MASTERY_PATHS)
        tag = @module.add_item(id: assmt.id, type: "assignment")
        expect(@course.module_items_visible_to(@student).to_a).to eq []

        release_content
        expect(@course.module_items_visible_to(@student).to_a).to eq [tag]
      end

      it "releases mastery paths assigned ungraded quizzes" do
        quiz = quiz_model(course: @course, quiz_type: "survey", only_visible_to_overrides: true)
        assignment_override_model(quiz:,
                                  set_type: AssignmentOverride::SET_TYPE_NOOP,
                                  set_id: AssignmentOverride::NOOP_MASTERY_PATHS)
        tag = @module.add_item(id: quiz.id, type: "quiz")
        expect(@course.module_items_visible_to(@student).to_a).to eq []

        release_content
        expect(@course.module_items_visible_to(@student).to_a).to eq [tag]
      end

      it "releases mastery paths assigned wiki pages" do
        wiki_page_assignment_model(course: @course, only_visible_to_overrides: true)
        tag = @module.add_item(id: @page.id, type: "wiki_page")
        expect(@course.module_items_visible_to(@student).to_a).to eq []

        release_content
        expect(@course.module_items_visible_to(@student).to_a).to eq [tag]
      end
    end
  end
end
