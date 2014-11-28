#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ContentParticipation do
  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
    assignment_model(:course => @course)
    @content = @assignment.submit_homework(@student)
  end

  describe "create_or_update" do
    it "should create if it doesn't exist" do
      expect {
        ContentParticipation.create_or_update({
          :content => @content,
          :user => @student,
          :workflow_state => "read",
        })
      }.to change(ContentParticipation, :count).by 1
    end

    it "should update existing if one already exists" do
      expect {
        ContentParticipation.create_or_update({
          :content => @content,
          :user => @student,
          :workflow_state => "read",
        })
      }.to change(ContentParticipation, :count).by 1

      expect {
        ContentParticipation.create_or_update({
          :content => @content,
          :user => @student,
          :workflow_state => "unread",
        })
      }.to change(ContentParticipation, :count).by 0

      cp = ContentParticipation.where(:user_id => @student).first
      expect(cp.workflow_state).to eq "unread"
    end
  end

  describe "update_participation_count" do
    it "should update the participation count automatically when the workflow state changes" do
      expect {
        ContentParticipation.create_or_update({
          :content => @content,
          :user => @student,
          :workflow_state => "read",
        })
      }.to change(ContentParticipationCount, :count).by 1

      ContentParticipation.create_or_update({
        :content => @content,
        :user => @student,
        :workflow_state => "unread",
      })
      cpc = ContentParticipationCount.where(:user_id => @student).first
      expect(cpc.unread_count).to eq 1
    end

    it "should not update participation count if workflow_state doesn't change" do
      expect {
        ContentParticipation.create_or_update({
          :content => @content,
          :user => @student,
          :workflow_state => "read",
        })
      }.to change(ContentParticipationCount, :count).by 1

      ContentParticipation.create_or_update({
        :content => @content,
        :user => @student,
        :workflow_state => "read",
      })
      cpc = ContentParticipationCount.where(:user_id => @student).first
      expect(cpc.unread_count).to eq 0
    end
  end
end
