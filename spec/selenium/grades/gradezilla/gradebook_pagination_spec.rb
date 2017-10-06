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

require_relative '../../helpers/gradezilla_common'
require_relative '../pages/gradezilla_page'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  before(:once) do
    gradebook_data_setup
    @page_size = 5
    Setting.set 'api_max_per_page', @page_size
  end

  before do
    user_session(@teacher)
  end

  def test_n_students(n)
    create_users_in_course @course, n
    Gradezilla.visit(@course)
    f('.gradebook_filter input').send_keys n
    expect(ff('.student-name')).to have_size 1
    expect(f('.student-name')).to include_text "user #{n}"
  end

  it "should work for 2 pages" do
    test_n_students @page_size + 1
  end

  it "should work for >2 pages" do
    test_n_students @page_size * 2 + 1
  end
end
