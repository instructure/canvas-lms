#
# Copyright (C) 2011-12 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "courses/statistics.html.erb" do
  before do
    course_with_teacher(:active_all => true)
    assign(:range_start, Date.parse("Jan 1 2000"))
    assign(:range_end, 3.days.from_now)
  end

  it "only lists active quiz objects, questions, and submissions" do
    quiz_with_submission
    @quiz.destroy
    quiz_with_submission

    view_context(@course, @user)
    render

    doc = Nokogiri::HTML.parse(response.body)
    expect(doc.at_css('.quiz_count').text).to eq "1"
    expect(doc.at_css('.quiz_question_count').text).to eq "1"
    expect(doc.at_css('.quiz_submission_count').text).to eq "1"
  end
end
