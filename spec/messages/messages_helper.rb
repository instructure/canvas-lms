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

def generate_message(notification_name, path_type, asset, options = {})
  raise "options must be a hash!" unless options.is_a? Hash
  @notification = Notification.find_by_name(notification_name.to_s) || Notification.create!(:name => notification_name.to_s)
  user = options[:user]
  asset_context = options[:asset_context]
  data = options[:data] || {}
  user ||= User.create!(:name => "some user")

  cc_path_type = path_type == :summary ? :email : path_type
  @cc = user.communication_channels.of_type(cc_path_type.to_s).first
  @cc ||= user.communication_channels.create!(:path_type => cc_path_type.to_s, :path => 'generate_message@example.com')
  @message = Message.new(:notification => @notification, :context => asset, :user => user, :communication_channel => @cc, :asset_context => asset_context, :data => data)
  @message.delayed_messages = []
  @message.parse!(path_type.to_s)
  @message.body.should_not be_nil
  if path_type == :email
    @message.subject.should_not be_nil
    @message.url.should_not be_nil
  end
  @message
end
