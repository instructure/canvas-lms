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

require_relative '../../common'
require_relative '../pages/k5_dashboard_page'
require_relative '../pages/k5_dashboard_common_page'
require_relative '../../../helpers/k5_common'
require_relative '../shared_examples/k5_important_dates_shared_examples'

describe "teacher k5 dashboard important dates" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before :once do
    teacher_setup
  end

  before :each do
    user_session @homeroom_teacher
  end

  it_behaves_like 'k5 important dates'
end
