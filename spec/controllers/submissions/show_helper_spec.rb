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
#

describe "Submissions::ShowHelper" do
  describe "included in a controller" do
    controller do
      include Submissions::ShowHelper

      def show
        @context = Course.find(params[:context_id])
        @assignment = Assignment.where(id: params[:assignment_id]).where.not(workflow_state: "deleted").first
        render_user_not_found
      end
    end

    describe "#render_user_not_found" do
      before do
        course_factory
        assignment_model
        routes.draw { get "anonymous" => "anonymous#show" }
      end

      context "with format html" do
        before do
          get :show, params: { context_id: @course.id, assignment_id: @assignment.id }
        end

        it "redirects to assignment url" do
          expect(response).to redirect_to(course_assignment_url(@course, @assignment.id))
        end

        it "set flash error" do
          expect(flash[:error]).to be_present
        end
      end

      context "with format json" do
        before do
          get :show, params: { context_id: @course.id, assignment_id: @assignment.id }, format: :json
        end

        it "render json with errors key" do
          json = response.parsed_body
          expect(json).to have_key("errors")
        end
      end

      context "with no assignment" do
        it "shows a cromulent error" do
          get :show, params: { context_id: @course.id, assignment_id: -9000 }
          expect(response).to redirect_to(course_url(@course))
          expect(flash[:error]).to eq "The specified assignment could not be found"
        end

        it "works with json too" do
          get :show, params: { context_id: @course.id, assignment_id: -9000 }, format: :json
          json = response.parsed_body
          expect(json["errors"]).to eq "The specified assignment (-9000) could not be found"
        end
      end

      context "with a deleted discussion" do
        it "shows This Discussion has been deleted alert" do
          graded_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "graded topic")
          graded_topic.destroy
          get :show, params: { context_id: @course.id, assignment_id: graded_topic.assignment.id }
          expect(flash[:notice]).to eq "This Discussion has been deleted"
        end
      end
    end
  end
end
