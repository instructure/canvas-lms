# frozen_string_literal: true

#
# Copyright (C) 2018 Instructure, Inc.
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

require_relative "graphql_spec_helper"

describe "graphql pg statement_timeouts" do
  before(:once) do
    course_with_student(active_all: true)
  end

  let(:query) { %|query { course(id: "#{@course.id}") { name } }| }
  let(:mutation) { %|mutation { updateAssignment(input: {id: "1"}) { assignment { name } } }| }

  def make_stuff_slow
    allow_any_instance_of(Course).to receive(:name) {
      ActiveRecord::Base.connection.execute("SELECT pg_sleep(0.002)")
      "asdf"
    }

    allow(Assignment).to receive(:find) {
      ActiveRecord::Base.connection.execute("SELECT pg_sleep(0.002)")
      raise ActiveRecord::RecordNotFound
    }
  end

  context "mutations" do
    it "works when fast" do
      make_stuff_slow
      expect do
        CanvasSchema.execute(mutation, context: { current_user: @teacher })
      end.not_to raise_error
    end

    it "fails when slow" do
      make_stuff_slow
      Setting.set("graphql_statement_timeout", 1)
      result = CanvasSchema.execute(mutation, context: { current_user: @teacher })
      expect(result.dig("data", "updateAssignment")).to be_nil
      expect(result.dig("errors", 0, "path")).to eq ["updateAssignment"]
    end
  end
end
