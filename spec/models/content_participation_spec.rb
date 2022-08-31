# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe ContentParticipation do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    assignment_model(course: @course)
    @content = @assignment.submit_homework(@student)
  end

  describe "create_or_update" do
    it "creates if it doesn't exist" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "read",
                                              })
      end.to change(ContentParticipation, :count).by 1
    end

    it "updates existing if one already exists" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "read",
                                              })
      end.to change(ContentParticipation, :count).by 1

      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "unread",
                                              })
      end.to change(ContentParticipation, :count).by 0

      cp = ContentParticipation.where(user_id: @student).first
      expect(cp.workflow_state).to eq "unread"
    end
  end

  describe "update_participation_count" do
    it "updates the participation count automatically when the workflow state changes" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "read",
                                              })
      end.to change(ContentParticipationCount, :count).by 1

      ContentParticipation.create_or_update({
                                              content: @content,
                                              user: @student,
                                              workflow_state: "unread",
                                            })
      cpc = ContentParticipationCount.where(user_id: @student).first
      expect(cpc.unread_count).to eq 1
    end

    it "does not update participation count if workflow_state doesn't change" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "read",
                                              })
      end.to change(ContentParticipationCount, :count).by 1

      ContentParticipation.create_or_update({
                                              content: @content,
                                              user: @student,
                                              workflow_state: "read",
                                            })
      cpc = ContentParticipationCount.where(user_id: @student).first
      expect(cpc.unread_count).to eq 0
    end

    it "unread count does not decrement if unread count is at 0 and workflow state changes from unread to read" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "unread",
                                              })
      end.to change(ContentParticipationCount, :count).by 1

      ContentParticipation.create_or_update({
                                              content: @content,
                                              user: @student,
                                              workflow_state: "read",
                                            })
      cpc = ContentParticipationCount.where(user_id: @student).first
      expect(cpc.unread_count).to eq 0
    end
  end

  describe "create" do
    it "sets the root_account_id from the submissions assignment" do
      participant = ContentParticipation.create_or_update({
                                                            content: @content,
                                                            user: @student,
                                                            workflow_state: "unread",
                                                          })
      expect(participant.root_account_id).to eq(@assignment.root_account_id)
    end
  end
end
