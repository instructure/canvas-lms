# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Loaders::DiscussionEntryUserLoader do
  before(:once) do
    @student1 = user_factory(active_all: true, active_state: "active", name: "Student Name", short_name: "Student", id: 1)
    @student2 = user_factory(active_all: true, active_state: "active", name: "Student Name", short_name: nil, id: 2)
    @student3 = user_factory(active_all: true, active_state: "active", name: "Student Name3", short_name: "Student3", id: 1)
    @student4 = user_factory(active_all: true, active_state: "active", name: "Student Name4", short_name: "Student4", id: 1)
  end

  it "give back the id and short_name when short_name is present" do
    GraphQL::Batch.batch do
      discussion_entry_user_loader = Loaders::DiscussionEntryUserLoader.load_many([@student1.id]).sync
      expect(discussion_entry_user_loader.first.name).to match "Student"
    end
  end

  it "give back the id and short_name when short_name is present for more user" do
    GraphQL::Batch.batch do
      discussion_entry_user_loader = Loaders::DiscussionEntryUserLoader.load_many([@student1.id, @student3.id, @student4.id]).sync
      expect(discussion_entry_user_loader.map(&:name)).to match_array(%w[Student Student3 Student4])
    end
  end

  it "give back the id and name when short_name is not present" do
    GraphQL::Batch.batch do
      discussion_entry_user_loader = Loaders::DiscussionEntryUserLoader.load_many([@student2.id]).sync
      expect(discussion_entry_user_loader.first.name).to match "Student Name"
    end
  end
end
