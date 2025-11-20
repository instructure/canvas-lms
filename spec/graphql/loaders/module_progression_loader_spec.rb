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

  describe "#perform" do
    let(:loader) { ModuleProgressionLoader.new(student, nil, course) }

    context "for student users" do
      it "preloads progressions to avoid N+1 queries" do
        modules = [enrolled_module]

        expect(ContextModule).to receive(:preload_progressions_for_user).with(modules, student).and_call_original

        GraphQL::Batch.batch do
          loader.load(enrolled_module)
        end
      end

      it "evaluates modules without progressions using evaluate_for" do
        expect(enrolled_module).to receive(:evaluate_for).with(student)

        GraphQL::Batch.batch do
          loader.load(enrolled_module)
        end
      end

      it "evaluates existing progressions using evaluate!" do
        enrolled_module.evaluate_for(student)

        expect_any_instance_of(ContextModuleProgression).to receive(:evaluate!)
        expect(enrolled_module).not_to receive(:evaluate_for)

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

      it "does not evaluate progressions for teachers" do
        expect(ContextModule).not_to receive(:preload_progressions_for_user)
        expect(enrolled_module).not_to receive(:evaluate_for)

        GraphQL::Batch.batch do
          teacher_loader.load(enrolled_module)
        end
      end
    end

    context "performance testing" do
      let(:modules) { Array.new(5) { course.context_modules.create!(name: "Module #{rand(1000)}") } }

      it "uses efficient database queries for multiple modules" do
        modules.each { |mod| mod.evaluate_for(student) }

        with_query_counter do
          GraphQL::Batch.batch do
            modules.each { |mod| loader.load(mod) }
          end

          expect(@query_count).to be <= 10
        end
      end

      it "does not trigger N+1 queries when loading progressions" do
        modules.each { |mod| mod.evaluate_for(student) }

        query_log = []
        allow(ActiveRecord::Base.connection).to receive(:exec_query).and_wrap_original do |method, *args|
          sql = args[0]
          query_log << sql if sql.include?("context_module_progressions") && sql.include?("WHERE")
          method.call(*args)
        end

        GraphQL::Batch.batch do
          modules.each { |mod| loader.load(mod) }
        end

        progression_queries = query_log.grep(/context_module_id.*=/)
        expect(progression_queries.count).to be <= 2
      end
    end
  end
end
