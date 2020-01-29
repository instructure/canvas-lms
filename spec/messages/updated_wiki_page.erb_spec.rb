#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "updated_wiki_page" do
  before :once do
    wiki_page_model
  end

  let(:asset) { @page }
  let(:notification_name) { :updated_wiki_page }

  include_examples "a message"
  context "locked Wiki Pages" do
    it "should send locked notification if availibility date is locked for email" do
      enrollment = course_with_student(active_all: true)
      context_module = @course.context_modules.create!(name: 'some module')
      page = @course.wiki_pages.create!(:title => "some page")
      context_module.add_item({:id => page.id, :type => 'wiki_page'})
      page.reload

      context_module.update(
        unlock_at: Time.zone.now + 3.days
      )

      page.update(
        body: "the content here of the Wiki Page body",
        could_be_locked: true
      )

      message = generate_message(notification_name, :email, page, :user => enrollment.user)
      expect(message.body).to include("Wiki page content is locked or not yet available")
    end

    it "should send Wiki Page notification with Wiki Pages content when unlocked for email" do
      enrollment = course_with_student(active_all: true)
      context_module = @course.context_modules.create!(name: 'some module')
      page = @course.wiki_pages.create!(:title => "some page")
      context_module.add_item({:id => page.id, :type => 'wiki_page'})
      page.reload

      context_module.update(
        unlock_at: Time.zone.now - 3.days
      )

      page.update(
        body: "the content here of the Wiki Page body",
        could_be_locked: true
      )

      message = generate_message(notification_name, :email, page, :user => enrollment.user)
      expect(message.body).to include("the content here of the Wiki Page body")
    end
  end

end
