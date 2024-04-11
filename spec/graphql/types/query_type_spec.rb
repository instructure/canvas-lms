# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::QueryType do
  it "works" do
    # set up courses, teacher, and enrollments
    test_course_1 = Course.create! name: "TEST"
    test_course_2 = Course.create! name: "TEST2"
    Course.create! name: "TEST3"

    teacher = user_factory(name: "Coolguy Mcgee")
    test_course_1.enroll_user(teacher, "TeacherEnrollment")
    test_course_2.enroll_user(teacher, "TeacherEnrollment")

    # this is a set of course ids to check against

    # get query_type.allCourses
    expect(
      CanvasSchema.execute(
        "{ allCourses { _id } }",
        context: { current_user: teacher }
      ).dig("data", "allCourses").pluck("_id")
    ).to match_array [test_course_1, test_course_2].map(&:to_param)
  end

  context "OutcomeCalculationMethod" do
    it "works" do
      @course = Course.create! name: "TEST"
      @admin = account_admin_user(account: @course.account)
      @calc_method = outcome_calculation_method_model(@course.account)

      expect(
        CanvasSchema.execute(
          "{ outcomeCalculationMethod(id: #{@calc_method.id}) { _id } }",
          context: { current_user: @admin }
        ).dig("data", "outcomeCalculationMethod", "_id")
      ).to eq @calc_method.id.to_s
    end
  end

  context "OutcomeProficiency" do
    it "works" do
      @course = Course.create! name: "TEST"
      @admin = account_admin_user(account: @course.account)
      @proficiency = outcome_proficiency_model(@course.account)

      expect(
        CanvasSchema.execute(
          "{ outcomeProficiency(id: #{@proficiency.id}) { _id } }",
          context: { current_user: @admin }
        ).dig("data", "outcomeProficiency", "_id")
      ).to eq @proficiency.id.to_s
    end
  end

  context "sisId" do
    let_once(:generic_sis_id) { "di_ecruos_sis" }
    let_once(:course) { Course.create!(name: "TEST", sis_source_id: generic_sis_id, account:) }
    let_once(:account) do
      acct = Account.default.sub_accounts.create!(name: "sub")
      acct.update!(sis_source_id: generic_sis_id)
      acct
    end
    let_once(:assignment) { course.assignments.create!(name: "test", sis_source_id: generic_sis_id) }
    let_once(:assignmentGroup) do
      assignment.assignment_group.update!(sis_source_id: generic_sis_id)
      assignment.assignment_group
    end
    let_once(:term) do
      course.enrollment_term.update!(sis_source_id: generic_sis_id)
      course.enrollment_term
    end
    let_once(:admin) { account_admin_user(account: Account.default) }

    %w[account course assignment assignmentGroup term].each do |type|
      it "doesn't allow searching #{type} when given both types of ids" do
        expect(
          CanvasSchema.execute("{#{type}(id: \"123\", sisId: \"123\") { id }}").dig("errors", 0, "message")
        ).to eq("Must specify exactly one of id or sisId")
      end

      it "allows searching #{type} by sisId" do
        original_object = send(type)
        expect(
          CanvasSchema.execute(%/{#{type}(sisId: "#{generic_sis_id}") { _id }}/, context: { current_user: admin })
          .dig("data", type, "_id")
        ).to eq(original_object.id.to_s)
      end
    end
  end

  context "LearningOutcome" do
    it "works" do
      @course = Course.create! name: "TEST"
      @admin = account_admin_user(account: @course.account)

      outcome_with_rubric(context: @course)

      expect(
        CanvasSchema.execute(
          "{ learningOutcome(id: #{@outcome.id}) { _id } }",
          context: { current_user: @admin }
        ).dig("data", "learningOutcome", "_id")
      ).to eq @outcome.id.to_s
    end
  end

  context "internalSetting" do
    before :once do
      @setting = Setting.create!(name: "sadmississippi_num_strands", value: 10)
    end

    context "as site admin" do
      before :once do
        @admin = site_admin_user
      end

      it "loads by id" do
        thing = CanvasSchema.execute("{internalSetting(id: #{@setting.id}) { name }}",
                                     context: { current_user: @admin })
        expect(thing["data"]).to eq({ "internalSetting" => { "name" => "sadmississippi_num_strands" } })
      end

      it "loads by name" do
        thing = CanvasSchema.execute('{internalSetting(name: "sadmississippi_num_strands") { _id }}',
                                     context: { current_user: @admin })
        expect(thing["data"]).to eq({ "internalSetting" => { "_id" => @setting.id.to_s } })
      end

      it "errors if neither is provided" do
        thing = CanvasSchema.execute("{internalSetting { _id }}",
                                     context: { current_user: @admin })
        expect(thing["errors"][0]["message"]).to eq "Must specify exactly one of id or name"
      end

      it "errors if both are provided" do
        thing = CanvasSchema.execute('{internalSetting(id: 5, name: "foo") { _id }}',
                                     context: { current_user: @admin })
        expect(thing["errors"][0]["message"]).to eq "Must specify exactly one of id or name"
      end
    end

    context "as non site admin" do
      before :once do
        @admin = account_admin_user
      end

      it "rejects by id" do
        thing = CanvasSchema.execute("{internalSetting(id: #{@setting.id}) { name }}",
                                     context: { current_user: @admin })
        expect(thing["data"]).to eq({ "internalSetting" => nil })
      end

      it "rejects by name" do
        thing = CanvasSchema.execute('{internalSetting(name: "sadmississippi_num_strands") { _id }}',
                                     context: { current_user: @admin })
        expect(thing["data"]).to eq({ "internalSetting" => nil })
      end
    end
  end

  context "submission" do
    before :once do
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user
      @assignment = @course.assignments.create!(name: "asdf", points_possible: 10)
    end

    let(:submission) { @assignment.submissions.find_by(user: @student1) }

    it "allows fetching the submission via ID as a teacher" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}) { _id } }",
          context: { current_user: @teacher }
        ).dig("data", "submission", "_id")
      ).to eq submission.id.to_s
    end

    it "allows fetching the submission via ID as the submission owner" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}) { _id } }",
          context: { current_user: @student1 }
        ).dig("data", "submission", "_id")
      ).to eq submission.id.to_s
    end

    it "does not allow fetching the submission via ID as a non-owner student" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}) { _id } }",
          context: { current_user: @student2 }
        ).dig("data", "submission")
      ).to be_nil
    end

    it "returns an error when fetching the submission via ID in combination with the assignment ID" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}, assignmentId: #{@assignment.id}) { _id } }",
          context: { current_user: @teacher }
        ).dig("errors", 0, "message")
      ).to eq "Must specify an id or an assignment_id and user_id"
    end

    it "returns an error when fetching the submission via ID in combination with the user ID" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}, userId: #{@student1.id}) { _id } }",
          context: { current_user: @teacher }
        ).dig("errors", 0, "message")
      ).to eq "Must specify an id or an assignment_id and user_id"
    end

    it "returns an error when not providing an id or assignment_id and user_id" do
      expect(
        CanvasSchema.execute(
          "{ submission { _id } }",
          context: { current_user: @teacher }
        ).dig("errors", 0, "message")
      ).to eq "Must specify an id or an assignment_id and user_id"
    end
  end
end
