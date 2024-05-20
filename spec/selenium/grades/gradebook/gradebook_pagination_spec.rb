# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/gradebook_page"

describe "Gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) do
    gradebook_data_setup
  end

  before do
    @page_size = 5
    stub_const("Api::MAX_PER_PAGE", @page_size)
    user_session(@teacher)
  end

  def test_n_students(n)
    create_users_in_course @course, n
    Gradebook.visit(@course)
    f("#gradebook-student-search input").send_keys "user #{n}"
    f("#gradebook-student-search input").send_keys(:return)
    expect(ff(".student-name")).to have_size 1
    expect(f(".student-name")).to include_text "user #{n}"
  end

  it "works for 2 pages" do
    test_n_students @page_size + 1
  end

  it "works for >2 pages" do
    test_n_students (@page_size * 2) + 1
  end
end
