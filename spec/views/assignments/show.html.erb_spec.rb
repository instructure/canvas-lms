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
require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/assignments/show" do
  it "should render" do
    course_with_teacher(active_all: true)
    view_context(@course, @user)
    g = @course.assignment_groups.create!(:name => "some group")
    a = @course.assignments.create!(:title => "some assignment")
    a.assignment_group_id = g.id
    a.save!
    assign(:assignment, a)
    assign(:assignment_groups, [g])
    assign(:current_user_rubrics, [])
    allow(view).to receive(:show_moderation_link).and_return(true)
    render 'assignments/show'
    expect(response).not_to be_nil # have_tag()
  end

  describe "assignments_2 feature flag" do
    describe "as a teacher" do
      before :each do
        course_with_teacher(active_all: true)
        view_context(@course, @user)
        a = @course.assignments.create!(title: "some assignment")
        assign(:assignment, a)
        allow(view).to receive(:show_moderation_link).and_return(false)
      end

      describe "with feature disabled" do
        it "does not show the new assignments_2 toggle button" do
          render 'assignments/show'
          expect(response).to have_tag("div#assignment_show")
          expect(response).not_to have_tag("a#toggle_assignments_2")
          expect(response).not_to have_tag("div#assignments_2")
        end

        it "shows the old assignments page even with query parameter" do
          allow(view).to receive(:params).and_return({assignments_2: "1"})
          render 'assignments/show'
          expect(response).to have_tag("div#assignment_show")
          expect(response).not_to have_tag("div#assignments_2")
          expect(response).not_to have_tag("a#toggle_assignments_2")
        end
      end

      describe "with feature enabled" do
        before :once do
          Account.default.enable_feature! :assignments_2
        end

        it "it shows old assignments with assignments_2 toggle button" do
          render 'assignments/show'
          expect(response).to have_tag("a#toggle_assignments_2")
          expect(response).to have_tag("div#assignment_show")
          expect(response).not_to have_tag("div#assignments_2")
        end

        it "shows the assignments_2 page when the query parameter is present" do
          allow(view).to receive(:params).and_return({assignments_2: "1"})
          render 'assignments/show'
          expect(response).to have_tag("div#assignments_2")
          expect(response).not_to have_tag("div#assignment_show")
        end
      end
    end

    describe "as a student" do
      before :each do
        course_with_student(active_all: true)
        view_context(@course, @user)
        a = @course.assignments.create!(title: "some assignment")
        # mocking this method seems to be the easiest thing to do
        allow(a).to receive(:multiple_due_dates?).and_return(false)
        assign(:assignment, a)
      end

      describe "with feature disabled" do
        it "does not show the new assignments toggle button" do
          render 'assignments/show'
          expect(response).to have_tag("div#assignment_show")
          expect(response).not_to have_tag("a#toggle_assignments_2")
          expect(response).not_to have_tag("div#assignments_2")
        end

        it "shows the old assignments page even with query parameter" do
          allow(view).to receive(:params).and_return({assignments_2: "1"})
          render 'assignments/show'
          expect(response).to have_tag("div#assignment_show")
          expect(response).not_to have_tag("div#assignments_2")
          expect(response).not_to have_tag("a#toggle_assignments_2")
        end
      end

      describe "with feature enabled" do
        before :once do
          Account.default.enable_feature! :assignments_2
        end

        it "shows the new assignments toggle button" do
          render 'assignments/show'
          expect(response).to have_tag("a#toggle_assignments_2")
          expect(response).to have_tag("div#assignment_show")
          expect(response).not_to have_tag("div#assignments_2")
        end

        it "shows the assignments 2 page when the query parameter is present" do
          allow(view).to receive(:params).and_return({assignments_2: "1"})
          render 'assignments/show'
          expect(response).to have_tag("div#assignments_2")
          expect(response).not_to have_tag("div#assignment_show")
        end
      end
    end
  end

  describe "moderation page link" do
    before :each do
      course_with_teacher(active_all: true)
      view_context(@course, @user)
      g = @course.assignment_groups.create!(name: "Homework")
      a = @course.assignments.create!(title: "Introduce Yourself")
      a.assignment_group_id = g.id
      a.save!
      assign(:assignment, a)
      assign(:assignment_groups, [g])
      assign(:current_user_rubrics, [])
    end

    it "is rendered when 'show_moderation_link' is true" do
      allow(view).to receive(:show_moderation_link).and_return(true)
      render 'assignments/show'
      expect(rendered).to include "moderated_grading_button"
    end

    it "is not rendered when 'show_moderation_link' is false" do
      allow(view).to receive(:show_moderation_link).and_return(false)
      render 'assignments/show'
      expect(rendered).not_to include "moderated_grading_button"
    end
  end

  context 'plagiarism platform' do
    include_context 'lti2_spec_helper'

    let(:eula_url) { 'https://www.test.com/eula' }
    let(:eula_service) do
      {
        "endpoint" => eula_url,
        "action" => ["GET"],
        "@id" => 'http://www.test.com/lti/v2/services#vnd.Canvas.Eula',
        "@type" => "RestService"
      }
    end

    before do
      allow_any_instance_of(Assignment).to receive(:multiple_due_dates?) { true }
      allow(view).to receive(:eula_url) { eula_url }
    end

    it 'renders the eula url if present' do
      tool_proxy.raw_data['tool_profile']['service_offered'] << eula_service
      tool_proxy.resources << resource_handler
      tool_proxy.save!

      course_with_student(active_all: true)
      view_context(@course, @student)

      a = @course.assignments.create!(:title => "some assignment", :submission_types => 'online_upload')
      allow(a).to receive(:tool_settings_tool) { message_handler }
      assign(:assignment, a)
      assign(:current_user_rubrics, [])
      assign(:external_tools, [])

      render 'assignments/show'
      expect(rendered).to include "<a href='https://www.test.com/eula'>End-User License Agreement.</a>"
    end
  end
end
