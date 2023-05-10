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
#

require_relative "../spec_helper"
require_relative "../support/request_helper"

describe "Discussion Topics API" do
  let(:teacher_enrollment) { course_with_teacher(active_all: true) }
  let(:course) { teacher_enrollment.course }
  let(:teacher) { teacher_enrollment.user }
  let!(:discussion) { discussion_topic_model(context: course, user: teacher) }
  let!(:anon_discussion) { discussion_topic_model(context: course, user: teacher, anonymous_state: "full_anonymity") }

  describe "index" do
    before do
      user_session(teacher)
    end

    describe "anonymity" do
      context "when the discussion is not anonymous" do
        it "includes the author information" do
          get api_v1_course_discussion_topics_path(course.id), params: { format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body.detect { |d| d["id"] == discussion.id }
          expect(json["author"]).to_not be_nil
        end
      end

      context "when the discussion is anonymous" do
        it "does not include the author information" do
          get api_v1_course_discussion_topics_path(course.id), params: { format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body.detect { |d| d["id"] == anon_discussion.id }
          expect(json["author"]).to be_nil
        end
      end
    end
  end
end
