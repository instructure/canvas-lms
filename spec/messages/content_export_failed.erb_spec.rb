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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'content_export_failed' do
  include MessagesCommon

  before :once do
    course_with_student(:active_all => true)
    @ce = @course.content_exports.create!(user: @student)
  end

  let(:notification_name) { :content_export_failed }

  context "content export" do
    let(:asset) { @ce }

    context ".email" do
      let(:path_type) { :email }
      it "should render the content export id" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("ContentExport:#{asset.id}")
      end
    end

    context ".email.html" do
      let(:path_type) { :summary }
      it "should render the content export id" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("ContentExport:#{asset.id}")
      end
    end
  end

  context "epub exports" do
    before :once do
      @epub = @course.epub_exports.create!(course: @course, user: @student, content_export: @ce)
    end

    let(:asset) { @epub }

    context ".email" do
      let(:path_type) { :email }
      it 'should render the epub export id' do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("EpubExport:#{asset.id}")
      end
    end

    context ".summary" do
      let(:path_type) { :summary }
      it 'should render the epub export id' do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("EpubExport:#{asset.id}")
      end
    end
  end

  context 'web zip exports' do
    before :once do
      @webzip = @course.web_zip_exports.create!(course: @course, user: @student, content_export: @ce)
    end

    let(:asset) { @webzip }

    context ".email" do
      let(:path_type) { :email }
      it 'should render the web zip export id' do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("WebZipExport:#{asset.id}")
      end
    end

    context ".summary" do
      let(:path_type) { :summary }
      it 'should render the web zip export id' do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include("WebZipExport:#{asset.id}")
      end
    end
  end
end
