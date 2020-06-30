#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative '../../conditional_release_spec_helper'
require_dependency "conditional_release/assimilator"

module ConditionalRelease
  describe Assimilator do
    it "should import all the stuff" do
      Account.default.enable_feature!(:conditional_release)

      course_factory(:active_all => true)
      students = n_students_in_course(3, :course => @course)
      trigger_assmt = @course.assignments.create!(:points_possible => 10, submission_types: "online_text_entry")
      subs = students.map{|s| trigger_assmt.submit_homework(s, body: "hi")}

      set1_assmt = @course.assignments.create!(:only_visible_to_overrides => true) # one in one set
      set2_assmt = @course.assignments.create!(:only_visible_to_overrides => true)
      set3a_assmt = @course.assignments.create!(:only_visible_to_overrides => true) # two sets in one range - will have to choose
      set3b_assmt = @course.assignments.create!(:only_visible_to_overrides => true)

      # service ids are arbitary
      set1_id = 9001
      set3a_id = 42
      service_data = [{
        "id" => 3,
        "account_id" => Account.default.global_id,
        "course_id" => @course.id.to_s,
        "trigger_assignment" => trigger_assmt.id.to_s,
        "created_at" => "2020-06-30T14:12:05.132Z",
        "updated_at" => "2020-06-30T14:12:05.132Z",
        "scoring_ranges" =>
          [{"id" => 7,
            "rule_id" => 3,
            "lower_bound" => "0.8",
            "upper_bound" => nil,
            "created_at" => "2020-06-30T14:12:05.134Z",
            "updated_at" => "2020-06-30T14:12:05.134Z",
            "position" => 1,
            "assignment_sets" =>
              [{"id" => set1_id,
                "scoring_range_id" => 7,
                "created_at" => "2020-06-30T14:12:05.138Z",
                "updated_at" => "2020-06-30T14:12:05.138Z",
                "position" => 1,
                "deleted_at" => nil,
                "assignments" =>
                  [{"id" => 1,
                    "assignment_id" => set1_assmt.id.to_s,
                    "created_at" => "2020-06-30T14:12:05.142Z",
                    "updated_at" => "2020-06-30T14:12:05.142Z",
                    "override_id" => nil,
                    "assignment_set_id" => 7,
                    "position" => 1,
                    "deleted_at" => nil}]}]},
            {"id" => 8,
              "rule_id" => 3,
              "lower_bound" => "0.3",
              "upper_bound" => "0.8",
              "created_at" => "2020-06-30T14:12:05.157Z",
              "updated_at" => "2020-06-30T14:12:05.157Z",
              "position" => 2,
              "deleted_at" => nil,
              "assignment_sets" =>
                [{"id" => 9,
                  "scoring_range_id" => 8,
                  "created_at" => "2020-06-30T14:12:05.162Z",
                  "updated_at" => "2020-06-30T14:12:05.162Z",
                  "position" => 1,
                  "deleted_at" => nil,
                  "assignments" =>
                    [{"id" => 3,
                      "assignment_id" => set2_assmt.id.to_s,
                      "created_at" => "2020-06-30T14:12:05.168Z",
                      "updated_at" => "2020-06-30T14:12:05.168Z",
                      "override_id" => 17,
                      "assignment_set_id" => 9,
                      "position" => 1,
                      "deleted_at" => nil}]}]},
            {"id" => 9,
              "rule_id" => 3,
              "lower_bound" => nil,
              "upper_bound" => "0.3",
              "created_at" => "2020-06-30T14:12:05.174Z",
              "updated_at" => "2020-06-30T14:12:05.174Z",
              "position" => 3,
              "deleted_at" => nil,
              "assignment_sets" =>
                [{"id" => set3a_id,
                  "scoring_range_id" => 9,
                  "created_at" => "2020-06-30T14:12:05.183Z",
                  "updated_at" => "2020-06-30T14:12:05.183Z",
                  "position" => 1,
                  "deleted_at" => nil,
                  "assignments" =>
                    [{
                      "id" => 3,
                      "assignment_id" => set3a_assmt.id.to_s,
                      "created_at" => "2020-06-30T14:12:05.168Z",
                      "updated_at" => "2020-06-30T14:12:05.168Z",
                      "override_id" => 17,
                      "assignment_set_id" => 9,
                      "position" => 1,
                      "deleted_at" => nil
                    }]},
                  {"id" => 9,
                    "scoring_range_id" => 9,
                    "created_at" => "2020-06-30T14:12:05.183Z",
                    "updated_at" => "2020-06-30T14:12:05.183Z",
                    "position" => 2,
                    "deleted_at" => nil,
                    "assignments" =>
                      [{
                        "id" => 3,
                        "assignment_id" => set3b_assmt.id.to_s,
                        "created_at" => "2020-06-30T14:12:05.168Z",
                        "updated_at" => "2020-06-30T14:12:05.168Z",
                        "override_id" => 17,
                        "assignment_set_id" => 9,
                        "position" => 1,
                        "deleted_at" => nil
                      }]}
                ]}],
        "assignment_set_actions" =>
          [{
            "id" => 1,
            "action" => "assign",
            "source" => "grade_change",
            "student_id" => students[0].id.to_s,
            "actor_id" => @teacher.id.to_s,
            "assignment_set_id" => set1_id,
            "created_at" => "2020-06-30T14:46:34.286Z",
            "updated_at" => "2020-06-30T14:46:34.286Z",
            "deleted_at" => nil
          },
          {
            "id" => 2,
            "action" => "assign",
            "source" => "select_assignment_set",
            "student_id" => students[1].id.to_s,
            "actor_id" => @teacher.id.to_s,
            "assignment_set_id" => set3a_id,
            "created_at" => "2020-06-30T14:46:34.286Z",
            "updated_at" => "2020-06-30T14:46:34.286Z",
            "deleted_at" => nil
          }]
      }]
      expect(ConditionalRelease::Assimilator).to receive(:retrieve_rules_data_from_service).with(Account.default).and_return(service_data)

      trigger_assmt.grade_student(students[2], grade: 5, grader: @teacher)
      Submission.where(:id => subs[2]).update_all(:updated_at => 1.minute.from_now) # make sure it gets pulled in the post-migrate resync query

      ConditionalRelease::Assimilator.run(Account.default)

      rule = trigger_assmt.conditional_release_rules.first
      expect(rule.scoring_ranges.count).to eq 3
      expect(rule.scoring_ranges.map{|r| r.upper_bound}).to eq [nil, 0.8, 0.3]
      expect(rule.scoring_ranges.map{|r| r.lower_bound}).to eq [0.8, 0.3, nil]
      range_assmts = rule.scoring_ranges.map{|r| r.assignment_sets.map{|s| s.assignment_set_associations.map(&:assignment_id)}}
      expect(range_assmts[0]).to eq [[set1_assmt.id]]
      expect(range_assmts[1]).to eq [[set2_assmt.id]]
      expect(range_assmts[2]).to eq [[set3a_assmt.id], [set3b_assmt.id]]
      set_actions = students.map{|s| AssignmentSetAction.where(:student_id => s).first}
      expect(set_actions[0].assignment_set.assignment_set_associations.map(&:assignment_id)).to eq [set1_assmt.id] # top set
      expect(set_actions[0].source).to eq "grade_change"
      expect(set_actions[1].assignment_set.assignment_set_associations.map(&:assignment_id)).to eq [set3a_assmt.id] # bottom row first set selection
      expect(set_actions[1].source).to eq "select_assignment_set"
      expect(set_actions[2].assignment_set.assignment_set_associations.map(&:assignment_id)).to eq [set2_assmt.id] # middle set - got picked up in post import sync
    end

    it "should rescue from errors" do
      expect(ConditionalRelease::Assimilator).to receive(:retrieve_rules_data_from_service).and_raise("aaaaa")

      expect {
        ConditionalRelease::Assimilator.run(Account.default)
      }.to raise_error("aaaaa")
      expect(Account.default.reload.settings[:conditional_release_assimilation_failed_at]).to be_present
      expect(ConditionalRelease::Assimilator.assimilation_in_progress?(Account.default)).to eq false
    end
  end
end
