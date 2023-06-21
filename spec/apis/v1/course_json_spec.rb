# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../../spec_helper"

module Api
  module V1
    describe CourseJson do
      let_once(:course) { ::Course.create! }
      let(:course_json) { CourseJson.new(course, nil, includes, []) }
      let(:includes) { [] }
      let(:user) { double(:user) }

      describe "#to_hash" do
        let_once(:student) { course_with_user("StudentEnrollment", course:, active_all: true).user }

        before(:once) do
          grading_period_group = course.grading_period_groups.create!
          grading_period_group.grading_periods.create!(
            title: "gp1",
            start_date: 1.day.ago,
            end_date: 2.days.from_now,
            close_date: 3.days.from_now
          )
        end

        it "contains information for the grading period even when final grades are hidden" do
          course.update!(hide_final_grades: true)
          includes = [:current_grading_period_scores, :total_scores]
          enrollments = Api::V1::CourseJson.to_hash(course, student, includes, course.enrollments).fetch("enrollments")
          expect(enrollments.first.keys).to include(
            :current_grading_period_id,
            :current_grading_period_title,
            :has_grading_periods,
            :multiple_grading_periods_enabled
          )
        end

        it "does not contain information for the period when total scores and period scores are not included" do
          includes = []
          enrollments = Api::V1::CourseJson.to_hash(course, student, includes, course.enrollments).fetch("enrollments")
          expect(enrollments.first.keys).not_to include(
            :current_grading_period_id,
            :current_grading_period_title,
            :has_grading_periods,
            :multiple_grading_periods_enabled
          )
        end

        context "total scores" do
          let_once(:includes) { [:total_scores] }

          context "when user is the student" do
            let_once(:student_enrollment) { course_with_user("StudentEnrollment", course:, active_all: true) }
            let_once(:student) { student_enrollment.user }
            let(:json_hash) { CourseJson.new(course, student, includes, [student_enrollment]).to_hash }
            let(:json_enrollments) { json_hash.fetch("enrollments") }
            let(:json_enrollment) { json_enrollments.detect { |enrollment| enrollment.fetch(:user_id) == student.id } }

            before(:once) do
              course.enable_feature!(:final_grades_override)
              course.update!(allow_final_grade_override: true, grading_standard_enabled: true)
              @course_score = student_enrollment.scores.create!(
                course_score: true, current_score: 63, final_score: 73, override_score: 99.0
              )
            end

            context "when Final Grade Override is enabled and allowed" do
              context "when a grade override exists" do
                it "sets computed_current_grade to the override grade" do
                  expect(json_enrollment.fetch(:computed_current_grade)).to eq "A"
                end

                it "sets computed_current_score to the override score" do
                  expect(json_enrollment.fetch(:computed_current_score)).to be 99.0
                end

                it "sets computed_current_letter_grade to the letter grade equivalent of the override score" do
                  expect(json_enrollment.fetch(:computed_current_letter_grade)).to eq "A"
                end

                it "sets computed_final_grade to the override grade" do
                  expect(json_enrollment.fetch(:computed_final_grade)).to eq "A"
                end

                it "sets computed_final_score to the override score" do
                  expect(json_enrollment.fetch(:computed_final_score)).to be 99.0
                end

                it "does not include an override_grade key" do
                  expect(json_enrollment).not_to have_key :override_grade
                end

                it "does not include an override_score key" do
                  expect(json_enrollment).not_to have_key :override_score
                end
              end

              context "when no grade override exists" do
                before { @course_score.update!(override_score: nil) }

                it "sets computed_current_grade to the computed current grade" do
                  expect(json_enrollment.fetch(:computed_current_grade)).to eq "D-"
                end

                it "sets computed_current_score to the computed current score" do
                  expect(json_enrollment.fetch(:computed_current_score)).to be 63.0
                end

                it "sets computed_current_letter_grade to the letter grade equivalent of the computed current score" do
                  expect(json_enrollment.fetch(:computed_current_letter_grade)).to eq "D-"
                end

                it "sets computed_final_grade to the computed final grade" do
                  expect(json_enrollment.fetch(:computed_final_grade)).to eq "C-"
                end

                it "sets computed_final_score to the computed final score" do
                  expect(json_enrollment.fetch(:computed_final_score)).to be 73.0
                end
              end
            end

            context "when Final Grade Override is not allowed" do
              before { course.update!(allow_final_grade_override: false) }

              it "sets computed_current_grade to the computed current grade" do
                expect(json_enrollment.fetch(:computed_current_grade)).to eq "D-"
              end

              it "sets computed_current_score to the computed current score" do
                expect(json_enrollment.fetch(:computed_current_score)).to be 63.0
              end

              it "sets computed_current_letter_grade to the letter grade equivalent of the computed current score" do
                expect(json_enrollment.fetch(:computed_current_letter_grade)).to eq "D-"
              end

              it "sets computed_final_grade to the computed final grade" do
                expect(json_enrollment.fetch(:computed_final_grade)).to eq "C-"
              end

              it "sets computed_final_score to the computed final score" do
                expect(json_enrollment.fetch(:computed_final_score)).to be 73.0
              end
            end

            context "when Final Grade Override is disabled" do
              before { course.disable_feature!(:final_grades_override) }

              it "sets computed_current_grade to the computed current grade" do
                expect(json_enrollment.fetch(:computed_current_grade)).to eq "D-"
              end

              it "sets computed_current_score to the computed current score" do
                expect(json_enrollment.fetch(:computed_current_score)).to be 63.0
              end

              it "sets computed_current_letter_grade to the letter grade equivalent of the computed current score" do
                expect(json_enrollment.fetch(:computed_current_letter_grade)).to eq "D-"
              end

              it "sets computed_final_grade to the computed final grade" do
                expect(json_enrollment.fetch(:computed_final_grade)).to eq "C-"
              end

              it "sets computed_final_score to the computed final score" do
                expect(json_enrollment.fetch(:computed_final_score)).to be 73.0
              end
            end
          end

          context "when user is a teacher" do
            let_once(:student_enrollment) { course_with_user("StudentEnrollment", course:, active_all: true) }
            let_once(:student) { student_enrollment.user }
            let_once(:teacher) { course_with_user("TeacherEnrollment", course:, active_all: true).user }
            let(:json_hash) { CourseJson.new(course, teacher, includes, [student_enrollment]).to_hash }
            let(:json_enrollments) { json_hash.fetch("enrollments") }
            let(:json_enrollment) { json_enrollments.detect { |enrollment| enrollment.fetch(:user_id) == student.id } }

            before(:once) do
              course.enable_feature!(:final_grades_override)
              course.update!(allow_final_grade_override: true, grading_standard_enabled: true)
              @course_score = student_enrollment.scores.create!(
                course_score: true, current_score: 63, final_score: 73, override_score: 99
              )
            end

            context "when Final Grade Override is enabled and allowed" do
              context "when a grade override exists" do
                it "sets computed_current_grade to the computed current grade" do
                  expect(json_enrollment.fetch(:computed_current_grade)).to eq "D-"
                end

                it "sets computed_current_score to the computed current score" do
                  expect(json_enrollment.fetch(:computed_current_score)).to be 63.0
                end

                it "sets computed_final_grade to the computed final grade" do
                  expect(json_enrollment.fetch(:computed_final_grade)).to eq "C-"
                end

                it "sets computed_final_score to the computed final score" do
                  expect(json_enrollment.fetch(:computed_final_score)).to be 73.0
                end

                it "sets override_grade to the override grade" do
                  expect(json_enrollment.fetch(:override_grade)).to eq "A"
                end

                it "sets override_score to the override score" do
                  expect(json_enrollment.fetch(:override_score)).to be 99.0
                end
              end

              context "when no grade override exists" do
                before { @course_score.update!(override_score: nil) }

                it "does not include an override_grade key" do
                  expect(json_enrollment).not_to have_key :override_grade
                end

                it "does not include an override_score key" do
                  expect(json_enrollment).not_to have_key :override_score
                end
              end
            end

            context "when Final Grade Override is not allowed" do
              before { course.update!(allow_final_grade_override: false) }

              it "does not include an override_grade key" do
                expect(json_enrollment).not_to have_key :override_grade
              end

              it "does not include an override_score key" do
                expect(json_enrollment).not_to have_key :override_score
              end
            end

            context "when Final Grade Override is disabled" do
              before { course.disable_feature!(:final_grades_override) }

              it "does not include an override_grade key" do
                expect(json_enrollment).not_to have_key :override_grade
              end

              it "does not include an override_score key" do
                expect(json_enrollment).not_to have_key :override_score
              end
            end
          end
        end

        context "current grading period scores" do
          let_once(:course) { ::Course.create! }
          let_once(:includes) { [:current_grading_period_scores, :total_scores] }

          context "when user is the student" do
            let_once(:student_enrollment) { course_with_user("StudentEnrollment", course:, active_all: true) }
            let_once(:student) { student_enrollment.user }
            let(:json_hash) { CourseJson.new(course, student, includes, [student_enrollment]).to_hash }
            let(:json_enrollments) { json_hash.fetch("enrollments") }
            let(:json_enrollment) { json_enrollments.detect { |enrollment| enrollment.fetch(:user_id) == student.id } }

            before(:once) do
              grading_period_group = course.grading_period_groups.create!
              gp1 = grading_period_group.grading_periods.create!(
                close_date: 2.days.from_now,
                end_date: 2.days.from_now,
                start_date: 1.day.ago,
                title: "gp1"
              )
              @gp_score = student_enrollment.scores.find_by!(grading_period: gp1)
              @gp_score.update!(current_score: 63, final_score: 73, override_score: 99)
              course.enable_feature!(:final_grades_override)
              course.update!(allow_final_grade_override: true, grading_standard_enabled: true)
            end

            context "when Final Grade Override is enabled and allowed" do
              context "when a grade override exists" do
                it "sets current_period_computed_current_grade to the override grade" do
                  expect(json_enrollment.fetch(:current_period_computed_current_grade)).to eq "A"
                end

                it "sets current_period_computed_current_score to the override score" do
                  expect(json_enrollment.fetch(:current_period_computed_current_score)).to be 99.0
                end

                it "sets current_period_computed_final_grade to the override grade" do
                  expect(json_enrollment.fetch(:current_period_computed_final_grade)).to eq "A"
                end

                it "sets current_period_computed_final_score to the override score" do
                  expect(json_enrollment.fetch(:current_period_computed_final_score)).to be 99.0
                end

                it "does not include a current_period_override_grade key" do
                  expect(json_enrollment).not_to have_key :current_period_override_grade
                end

                it "does not include a current_period_override_score key" do
                  expect(json_enrollment).not_to have_key :current_period_override_score
                end
              end

              context "when no grade override exists" do
                before { @gp_score.update!(override_score: nil) }

                it "sets current_period_computed_current_grade to the computed current grade" do
                  expect(json_enrollment.fetch(:current_period_computed_current_grade)).to eq "D-"
                end

                it "sets current_period_computed_current_score to the computed current score" do
                  expect(json_enrollment.fetch(:current_period_computed_current_score)).to be 63.0
                end

                it "sets current_period_computed_final_grade to the computed final grade" do
                  expect(json_enrollment.fetch(:current_period_computed_final_grade)).to eq "C-"
                end

                it "sets current_period_computed_final_score to the computed final score" do
                  expect(json_enrollment.fetch(:current_period_computed_final_score)).to be 73.0
                end
              end
            end

            context "when Final Grade Override is not allowed" do
              before { course.update!(allow_final_grade_override: false) }

              it "sets current_period_computed_current_grade to the computed current grade" do
                expect(json_enrollment.fetch(:current_period_computed_current_grade)).to eq "D-"
              end

              it "sets current_period_computed_current_score to the computed current score" do
                expect(json_enrollment.fetch(:current_period_computed_current_score)).to be 63.0
              end

              it "sets current_period_computed_final_grade to the computed final grade" do
                expect(json_enrollment.fetch(:current_period_computed_final_grade)).to eq "C-"
              end

              it "sets current_period_computed_final_score to the computed final score" do
                expect(json_enrollment.fetch(:current_period_computed_final_score)).to be 73.0
              end
            end

            context "when Final Grade Override is disabled" do
              before { course.disable_feature!(:final_grades_override) }

              it "sets current_period_computed_current_grade to the computed current grade" do
                expect(json_enrollment.fetch(:current_period_computed_current_grade)).to eq "D-"
              end

              it "sets current_period_computed_current_score to the computed current score" do
                expect(json_enrollment.fetch(:current_period_computed_current_score)).to be 63.0
              end

              it "sets current_period_computed_final_grade to the computed final grade" do
                expect(json_enrollment.fetch(:current_period_computed_final_grade)).to eq "C-"
              end

              it "sets current_period_computed_final_score to the computed final score" do
                expect(json_enrollment.fetch(:current_period_computed_final_score)).to be 73.0
              end
            end
          end

          context "when user is a teacher" do
            let_once(:student_enrollment) { course_with_user("StudentEnrollment", course:, active_all: true) }
            let_once(:student) { student_enrollment.user }
            let_once(:teacher) { course_with_user("TeacherEnrollment", course:, active_all: true).user }
            let(:json_hash) { CourseJson.new(course, teacher, includes, [student_enrollment]).to_hash }
            let(:json_enrollments) { json_hash.fetch("enrollments") }
            let(:json_enrollment) { json_enrollments.detect { |enrollment| enrollment.fetch(:user_id) == student.id } }

            before(:once) do
              grading_period_group = course.grading_period_groups.create!
              @gp1 = grading_period_group.grading_periods.create!(
                close_date: 2.days.from_now,
                end_date: 2.days.from_now,
                start_date: 1.day.ago,
                title: "gp1"
              )
              course.enable_feature!(:final_grades_override)
              course.update!(allow_final_grade_override: true, grading_standard_enabled: true)
              @gp_score = student_enrollment.scores.find_by!(grading_period: @gp1)
              @gp_score.update!(current_score: 63, final_score: 73, override_score: 99)
            end

            it "doesn't error when there is no grading period" do
              @gp1.destroy
              expect { json_enrollment.fetch(:current_period_computed_current_score) }.to_not raise_error
            end

            context "when Final Grade Override is enabled and allowed" do
              context "when a grade override exists" do
                it "sets computed_current_grade to the computed current grade" do
                  expect(json_enrollment.fetch(:current_period_computed_current_grade)).to eq "D-"
                end

                it "sets computed_current_score to the computed current score" do
                  expect(json_enrollment.fetch(:current_period_computed_current_score)).to be 63.0
                end

                it "sets computed_final_grade to the computed final grade" do
                  expect(json_enrollment.fetch(:current_period_computed_final_grade)).to eq "C-"
                end

                it "sets computed_final_score to the computed final score" do
                  expect(json_enrollment.fetch(:current_period_computed_final_score)).to be 73.0
                end

                it "sets override_grade to the override grade" do
                  expect(json_enrollment.fetch(:current_period_override_grade)).to eq "A"
                end

                it "sets override_score to the override score" do
                  expect(json_enrollment.fetch(:current_period_override_score)).to be 99.0
                end
              end

              context "when no grade override exists" do
                before { @gp_score.update!(override_score: nil) }

                it "does not include a current_period_override_grade key" do
                  expect(json_enrollment).not_to have_key :current_period_override_grade
                end

                it "does not include a current_period_override_score key" do
                  expect(json_enrollment).not_to have_key :current_period_override_score
                end
              end
            end

            context "when Final Grade Override is not allowed" do
              before { course.update!(allow_final_grade_override: false) }

              it "does not include a current_period_override_grade key" do
                expect(json_enrollment).not_to have_key :current_period_override_grade
              end

              it "does not include a current_period_override_score key" do
                expect(json_enrollment).not_to have_key :current_period_override_score
              end
            end

            context "when Final Grade Override is disabled" do
              before { course.disable_feature!(:final_grades_override) }

              it "does not include a current_period_override_grade key" do
                expect(json_enrollment).not_to have_key :current_period_override_grade
              end

              it "does not include a current_period_override_score key" do
                expect(json_enrollment).not_to have_key :current_period_override_score
              end
            end
          end
        end
      end

      describe "#include_description" do
        let(:predicate) { course_json.include_description }

        it "affirms when the public_description key is in the includes array" do
          includes << "public_description"
          expect(predicate).to be_truthy
        end

        it "affirms when the public_description key is a symbol" do
          includes << :public_description
          expect(predicate).to be_truthy
        end

        it "negates when the public_description key is missing" do
          expect(predicate).to be_falsey
        end
      end

      describe "#include_total_scores?" do
        let(:predicate) { course_json.include_total_scores? }
        let(:course_settings) { {} }
        let(:course) { double(course_settings) }

        describe "when total scores key is set" do
          before { includes << :total_scores }

          it "is false if the final grade is hidden" do
            course_settings[:hide_final_grades?] = true
            expect(predicate).to be_falsey
          end

          it "is true if the course allows the grade to be seen" do
            course_settings[:hide_final_grades?] = false
            expect(predicate).to be_truthy
          end
        end

        describe "when total scores key is not set" do
          before { includes.clear }

          it "is false if the final grade is hidden" do
            course_settings[:hide_final_grades?] = true
            expect(predicate).to be_falsey
          end

          it "is false even even if the final grade is NOT hidden" do
            course_settings[:hide_final_grades?] = false
            expect(predicate).to be_falsey
          end
        end
      end

      describe "#allowed_attributes" do
        it "just returns the base attributes when there are no includes" do
          includes.clear
          expect(course_json.allowed_attributes).to eq CourseJson::BASE_ATTRIBUTES
        end

        it "tacks on any includes" do
          includes << :some << :other << :keys
          expect(course_json.allowed_attributes).to eq(CourseJson::BASE_ATTRIBUTES + %i[some other keys])
        end
      end

      describe "#methods_to_send" do
        it "includes the end_at field" do
          expect(course_json.methods_to_send).to include("end_at")
        end

        it "includes the public_syllabus field" do
          expect(course_json.methods_to_send).to include("public_syllabus")
        end

        it "includes the public_syllabus_to_auth field" do
          expect(course_json.methods_to_send).to include("public_syllabus_to_auth")
        end

        it "includes the storage_quota_mb field" do
          expect(course_json.methods_to_send).to include("storage_quota_mb")
        end

        it "includes the hide_final_grades method if its in the includes array" do
          includes << :hide_final_grades
          expect(course_json.methods_to_send).to include("hide_final_grades")
        end
      end

      describe "#clear_unneeded_fields" do
        let(:hash) { {} }

        describe "with an optional field" do
          before { hash["enrollments"] = [] }

          it "kicks the key-value pair out if the value is nil" do
            hash["enrollments"] = nil
            expect(course_json.clear_unneeded_fields(hash)).to eq({})
          end

          it "keeps the key-value pair if the value is not nil" do
            expect(course_json.clear_unneeded_fields(hash)).to eq({ "enrollments" => [] })
          end
        end

        describe "with any other field" do
          before { hash["some_other_key"] = "some_value" }

          it "keeps the key-value pair even if the value is nil" do
            hash["some_other_key"] = nil
            expect(course_json.clear_unneeded_fields(hash)).to eq({ "some_other_key" => nil })
          end

          it "keeps the key-value pair if the value is not nil" do
            expect(course_json.clear_unneeded_fields(hash)).to eq({ "some_other_key" => "some_value" })
          end
        end
      end

      describe "#description" do
        let(:course) { double(public_description: "an eloquent anecdote") }

        it "returns the description when its configured for inclusion" do
          includes << :public_description
          expect(course_json.include_description).to be_truthy
          expect(course_json.description(course)).to eq "an eloquent anecdote"
        end

        it "is nil when configured not to be included" do
          includes.clear
          expect(course_json.description(course)).to be_nil
        end
      end

      describe "#initialization" do
        subject { @json }

        let(:enrollments) { double(:enrollments) }
        let(:hash) { { a: "1", b: "2" } }
        let(:includes) { %w[these three keys] }

        before do
          @json = CourseJson.new(course, user, includes, enrollments) { hash }
        end

        describe "#course" do
          subject { super().course }

          it { is_expected.to eq course }
        end

        describe "#user" do
          subject { super().user }

          it { is_expected.to eq user }
        end

        describe "#includes" do
          subject { super().includes }

          it { is_expected.to eq %i[these three keys] }
        end

        describe "#enrollments" do
          subject { super().enrollments }

          it { is_expected.to eq enrollments }
        end

        describe "#hash" do
          subject { super().hash }

          it { is_expected.to eq hash }
        end
      end

      describe "#set_sis_course_id" do
        let(:sis_course) { double(grants_right?: @has_right, sis_source_id: @sis_id, sis_batch_id: @batch, root_account:) }
        let(:sis_course_json) { CourseJson.new(sis_course, user, includes, []) }
        let(:root_account) { double(grants_right?: @has_right) }
        let(:hash) { {} }

        before do
          @sis_id = 1357
          @batch = 991_357
          @has_right = false
        end

        describe "when appropriate rights are granted" do
          before { @has_right = true }

          it "adds sis the key-value pair to the hash" do
            sis_course_json.set_sis_course_id(hash)
            expect(hash["sis_course_id"]).to eq 1357
          end

          describe "with a nil sis_id" do
            before do
              @sis_id = nil
              @batch = nil
              sis_course_json.set_sis_course_id(hash)
            end

            it "allows the nil value to go into the has" do
              expect(hash["sis_course_id"]).to be_nil
            end

            it "does not get cleared out before translation to json" do
              expect(sis_course_json.clear_unneeded_fields(hash)).to eq({ "sis_course_id" => nil, "sis_import_id" => nil })
            end
          end
        end

        it "doesnt add the sis_course_id key at all if the rights are NOT present" do
          sis_course_json.set_sis_course_id(hash)
          expect(hash).to eq({})
        end

        it "uses precalculated permissions if available" do
          precalculated_permissions = { read_sis: false, manage_sis: true }
          course_json_with_perms = CourseJson.new(sis_course, user, includes, [], precalculated_permissions:)
          expect(sis_course).to_not receive(:grants_right?)
          course_json_with_perms.set_sis_course_id(hash)
          expect(hash["sis_course_id"]).to eq 1357
        end
      end

      describe "#permissions" do
        let(:course) { double(public_description: "an eloquent anecdote") }

        it "returns the permissions when its configured for inclusion" do
          includes << :permissions
          expect(course_json.include_permissions).to be_truthy
          expect(course_json.permissions_to_include).to eq [:create_discussion_topic, :create_announcement]
        end

        it "is nil when configured not to be included" do
          includes.clear
          expect(course_json.permissions_to_include).to be_nil
        end
      end
    end
  end
end
