# encoding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GradebookCsvsController do
  before :once do
    course_with_teacher active_all: true
    @course.short_name = "ENG101"
    @course.save
  end

  it "uses GradebookCsvsController" do
    expect(controller).to be_an_instance_of(GradebookCsvsController)
  end

  describe "GET 'show'" do
    it "returns the attachment and progress" do
      user_session @teacher

      get 'show', course_id: @course.id, format: :json
      json = json_parse(response.body)
      expect(response).to be_success
      expect(json).to have_key 'attachment_id'
      expect(json).to have_key 'progress_id'
    end

    it "creates the attachment and progress" do
      user_session @teacher

      get 'show', course_id: @course.id, format: :json
      json = json_parse(response.body)
      expect(Attachment.find json['attachment_id']).not_to be_nil
      expect(Progress.find json['progress_id']).not_to be_nil
    end

    it "names the CSV file after course#short_name" do
      user_session @teacher

      get 'show', course_id: @course.id, format: :json
      json = json_parse(response.body)
      attachment = Attachment.find(json['attachment_id'])
      expect(@course.short_name).to eq(File.basename(attachment.filename.split("-").last, ".csv"))
    end
  end
end

