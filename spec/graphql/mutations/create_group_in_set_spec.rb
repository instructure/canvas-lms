#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Mutations::CreateGroupInSet do
  before(:once) do
    student_in_course(active_all: true)
    @gc = @course.group_categories.create! name: "asdf"
  end

  def mutation_str(name: "zxcv", group_set_id: nil)
    group_set_id ||= @gc.id
    <<~GQL
      mutation {
        createGroupInSet(input: {
          name: "#{name}"
          groupSetId: "#{group_set_id}"
        }) {
          group {
            _id
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

    new_group_id = result.dig(*%w[data createGroupInSet group _id])
    expect(Group.find(new_group_id).name).to eq "zxcv"

    expect(result.dig(*%w[data createGroupInSet errors])).to be_nil
  end

  it "fails gracefully for invalid group sets" do
    invalid_group_set_id = 111111111111111111
    result = CanvasSchema.execute(mutation_str(group_set_id: invalid_group_set_id), context: {current_user: @student})
    expect(result["errors"]).not_to be_nil
    expect(result.dig(*%w[data createGroupInSet])).to be_nil
  end

  it "requires permission" do
    result = CanvasSchema.execute(mutation_str, context: {current_user: @student})
    expect(result["errors"]).not_to be_nil
    expect(result.dig(*%w[data createGroupInSet])).to be_nil
  end

  context "validation errors" do
    it "returns validation errors" do
      result = CanvasSchema.execute(
        mutation_str(name: "!" * (Group.maximum_string_length + 1)),
        context: {current_user: @teacher}
      )

      # top-level errors are nil since this is a user error
      expect(result["errors"]).to be_nil

      validation_errors = result.dig(*%w[data createGroupInSet errors])
      expect(validation_errors.size).to eq 1
      expect(validation_errors[0]["attribute"]).to eq "name"
      expect(validation_errors[0]["message"]).to_not be_nil

      expect(result.dig("data", "createGroupInSet", "group")).to be_nil
    end
  end
end
