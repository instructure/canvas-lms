# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
require_relative '../spec_helper'

describe GradebookUpload do
  describe ".queue_from" do
    let(:teacher_enrollment){ teacher_in_course }
    let(:teacher){ teacher_enrollment.user }
    let(:gradebook_course){ teacher_enrollment.course }
    let(:attachment_data){ {dummy: "data"} }

    before(:each) do
      # actual attachment integration covered in gradebook_uploads_controller_spec;
      # that means in the spec the dummy hash will be enqueued instead of a real attachment
      # object
      allow_any_instance_of(GradebookUpload).to receive_messages(attachments: double(create!: attachment_data))
    end

    it "builds a progress object to track the import" do
      progress = GradebookUpload.queue_from(gradebook_course, teacher, attachment_data)
      expect(progress.workflow_state).to eq("queued")
      expect(progress.tag).to eq("gradebook_upload")
      expect(progress.context).to eq(gradebook_course)
    end

    it "queues a job to run the import" do
      GradebookUpload.queue_from(gradebook_course, teacher, attachment_data)
      job = Delayed::Job.last
      expect(job.tag).to match(/GradebookImporter/)
    end

    it "stores the input data in an attachment on the gradebook upload" do
      GradebookUpload.queue_from(gradebook_course, teacher, attachment_data)
      job = Delayed::Job.last
      expect(job.handler).to include("dummy: data")
    end

    it "creates a GradebookUpload object to represent the upload process" do
      GradebookUpload.queue_from(gradebook_course, teacher, attachment_data)
      upload = GradebookUpload.last
      expect(upload.course).to eq(gradebook_course)
    end
  end
end
