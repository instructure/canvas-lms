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
require_relative "../../../app/graphql/types/module_type"

describe ModuleProgressionLoader do
  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end
  let_once(:teacher) { course_with_teacher(course:, active_all: true).user }
  let_once(:student) { @student }
  let_once(:other_course) { Course.create! }

  let_once(:enrolled_module) { course.context_modules.create!(name: "Enrolled Module") }
  let_once(:unenrolled_module) { other_course.context_modules.create!(name: "Unenrolled Module") }

  def with_query_counter
    @query_count = 0
    original_method = ActiveRecord::Base.connection.method(:execute)

    allow(ActiveRecord::Base.connection).to receive(:execute) do |sql|
      @query_count += 1 unless sql.match?(/^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/)
      original_method.call(sql)
    end

    yield
  ensure
    RSpec::Mocks.space.reset_all
  end

  describe "#get_enrolled_modules" do
    let(:loader) { ModuleProgressionLoader.new(student, nil, course) }

    context "with mixed enrolled and unenrolled modules" do
      let(:modules) { [enrolled_module, unenrolled_module] }

      it "returns only enrolled modules using database query" do
        enrolled_modules_relation = loader.send(:get_enrolled_modules, modules)
        expect(enrolled_modules_relation).to be_a(ActiveRecord::Relation)
        expect(enrolled_modules_relation.to_a).to eq [enrolled_module]
        expect(enrolled_modules_relation.to_a).not_to include(unenrolled_module)
      end

      it "uses efficient database query instead of loading enrollments into memory" do
        with_query_counter do
          loader.send(:get_enrolled_modules, modules)

          # Should use a single JOIN query instead of loading all enrollments
          # The exact count may vary, but should be minimal (typically 1-2 queries)
          expect(@query_count).to be <= 2
        end
      end

      it "handles empty module list" do
        enrolled_modules_relation = loader.send(:get_enrolled_modules, [])
        expect(enrolled_modules_relation).to be_a(ActiveRecord::Relation)
        expect(enrolled_modules_relation.to_a).to eq []
      end

      it "handles case where user is not enrolled in any modules" do
        unenrolled_user = User.create!
        unenrolled_loader = ModuleProgressionLoader.new(unenrolled_user, nil, course)

        enrolled_modules_relation = unenrolled_loader.send(:get_enrolled_modules, [enrolled_module])
        expect(enrolled_modules_relation).to be_a(ActiveRecord::Relation)
        expect(enrolled_modules_relation.to_a).to eq []
      end
    end

    context "with no user" do
      let(:no_user_loader) { ModuleProgressionLoader.new(nil, nil, course) }

      it "returns empty relation when user is nil" do
        enrolled_modules_relation = no_user_loader.send(:get_enrolled_modules, [enrolled_module])
        expect(enrolled_modules_relation).to be_a(ActiveRecord::Relation)
        expect(enrolled_modules_relation.to_a).to eq []
      end
    end

    context "with no context" do
      let(:no_context_loader) { ModuleProgressionLoader.new(student, nil, nil) }

      it "returns empty relation when context is nil" do
        enrolled_modules_relation = no_context_loader.send(:get_enrolled_modules, [enrolled_module])
        expect(enrolled_modules_relation).to be_a(ActiveRecord::Relation)
        expect(enrolled_modules_relation.to_a).to eq []
      end
    end
  end

  describe "#batch_create_progressions" do
    let(:loader) { ModuleProgressionLoader.new(student, nil, course) }

    context "with enrolled modules" do
      it "creates progressions for enrolled modules" do
        enrolled_relation = ContextModule.where(id: enrolled_module.id)
        expect do
          loader.send(:batch_create_progressions, enrolled_relation)
        end.to change { ContextModuleProgression.count }.by(1)

        progression = ContextModuleProgression.find_by(user: student, context_module: enrolled_module)
        expect(progression).to be_present
      end

      it "handles empty module list" do
        empty_relation = ContextModule.none
        expect do
          loader.send(:batch_create_progressions, empty_relation)
        end.not_to change { ContextModuleProgression.count }
      end

      it "handles duplicate progression creation gracefully" do
        # Create initial progression
        ContextModuleProgression.create!(user: student, context_module: enrolled_module)
        initial_count = ContextModuleProgression.count

        # Attempt to create again - should not fail or create duplicates
        enrolled_relation = ContextModule.where(id: enrolled_module.id)
        expect do
          loader.send(:batch_create_progressions, enrolled_relation)
        end.not_to change { ContextModuleProgression.count }.from(initial_count)
      end

      it "activates correct shard for each module" do
        enrolled_relation = ContextModule.where(id: enrolled_module.id)
        expect(enrolled_module.shard).to receive(:activate).at_least(:once).and_yield
        loader.send(:batch_create_progressions, enrolled_relation)
      end
    end

    context "with no user" do
      let(:no_user_loader) { ModuleProgressionLoader.new(nil, nil, course) }

      it "does not create progressions when user is nil" do
        enrolled_relation = ContextModule.where(id: enrolled_module.id)
        expect do
          no_user_loader.send(:batch_create_progressions, enrolled_relation)
        end.not_to change { ContextModuleProgression.count }
      end
    end
  end

  describe "#perform" do
    let(:loader) { ModuleProgressionLoader.new(student, nil, course) }

    context "for student users" do
      it "batches progression creation to avoid N+1 queries" do
        modules = [enrolled_module]

        expect(loader).to receive(:get_enrolled_modules).with(modules).and_call_original
        expect(loader).to receive(:batch_create_progressions).and_call_original

        GraphQL::Batch.batch do
          loader.load(enrolled_module)
        end
      end

      it "evaluates modules after creating progressions" do
        expect(enrolled_module).to receive(:evaluate_for).with(student)

        GraphQL::Batch.batch do
          loader.load(enrolled_module)
        end
      end

      it "fulfills with correct progressions" do
        progression = nil

        GraphQL::Batch.batch do
          loader.load(enrolled_module).then do |result|
            progression = result
          end
        end

        expect(progression).to be_a(ContextModuleProgression)
        expect(progression.user).to eq student
        expect(progression.context_module).to eq enrolled_module
      end
    end

    context "for non-student users" do
      let(:teacher_loader) { ModuleProgressionLoader.new(teacher, nil, course) }

      it "does not create progressions for teachers" do
        expect(teacher_loader).not_to receive(:get_enrolled_modules)
        expect(teacher_loader).not_to receive(:batch_create_progressions)
        expect(enrolled_module).not_to receive(:evaluate_for)

        GraphQL::Batch.batch do
          teacher_loader.load(enrolled_module)
        end
      end
    end

    context "performance testing" do
      let(:modules) { Array.new(5) { course.context_modules.create!(name: "Module #{rand(1000)}") } }

      it "uses efficient database queries for multiple modules" do
        with_query_counter do
          GraphQL::Batch.batch do
            modules.each { |mod| loader.load(mod) }
          end

          # Should use batched queries, not individual queries per module
          # Exact count may vary but should be reasonable for batched operations
          expect(@query_count).to be <= modules.count * 2
        end
      end
    end
  end
end
