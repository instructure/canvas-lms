#
# Copyright (C) 2016 Instructure, Inc.
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
require 'spec/views/views_helper'

describe "/gradebooks/submissions_zip_upload", type: :view do
  before do
    course_with_student
    view_context
    assign(:students, [@user])
    assign(:assignment, @course.assignments.create!(:title => "some assignment"))
    assign(:comments, [])
    assign(:failures, [])
  end

  it "should render" do
    render 'gradebooks/submissions_zip_upload'

    expect(rendered).to be_present
  end

  it "includes a link back to the gradebook (gradebook by default)" do
    render 'gradebooks/submissions_zip_upload'

    expect(view.content_for(:right_side)).to match(/a.+?href="\/courses\/#{@course.id}\/gradebook"/)
  end
end
