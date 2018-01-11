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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')
require_relative '../../selenium/helpers/groups_common'

describe "/gradebooks/speed_grader" do
  include GroupsCommon

  before do
    course_with_student(active_all: true)
    view_context
    assign(:students, [@user])

    @group_category = @course.group_categories.create!(name: "Test Group Set")
    @group = @course.groups.create!(name: "a group", group_category: @group_category)
    add_user_to_group(@user, @group, true)
    @assignment = @course.assignments.create!(assignment_valid_attributes.merge(
      group_category: @group_category,
      grade_group_students_individually: true
    ))

    assign(:assignment, @assignment)
    assign(:submissions, [])
    assign(:assessments, [])
    assign(:body_classes, [])
  end

  it "should render" do
    render "gradebooks/speed_grader"
    expect(rendered).not_to be_nil
  end

  it "includes a link back to the gradebook (gradebook by default)" do
    render "gradebooks/speed_grader"
    course_id = @course.id
    expect(rendered).to include "a href=\"http://test.host/courses/#{course_id}/gradebook\""
  end

  it 'includes the comment auto-save message' do
    render 'gradebooks/speed_grader'

    expect(rendered).to include 'Your comment was auto-saved as a draft.'
  end

  it 'includes the link to publish' do
    render 'gradebooks/speed_grader'

    expect(rendered).to match(/button.+?class=.+?submit_comment_button/)
  end

  it 'it renders the plagiarism resubmit button if the assignment has a plagiarism tool' do
    allow_any_instance_of(Assignment).to receive(:assignment_configuration_tool_lookup_ids) { [1] }
    render 'gradebooks/speed_grader'
    expect(rendered).to include "<div id='plagiarism_platform_info_container'>"
  end

  describe 'submission comments form' do
    it 'is rendered when @can_comment_on_submission is true' do
      assign(:can_comment_on_submission, true)
      render 'gradebooks/speed_grader'

      expect(rendered).to match(/form id="add_a_comment"/)
    end

    it 'is not rendered when @can_comment_on_submission is false' do
      assign(:can_comment_on_submission, false)
      render 'gradebooks/speed_grader'

      expect(rendered).not_to match(/form id="add_a_comment"/)
    end
  end

  context 'when group assignment' do
    before do
      assign(:can_comment_on_submission, true)
    end

    it 'shows radio buttons if individually graded' do
      render 'gradebooks/speed_grader'
      html = Nokogiri::HTML.fragment(response.body)
      expect(html.css('input[type="radio"][name="submission[group_comment]"]').size).to eq 2
      expect(html.css('#submission_group_comment').size).to eq 1
    end

    it 'renders hidden checkbox if group graded' do
      @assignment.grade_group_students_individually = false
      @assignment.save!
      render 'gradebooks/speed_grader'
      html = Nokogiri::HTML.fragment(response.body)
      expect(html.css('input[type="radio"][name="submission[group_comment]"]').size).to eq 0
      checkbox = html.css('#submission_group_comment')
      expect(checkbox.attr('checked').value).to eq 'checked'
      expect(checkbox.attr('style').value).to include('display:none')
    end
  end
end
