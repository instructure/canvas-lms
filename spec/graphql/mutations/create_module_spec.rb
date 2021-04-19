# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require 'spec_helper'
require_relative "../graphql_spec_helper"

describe Mutations::CreateModule do
  before(:once) do
    course_factory(active_all: true)
  end

  def mutation_str(name: "zxcv", course_id: nil)
    course_id ||= @course.id
    <<~GQL
      mutation {
        createModule(input: {
          name: "#{name}"
          courseId: "#{course_id}"
        }) {
          module {
            _id
            name
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  it "works" do
    result = CanvasSchema.execute(mutation_str, context: {current_user: @teacher})
    expect(result.dig(*%w[data createModule module name])).to eq 'zxcv'
    new_module_id = result.dig(*%w[data createModule module _id])
    expect(@course.context_modules.find(new_module_id).name).to eq 'zxcv'
    expect(result.dig(*%w[data createModule errors])).to be_nil
  end

  it "requires non-empty name" do
    result = CanvasSchema.execute(mutation_str(name: ''), context: {current_user: @teacher})
    expect(result.dig('data', 'createModule', 'errors')[0]['message']).to eq "can't be blank"
  end

  it "fails gracefully for invalid course id" do
    invalid_course_id = 0
    result = CanvasSchema.execute(mutation_str(course_id: invalid_course_id), context: {current_user: @teacher})
    expect(result["errors"]).not_to be_nil
    expect(result.dig(*%w[data createModule])).to be_nil
  end

  it "requires permission" do
    student_in_course
    result = CanvasSchema.execute(mutation_str, context: {current_user: @student})
    expect(result["errors"]).not_to be_nil
    expect(result.dig(*%w[data createModule])).to be_nil
  end
end
