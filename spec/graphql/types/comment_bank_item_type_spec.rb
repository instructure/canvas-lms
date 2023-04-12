# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Types::CommentBankItemType do
  before(:once) do
    account_admin_user
    @item = comment_bank_item_model(user: @admin)
  end

  let(:item_type) { GraphQLTypeTester.new(@item, current_user: @admin) }

  it "resolves" do
    expect(item_type.resolve("_id")).to eq @item.id.to_s
    expect(item_type.resolve("comment")).to eq @item.comment
    expect(item_type.resolve("courseId")).to eq @item.course_id.to_s
    expect(item_type.resolve("userId")).to eq @item.user_id.to_s
  end

  it "requires read permission on record" do
    expect(item_type.resolve("_id", current_user: user_model)).to be_nil
  end
end
