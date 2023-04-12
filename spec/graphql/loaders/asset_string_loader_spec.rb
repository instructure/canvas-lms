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

describe Loaders::AssetStringLoader do
  before(:once) do
    @course1 = Course.create! name: "asdf"
    @course2 = Course.create! name: "asdf"
    @assignment = @course1.assignments.create! name: "asdf"
  end

  around do |example|
    @query_count = 0
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do
      @query_count += 1
    end

    example.run

    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  it "batch loads" do
    expect do
      GraphQL::Batch.batch do
        Loaders::AssetStringLoader.load(@course1.asset_string).then do |course|
          expect(course).to eq @course1
        end
        Loaders::AssetStringLoader.load(@course2.asset_string).then do |course|
          expect(course).to eq @course2
        end
        Loaders::AssetStringLoader.load(@assignment.asset_string).then do |assignment|
          expect(assignment).to eq @assignment
        end
      end
    end.to change { @query_count }.by(2)
  end

  it "fulfills with nil if target is not found" do
    GraphQL::Batch.batch do
      Loaders::AssetStringLoader.load("random_1").then do |target|
        expect(target).to be_nil
      end
    end
  end
end
