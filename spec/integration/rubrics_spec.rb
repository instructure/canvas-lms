#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "rubrics" do
  it "doesn't render edit links for outcome criterion rows" do
    course_with_teacher_logged_in(active_all: true)
    outcome_with_rubric
    @rubric.rubric_associations.create!(
      association_object: @course,
      context: @course,
      purpose: 'bookmark'
    )

    get "/courses/#{@course.id}/rubrics/#{@rubric.id}"

    expect(response).to be_success
    page = Nokogiri::HTML(response.body)
    expect(page.css('#rubrics .rubric_table .criterion:nth-child(1) .edit_criterion_link')).to be_empty
    expect(page.css('#rubrics .rubric_table .criterion:nth-child(2) .edit_criterion_link')).not_to be_empty
  end
end
