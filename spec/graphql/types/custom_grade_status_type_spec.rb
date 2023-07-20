# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe Types::CustomGradeStatusType do
  before(:once) do
    teacher_in_course(active_all: true)
    @admin = account_admin_user(account: @account)
  end

  let(:custom_grade_status) { CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @teacher) }
  let(:custom_grade_status_type) { GraphQLTypeTester.new(custom_grade_status, current_user: @admin) }

  it "works" do
    expect(custom_grade_status_type.resolve(:name)).to eq custom_grade_status.name
    expect(custom_grade_status_type.resolve(:color)).to eq custom_grade_status.color
    expect(custom_grade_status_type.resolve(:_id)).to eq custom_grade_status.id.to_s
  end
end
