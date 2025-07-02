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

describe Loaders::ModuleActiveOverridesLoader do
  let_once(:course) do
    course = Course.create! name: "asdf"
    course
  end

  let_once(:mod1) { course.context_modules.create!(name: "module1") }
  let_once(:mod2) { course.context_modules.create!(name: "module2") }
  let_once(:mod3) { course.context_modules.create!(name: "module3") }

  around do |example|
    @query_count = 0
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      @query_count += 1 if /SELECT.*FROM.*assignment_overrides/i.match?(event.payload[:sql])
    end

    example.run

    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  it "batch loads and prevents N+1 queries" do
    AssignmentOverride.create!(context_module_id: mod1.id, workflow_state: "active")
    AssignmentOverride.create!(context_module_id: mod3.id, workflow_state: "active")
    AssignmentOverride.create!(context_module_id: mod2.id, workflow_state: "deleted")

    results = []
    expect do
      GraphQL::Batch.batch do
        loader = Loaders::ModuleActiveOverridesLoader.for
        loader.load(mod1).then { |result| results << result }
        loader.load(mod2).then { |result| results << result }
        loader.load(mod3).then { |result| results << result }
      end
    end.to change { @query_count }.by(1)

    expect(results).to match_array([true, false, true])
  end

  it "handles modules without overrides" do
    result = nil
    GraphQL::Batch.batch do
      loader = Loaders::ModuleActiveOverridesLoader.for
      loader.load(mod1).then { |res| result = res }
    end
    expect(result).to be false
  end

  it "only considers active overrides" do
    AssignmentOverride.create!(context_module_id: mod1.id, workflow_state: "deleted")
    AssignmentOverride.create!(context_module_id: mod1.id, workflow_state: "active")

    result = nil
    GraphQL::Batch.batch do
      loader = Loaders::ModuleActiveOverridesLoader.for
      loader.load(mod1).then { |res| result = res }
    end
    expect(result).to be true
  end
end
