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

require_relative "../../spec_helper"

describe Loaders::CourseModuleProgressionDataLoader do
  before :once do
    course_with_student(active_all: true)
  end

  def with_batch_loader
    GraphQL::Batch.batch do
      yield Loaders::CourseModuleProgressionDataLoader.for(current_user: @student)
    end
  end

  describe "#perform" do
    context "with module progressions" do
      before :once do
        @module1 = @course.context_modules.create!(name: "Module 1")
        @module2 = @course.context_modules.create!(name: "Module 2")
        @progression1 = @module1.context_module_progressions.create!(
          user: @student,
          workflow_state: "completed",
          current: true,
          evaluated_at: 1.hour.ago
        )
        @progression2 = @module2.context_module_progressions.create!(
          user: @student,
          workflow_state: "started",
          current: true,
          evaluated_at: 1.hour.ago
        )
      end

      it "loads progressions for a course" do
        progressions = with_batch_loader { |loader| loader.load(@course) }
        expect(progressions.map(&:id)).to match_array([@progression1.id, @progression2.id])
      end

      it "includes progressions with different workflow states" do
        progressions = with_batch_loader { |loader| loader.load(@course) }
        expect(progressions.map(&:workflow_state)).to match_array(["completed", "started"])
      end
    end

    context "with no progressions" do
      it "returns empty array for course with no modules" do
        progressions = with_batch_loader { |loader| loader.load(@course) }
        expect(progressions).to eq([])
      end
    end

    context "with no current user" do
      it "returns empty array" do
        result = GraphQL::Batch.batch do
          loader = Loaders::CourseModuleProgressionDataLoader.for(current_user: nil)
          loader.load(@course)
        end
        expect(result).to eq([])
      end
    end

    context "with multiple courses" do
      before :once do
        @original_course = @course
        course_factory(active_all: true)
        @course2 = @course
        @course = @original_course
        @course2.enroll_student(@student, enrollment_state: "active")

        @module1 = @course.context_modules.create!(name: "Course 1 Module")
        @module2 = @course2.context_modules.create!(name: "Course 2 Module")
        @progression1 = @module1.context_module_progressions.create!(
          user: @student,
          workflow_state: "completed",
          current: true,
          evaluated_at: 1.hour.ago
        )
        @progression2 = @module2.context_module_progressions.create!(
          user: @student,
          workflow_state: "started",
          current: true,
          evaluated_at: 1.hour.ago
        )
      end

      it "groups progressions by course" do
        GraphQL::Batch.batch do
          loader = Loaders::CourseModuleProgressionDataLoader.for(current_user: @student)

          loader.load(@course).then do |progressions1|
            expect(progressions1.map(&:id)).to eq([@progression1.id])
            expect(progressions1.map(&:id)).not_to include(@progression2.id)
          end

          loader.load(@course2).then do |progressions2|
            expect(progressions2.map(&:id)).to eq([@progression2.id])
            expect(progressions2.map(&:id)).not_to include(@progression1.id)
          end
        end
      end

      it "batches queries efficiently" do
        query_count = 0
        counter = ->(*) { query_count += 1 }

        ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
          GraphQL::Batch.batch do
            loader = Loaders::CourseModuleProgressionDataLoader.for(current_user: @student)
            loader.load(@course)
            loader.load(@course2)
          end
        end

        expect(query_count).to be <= 2
      end
    end

    context "filtering by current and evaluated_at" do
      before :once do
        @module1 = @course.context_modules.create!(name: "Module 1")
        @module2 = @course.context_modules.create!(name: "Module 2")
        @module3 = @course.context_modules.create!(name: "Module 3")
        @module4 = @course.context_modules.create!(name: "Module 4")

        @progression1 = @module1.context_module_progressions.create!(
          user: @student,
          workflow_state: "completed",
          current: true,
          evaluated_at: 1.hour.ago
        )
        @progression2 = @module2.context_module_progressions.create!(
          user: @student,
          workflow_state: "started",
          current: false,
          evaluated_at: 1.day.ago
        )
        @progression3 = @module3.context_module_progressions.create!(
          user: @student,
          workflow_state: "locked",
          current: false,
          evaluated_at: nil
        )
        @progression4 = @module4.context_module_progressions.create!(
          user: @student,
          workflow_state: "unlocked",
          current: true,
          evaluated_at: nil
        )
      end

      it "includes progressions with current=true" do
        progressions = with_batch_loader { |loader| loader.load(@course) }
        expect(progressions.map(&:id)).to include(@progression1.id)
      end

      it "includes progressions with evaluated_at set (even if current=false)" do
        progressions = with_batch_loader { |loader| loader.load(@course) }
        expect(progressions.map(&:id)).to include(@progression2.id)
      end

      it "excludes progressions with current=false and evaluated_at=nil" do
        progressions = with_batch_loader { |loader| loader.load(@course) }
        expect(progressions.map(&:id)).not_to include(@progression3.id)
      end

      it "includes progressions with current=true even if evaluated_at=nil" do
        progressions = with_batch_loader { |loader| loader.load(@course) }
        expect(progressions.map(&:id)).to include(@progression4.id)
      end

      it "loads correct count of filtered progressions" do
        progressions = with_batch_loader { |loader| loader.load(@course) }
        expect(progressions.length).to eq(3)
      end
    end
  end
end
