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

require "spec_helper"

describe DataFixup::CreateCanvadocsSubmissionsRecords do
  before :once do
    student_in_course active_all: true
    @assignment = @course.assignments.create! title: "ASSIGNMENT"
    @attachment = crocodocable_attachment_model user: @student, context: @student
  end

  def make_submission
    @submission = @assignment.submit_homework @student,
      submission_type: "online_upload",
      attachments: [@attachment]
  end

  def test_associations(type)
    run_jobs

    #clear out the records created by callbacks
    CanvadocsSubmission.delete_all

    DataFixup::CreateCanvadocsSubmissionsRecords.run
    expect(@attachment.send(type).submissions).to eq [@submission]
  end

  it "creates records for canvadocs" do
    PluginSetting.create! :name => 'canvadocs',
                          :settings => {"api_key" => "blahblahblahblahblah",
                                        "base_url" => "http://example.com",
                                        "annotations_supported" => true}
    make_submission
    test_associations('canvadoc')
  end

  it "creates records for crocodoc_documents" do
    PluginSetting.create! :name => 'crocodoc',
                          :settings => { :api_key => "blahblahblahblahblah" }
    make_submission
    test_associations('crocodoc_document')
  end
end
