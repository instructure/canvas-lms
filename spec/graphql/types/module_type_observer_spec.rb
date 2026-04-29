# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Types::ModuleType do
  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end
  let_once(:student) { @student }
  let_once(:teacher) { @teacher }

  let_once(:observer) do
    user_factory(active_all: true).tap do |user|
      course.enroll_user(user, "ObserverEnrollment", associated_user_id: student.id)
    end
  end

  let_once(:context_module) do
    course.context_modules.create!(name: "Test Module")
  end

  describe "observer functionality" do
    context "nil current_user safety" do
      it "returns empty hash for submission_statistics with nil current_user" do
        module_type = GraphQLTypeTester.new(context_module, current_user: nil)

        # Mock the loader to ensure it's not called
        expect(Loaders::ModuleStatisticsLoader).not_to receive(:for)
        expect(Loaders::ObserverModuleStatisticsLoader).not_to receive(:for)

        result = module_type.resolve("submissionStatistics { latestDueAt }")
        expect(result).to be_nil
      end

      it "returns nil for progression with nil current_user" do
        module_type = GraphQLTypeTester.new(context_module, current_user: nil)

        # Mock the loader to ensure it's not called
        expect(ModuleProgressionLoader).not_to receive(:for)
        expect(Loaders::ObserverModuleProgressionLoader).not_to receive(:for)

        result = module_type.resolve("progression { _id }")
        expect(result).to be_nil
      end
    end

    context "observer detection consistency" do
      it "uses observer loader for submission_statistics when user is observer with observed students" do
        module_type = GraphQLTypeTester.new(context_module, current_user: observer)

        # Mock ObserverEnrollment to return observed students
        allow(ObserverEnrollment).to receive(:observed_students)
          .with(course, observer, include_restricted_access: false)
          .and_return({ student => [double] })

        # Expect observer loader to be called
        observer_loader = instance_double(Loaders::ObserverModuleStatisticsLoader)
        allow(Loaders::ObserverModuleStatisticsLoader).to receive(:for)
          .with(current_user: observer, request: nil)
          .and_return(observer_loader)
        allow(observer_loader).to receive(:load).with(context_module).and_return({})

        # Ensure regular loader is NOT called
        expect(Loaders::ModuleStatisticsLoader).not_to receive(:for)

        module_type.resolve("submissionStatistics { latestDueAt }")
      end

      it "uses observer loader for progression when user is observer with observed students" do
        module_type = GraphQLTypeTester.new(context_module, current_user: observer)

        # Mock ObserverEnrollment to return observed students
        allow(ObserverEnrollment).to receive(:observed_students)
          .with(course, observer, include_restricted_access: false)
          .and_return({ student => [double] })

        # Expect observer loader to be called
        observer_loader = instance_double(Loaders::ObserverModuleProgressionLoader)
        allow(Loaders::ObserverModuleProgressionLoader).to receive(:for)
          .with(current_user: observer, session: nil, request: nil)
          .and_return(observer_loader)
        allow(observer_loader).to receive(:load).with(context_module).and_return(nil)

        # Ensure regular loader is NOT called
        expect(ModuleProgressionLoader).not_to receive(:for)

        module_type.resolve("progression { _id }")
      end

      it "uses regular loader for submission_statistics when user is observer without observed students" do
        # Create observer with no observed students
        observer_no_students = user_factory(active_all: true).tap do |user|
          course.enroll_user(user, "ObserverEnrollment")
        end

        module_type = GraphQLTypeTester.new(context_module, current_user: observer_no_students)

        # Mock ObserverEnrollment to return empty hash (no observed students)
        allow(ObserverEnrollment).to receive(:observed_students)
          .with(course, observer_no_students, include_restricted_access: false)
          .and_return({})

        # Expect regular loader to be called
        regular_loader = instance_double(Loaders::ModuleStatisticsLoader)
        allow(Loaders::ModuleStatisticsLoader).to receive(:for)
          .with(current_user: observer_no_students)
          .and_return(regular_loader)
        allow(regular_loader).to receive(:load).with(context_module).and_return({})

        # Ensure observer loader is NOT called
        expect(Loaders::ObserverModuleStatisticsLoader).not_to receive(:for)

        module_type.resolve("submissionStatistics { latestDueAt }")
      end

      it "uses regular loader for progression when user is observer without observed students" do
        # Create observer with no observed students
        observer_no_students = user_factory(active_all: true).tap do |user|
          course.enroll_user(user, "ObserverEnrollment")
        end

        module_type = GraphQLTypeTester.new(context_module, current_user: observer_no_students)

        # Mock ObserverEnrollment to return empty hash (no observed students)
        allow(ObserverEnrollment).to receive(:observed_students)
          .with(course, observer_no_students, include_restricted_access: false)
          .and_return({})

        # Expect regular loader to be called
        regular_loader = instance_double(ModuleProgressionLoader)
        allow(ModuleProgressionLoader).to receive(:for)
          .with(observer_no_students, nil, course)
          .and_return(regular_loader)
        allow(regular_loader).to receive(:load).with(context_module).and_return(nil)

        # Ensure observer loader is NOT called
        expect(Loaders::ObserverModuleProgressionLoader).not_to receive(:for)

        module_type.resolve("progression { _id }")
      end

      it "uses regular loader for students" do
        module_type = GraphQLTypeTester.new(context_module, current_user: student)

        # Mock ObserverEnrollment to confirm student has no observed students
        allow(ObserverEnrollment).to receive(:observed_students)
          .with(course, student, include_restricted_access: false)
          .and_return({})

        # Expect regular loaders to be called
        stats_loader = instance_double(Loaders::ModuleStatisticsLoader)
        allow(Loaders::ModuleStatisticsLoader).to receive(:for)
          .with(current_user: student)
          .and_return(stats_loader)
        allow(stats_loader).to receive(:load).with(context_module).and_return({})

        progression_loader = instance_double(ModuleProgressionLoader)
        allow(ModuleProgressionLoader).to receive(:for)
          .with(student, nil, course)
          .and_return(progression_loader)
        allow(progression_loader).to receive(:load).with(context_module).and_return(nil)

        # Ensure observer loaders are NOT called
        expect(Loaders::ObserverModuleStatisticsLoader).not_to receive(:for)
        expect(Loaders::ObserverModuleProgressionLoader).not_to receive(:for)

        module_type.resolve("submissionStatistics { latestDueAt }")
        module_type.resolve("progression { _id }")
      end
    end

    context "DRY observer detection validation" do
      it "uses consistent observer detection logic for both methods" do
        # Mock ObserverEnrollment to return observed students for both calls
        allow(ObserverEnrollment).to receive(:observed_students)
          .with(course, observer, include_restricted_access: false)
          .and_return({ student => [double] }).twice

        # Mock the loaders to prevent actual GraphQL execution
        observer_stats_loader = instance_double(Loaders::ObserverModuleStatisticsLoader)
        allow(Loaders::ObserverModuleStatisticsLoader).to receive(:for)
          .with(current_user: observer, request: nil)
          .and_return(observer_stats_loader)
        allow(observer_stats_loader).to receive(:load).with(context_module).and_return({})

        observer_progression_loader = instance_double(Loaders::ObserverModuleProgressionLoader)
        allow(Loaders::ObserverModuleProgressionLoader).to receive(:for)
          .with(current_user: observer, session: nil, request: nil)
          .and_return(observer_progression_loader)
        allow(observer_progression_loader).to receive(:load).with(context_module).and_return(nil)

        # Ensure regular loaders are NOT called for either method
        expect(Loaders::ModuleStatisticsLoader).not_to receive(:for)
        expect(ModuleProgressionLoader).not_to receive(:for)

        module_type = GraphQLTypeTester.new(context_module, current_user: observer)

        # Both methods should use observer loaders due to consistent observer detection
        module_type.resolve("submissionStatistics { latestDueAt }")
        module_type.resolve("progression { _id }")
      end
    end
  end
end
