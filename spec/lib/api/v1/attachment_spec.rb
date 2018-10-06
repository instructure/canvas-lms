#
# Copyright (C) 2018 - present Instructure, Inc.
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

require "spec_helper"

describe Api::V1::Attachment do
  include Api::V1::Attachment
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: 'example.com' }
  end

  describe "#attachment_json" do
    let(:course) { Course.create! }
    let(:attachment) { attachment_model(content_type: "application/pdf", context: student) }
    let(:student) { course_with_user("StudentEnrollment", course: course, active_all: true).user }
    let(:teacher) { course_with_user("TeacherEnrollment", course: course, active_all: true).user }

    before(:each) do
      allow(Canvadocs).to receive(:enabled?).and_return(true)
      Canvadoc.create!(document_id: "abc123#{attachment.id}", attachment_id: attachment.id)
    end

    it "includes the submission id in the url_opts when preview_url is included" do
      params = {
        include: ["preview_url"],
        submission_id: 2345
      }
      json = attachment_json(attachment, teacher, {}, params)
      expect(json.fetch("preview_url")).to include("%22submission_id%22:2345")
    end
  end
end
