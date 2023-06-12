# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../../helpers/discussions_common"

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  let(:course) { course_model.tap(&:offer!) }
  let(:student) { student_in_course(course:, name: "student", active_all: true).user }
  let(:teacher) { teacher_in_course(course:, name: "teacher", active_all: true).user }
  let(:somebody) { student_in_course(course:, name: "somebody", active_all: true).user }
  let(:somebody_topic) { course.discussion_topics.create!(user: somebody, title: "somebody topic title", message: "somebody topic message") }
  let(:group_topic) { group_discussion_assignment }
  let(:assignment_group) { course.assignment_groups.create!(name: "assignment group") }
  let(:entry) { topic.discussion_entries.create!(user: teacher, message: "teacher entry") }

  context "on the index page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/" }

    context "as anyone" do # we actually use a student, but the idea is that it would work the same for a teacher or anyone else
      before do
        user_session(somebody)
        stub_rcs_config
      end

      let(:topic) { somebody_topic }

      it "starts a new topic", priority: "1" do
        get url
        expect_new_page_load { f("#add_discussion").click }
        edit("new topic title", "new topic")
      end
    end
  end
end
