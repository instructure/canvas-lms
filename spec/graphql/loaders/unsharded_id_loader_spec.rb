# frozen_string_literal: true

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

describe Loaders::UnshardedIDLoader do
  let(:setting) { Setting.create!(name: "number_of_M1s", value: "infinity") }
  let(:setting_loader) { Loaders::UnshardedIDLoader.for(Setting) }

  it "loads un-sharded records" do
    GraphQL::Batch.batch do
      setting_loader.load(setting.id).then do |internal_setting|
        expect(internal_setting).to eq setting
      end
    end
  end

  it "returns nil for nonexistent records" do
    GraphQL::Batch.batch do
      setting_loader.load(-1).then do |internal_setting|
        expect(internal_setting).to be_nil
      end
    end
  end
end
