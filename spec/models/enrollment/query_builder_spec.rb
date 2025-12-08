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

describe "Enrollment::QueryBuilder" do
  describe "#conditions" do
    let(:conditions)     { Enrollment::QueryBuilder.new(state, options).conditions }
    let(:options)        { {} }
    let(:account_id)     { Account.create(name: "Account").id }
    let(:term_id)        { create_record(EnrollmentTerm, name: "default", root_account_id: account_id, created_at: Time.now.utc, updated_at: Time.now.utc) }
    let(:user)           { create_record(User, { name: "User", workflow_state: "active", created_at: Time.now.utc, updated_at: Time.now.utc }, :record) }
    let(:enrollment_map) { {} }

    # each item corresponds to a unique course the user is enrolled in
    def create_enrollments(*matrix)
      now = Time.now.utc
      course_ids = create_records(Course, matrix.map do |_e_state, c_state, _type|
        {
          name: "Course",
          account_id:,
          workflow_state: c_state,
          root_account_id: account_id,
          enrollment_term_id: term_id,
          created_at: now,
          updated_at: now,
        }
      end)

      section_ids = create_records(CourseSection, course_ids.each_index.map do |i|
        {
          course_id: course_ids[i],
          root_account_id: account_id,
          name: "Section",
          created_at: now,
          updated_at: now,
        }
      end)

      enrollment_ids = create_records(Enrollment, matrix.each_with_index.map do |(e_state, _, type), i|
        {
          user_id: user.id,
          course_id: course_ids[i],
          type:,
          workflow_state: e_state,
          course_section_id: section_ids[i],
          role_id: Role.get_built_in_role(type, root_account_id: account_id).id,
          root_account_id: account_id,
          created_at: now,
          updated_at: now,
        }
      end)

      enrollment_ids.each_with_index do |id, i|
        enrollment_map[id] = matrix[i]
      end
    end

    def matches_for(scope)
      enrollment_map.values_at(*scope.pluck(:id)).sort
    end

    def enrollments(course_workflow_state = nil)
      scope = user.enrollments.joins(:course)
      if course_workflow_state
        scope = scope.where(courses: { workflow_state: course_workflow_state })
      end
      scope
    end

    shared_examples_for "enforce_course_workflow_state" do
      let(:options) { { strict_checks: false } }

      context "with :enforce_course_workflow_state=true" do
        it "rejects enrollments in courses with a different workflow_state" do
          create_enrollments(
            [state.to_s, "available", "StudentEnrollment"]
          )
          options[:course_workflow_state] = "unknown"
          options[:enforce_course_workflow_state] = true

          result = enrollments.where(conditions)
          expect(result).to be_empty
        end
      end
    end

    context "with :active" do
      let(:state) { :active }

      before do
        create_enrollments(
          %w[active available StudentEnrollment],
          %w[active available TeacherEnrollment],
          %w[active claimed StudentEnrollment],
          %w[active claimed TeacherEnrollment],
          %w[invited available StudentEnrollment]
        )
      end

      context "with strict_checks:true" do
        let(:options) { { strict_checks: true } }

        it "returns sensible defaults" do
          result = enrollments.where(conditions)
          expect(matches_for(result)).to eq [
            %w[active available StudentEnrollment],
            %w[active available TeacherEnrollment],
            %w[active claimed TeacherEnrollment]
          ]
        end

        it "returns active enrollments in available courses" do
          options[:course_workflow_state] = "available"
          result = enrollments("available").where(conditions)
          expect(matches_for(result)).to eq [
            %w[active available StudentEnrollment],
            %w[active available TeacherEnrollment]
          ]
        end

        it "returns visible enrollments in unpublished courses" do
          options[:course_workflow_state] = "claimed"
          result = enrollments("claimed").where(conditions)
          expect(matches_for(result)).to eq [
            %w[active claimed TeacherEnrollment]
          ]
        end

        it "returns nothing for other course workflow states" do
          options[:course_workflow_state] = "deleted"
          expect(conditions).to be_nil
        end
      end

      context "with strict_checks:false" do
        let(:options) { { strict_checks: false } }

        it "returns sensible defaults" do
          result = enrollments.where(conditions)
          expect(matches_for(result)).to eq [
            %w[active available StudentEnrollment],
            %w[active available TeacherEnrollment],
            %w[active claimed StudentEnrollment],
            %w[active claimed TeacherEnrollment]
          ]
        end

        it "does not return anything if the course is deleted" do
          options[:course_workflow_state] = "deleted"
          expect(conditions).to be_nil
        end

        it "returns all active enrollments in non-deleted courses" do
          options[:course_workflow_state] = "claimed" # not enforcing state, so we get both claimed and available
          result = enrollments.where(conditions)
          expect(matches_for(result)).to eq [
            %w[active available StudentEnrollment],
            %w[active available TeacherEnrollment],
            %w[active claimed StudentEnrollment],
            %w[active claimed TeacherEnrollment]
          ]
        end
      end

      it_behaves_like "enforce_course_workflow_state"
    end

    context "with :invited" do
      let(:state) { :invited }

      before do
        create_enrollments(
          %w[creation_pending available StudentEnrollment],
          %w[creation_pending available TeacherEnrollment],
          %w[creation_pending claimed StudentEnrollment],
          %w[creation_pending claimed TeacherEnrollment],
          %w[invited available StudentEnrollment],
          %w[invited available TeacherEnrollment],
          %w[invited claimed StudentEnrollment],
          %w[invited claimed TeacherEnrollment],
          %w[active available StudentEnrollment]
        )
      end

      context "with strict_checks:true" do
        let(:options) { { strict_checks: true } }

        it "returns sensible defaults" do
          result = enrollments.where(conditions)
          expect(matches_for(result)).to eq [
            %w[invited available StudentEnrollment],
            %w[invited available TeacherEnrollment],
            %w[invited claimed TeacherEnrollment]
          ]
        end

        it "returns invitations in published courses" do
          options[:course_workflow_state] = "available"
          result = enrollments("available").where(conditions)
          expect(matches_for(result)).to eq [
            %w[invited available StudentEnrollment],
            %w[invited available TeacherEnrollment]
          ]
        end

        it "returns invitations for admins in unpublished courses" do
          options[:course_workflow_state] = "claimed"
          result = enrollments("claimed").where(conditions)
          expect(matches_for(result)).to eq [
            %w[invited claimed TeacherEnrollment]
          ]
        end

        it "does not return anything if the course is deleted" do
          options[:course_workflow_state] = "deleted"
          expect(conditions).to be_nil
        end
      end

      context "with strict_checks:false" do
        let(:options) { { strict_checks: false } }

        it "returns sensible defaults" do
          options[:course_workflow_state] = "available"
          result = enrollments.where(conditions)
          expect(matches_for(result)).to eq [
            %w[creation_pending available StudentEnrollment],
            %w[creation_pending available TeacherEnrollment],
            %w[creation_pending claimed StudentEnrollment],
            %w[creation_pending claimed TeacherEnrollment],
            %w[invited available StudentEnrollment],
            %w[invited available TeacherEnrollment],
            %w[invited claimed StudentEnrollment],
            %w[invited claimed TeacherEnrollment]
          ]
        end

        it "does not return anything if the course is deleted" do
          options[:course_workflow_state] = "deleted"
          expect(conditions).to be_nil
        end
      end

      it_behaves_like "enforce_course_workflow_state"
    end

    %i[deleted rejected completed creation_pending inactive].each do |state|
      context "with #{state.inspect}" do
        let(:state) { state }

        it "only returns #{state} enrollments" do
          create_enrollments(
            %w[active available StudentEnrollment],
            [state.to_s, "available", "StudentEnrollment"]
          )

          result = enrollments.where(conditions)
          expect(result).to be_present
          expect(matches_for(result)).to eq [
            [state.to_s, "available", "StudentEnrollment"]
          ]
        end

        it_behaves_like "enforce_course_workflow_state"
      end
    end

    context "with :current_and_invited" do
      let(:state) { :current_and_invited }

      it "returns sensible defaults" do
        create_enrollments(
          %w[active available StudentEnrollment],
          %w[active available TeacherEnrollment],
          %w[active claimed StudentEnrollment],
          %w[active claimed TeacherEnrollment],
          %w[invited available StudentEnrollment],
          %w[invited available TeacherEnrollment],
          %w[invited claimed StudentEnrollment],
          %w[invited claimed TeacherEnrollment],
          %w[creation_pending available StudentEnrollment]
        )

        result = enrollments.where(conditions)
        expect(matches_for(result)).to eq [
          %w[active available StudentEnrollment],
          %w[active available TeacherEnrollment],
          %w[active claimed TeacherEnrollment],
          %w[invited available StudentEnrollment],
          %w[invited available TeacherEnrollment],
          %w[invited claimed TeacherEnrollment]
        ]
      end
    end

    context "with :current_and_future" do
      let(:state) { :current_and_future }

      it "returns sensible defaults" do
        create_enrollments(
          %w[active available StudentEnrollment],
          %w[active available TeacherEnrollment],
          %w[active claimed StudentEnrollment],
          %w[active claimed TeacherEnrollment],
          %w[invited available StudentEnrollment],
          %w[invited available TeacherEnrollment],
          %w[invited claimed StudentEnrollment],
          %w[invited claimed TeacherEnrollment],
          %w[creation_pending available StudentEnrollment]
        )

        result = enrollments.where(conditions)
        expect(matches_for(result)).to eq [
          %w[active available StudentEnrollment],
          %w[active available TeacherEnrollment],
          %w[active claimed StudentEnrollment], # students can see that they have an active enrollment in an unpublished course
          %w[active claimed TeacherEnrollment],
          %w[invited available StudentEnrollment],
          %w[invited available TeacherEnrollment],
          %w[invited claimed TeacherEnrollment]
        ]
      end
    end

    context "with :current_and_concluded" do
      let(:state) { :current_and_concluded }

      it "returns sensible defaults" do
        create_enrollments(
          %w[active available StudentEnrollment],
          %w[active available TeacherEnrollment],
          %w[active claimed StudentEnrollment],
          %w[active claimed TeacherEnrollment],
          %w[invited available StudentEnrollment],
          %w[completed available StudentEnrollment]
        )

        result = enrollments.where(conditions)
        expect(matches_for(result)).to eq [
          %w[active available StudentEnrollment],
          %w[active available TeacherEnrollment],
          %w[active claimed TeacherEnrollment],
          %w[completed available StudentEnrollment]
        ]
      end
    end
  end
end
