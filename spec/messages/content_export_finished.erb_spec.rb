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
#

require_relative "messages_helper"

describe "content_export_finished" do
  include MessagesCommon

  before :once do
    course_with_student(active_all: true)
    @ce = @course.content_exports.create!(user: @student)
  end

  let(:notification_name) { :content_export_finished }

  context "content export" do
    let(:asset) { @ce }

    describe ".email" do
      let(:path_type) { :email }

      it "renders the content export link" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("/courses/#{@course.id}/content_exports")
      end
    end

    describe ".email.html" do
      let(:path_type) { :summary }

      it "renders the content export link" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("/courses/#{@course.id}/content_exports")
      end
    end
  end

  context "epub exports" do
    before :once do
      @epub = @course.epub_exports.create!(course: @course, user: @student, content_export: @ce)
    end

    let(:asset) { @epub }

    describe ".email" do
      let(:path_type) { :email }

      it "renders the epub export link" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("/epub_exports")
      end
    end

    describe ".summary" do
      let(:path_type) { :summary }

      it "renders the epub export link" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("/epub_exports")
      end
    end
  end

  context "web zip exports" do
    before :once do
      @webzip = @course.web_zip_exports.create!(course: @course, user: @student, content_export: @ce)
    end

    let(:asset) { @webzip }

    describe ".email" do
      let(:path_type) { :email }

      it "renders the web zip export link" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("/courses/#{@course.id}/offline_web_exports")
      end
    end

    describe ".summary" do
      let(:path_type) { :summary }

      it "renders the web zip export link" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("/courses/#{@course.id}/offline_web_exports")
      end
    end
  end
end
