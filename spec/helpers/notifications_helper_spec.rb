#
# Copyright (C) 2011 Instructure, Inc.
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

describe NotificationsHelper do
  
  before(:all) do
    class A
      include NotificationsHelper
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :A)
  end
  
  before do
    @a = A.new
  end
  
  it "should have a format_message" do
    @a.should be_respond_to(:format_message)
  end

  it "should replace newlines with <br/>" do
    msg = %{this
      and that}
    fm = @a.format_message(msg, '')
    fm.first.should match(/<br\/>/)
  end
  
  it "should replace links with actual html links" do
    msg = %{http://google.com}
    fm = @a.format_message(msg, '')
    fm.first.should match(/<a href='http:\/\/google.com/)
  end
end


# def format_message(message="", notification_id=nil)
#   message = message.gsub(/\r?\n/, "<br/>\r\n")
#   links = []
#   message = message.gsub(/((http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?)/ix) do |s|
#     parts = "#{s}".split("#", 2)
#     link = parts[0]
#     link += link.match(/\?/) ? "&" : "?"
#     link += "clear_notification_id=#{notification_id}"
#     link += parts[1] if parts[1]
#     links << link
#     "<a href='#{link}'>#{s}</a>";
#   end
#   links.unshift message
# end
