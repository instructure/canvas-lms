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

describe Loaders::DatesOverridableLoader do
  before(:once) do
    course = course_factory(active_all: true)
    @assignment1 = course.assignments.create!(title: "Assignment 1")
    @assignment2 = course.assignments.create!(title: "Assignment 2")
  end

  it "calls preload_override_data_for_objects once for the entire batch, not per assignment" do
    expect(DatesOverridable).to receive(:preload_override_data_for_objects)
      .with([@assignment1, @assignment2])
      .once
      .and_call_original

    GraphQL::Batch.batch do
      loader = Loaders::DatesOverridableLoader.new
      loader.load(@assignment1)
      loader.load(@assignment2)
    end
  end

  it "fulfills each assignment with itself" do
    GraphQL::Batch.batch do
      loader = Loaders::DatesOverridableLoader.new

      loader.load(@assignment1).then do |result|
        expect(result).to be(@assignment1)
      end

      loader.load(@assignment2).then do |result|
        expect(result).to be(@assignment2)
      end
    end
  end

  it "sets preloaded override data on the returned assignment objects" do
    GraphQL::Batch.batch do
      loader = Loaders::DatesOverridableLoader.new

      loader.load(@assignment1).then do |result|
        expect(result.preloaded_overrides).not_to be_nil
        expect(result.preloaded_module_ids).not_to be_nil
        expect(result.preloaded_module_overrides).not_to be_nil
      end
    end
  end
end
