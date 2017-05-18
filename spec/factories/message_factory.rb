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

module Factories
  def message_model(opts={})
    @message = factory_with_protected_attributes(Message, message_valid_attributes.merge(opts))
  end

  def message_valid_attributes
    {
      :subject => "value for subject",
      :body => "value for body",
      :sent_at => Time.now
    }
  end

  def generate_message(notification_name, path_type, asset, options = {})
    raise "options must be a hash!" unless options.is_a? Hash
    @notification = Notification.where(name: notification_name.to_s).first_or_create!
    user = options[:user]
    asset_context = options[:asset_context]
    data = options[:data] || {}
    user ||= User.create!(:name => "some user")

    cc_path_type = path_type == :summary ? :email : path_type
    @cc = user.communication_channels.of_type(cc_path_type.to_s).first
    @cc ||= user.communication_channels.create!(path_type: cc_path_type.to_s,
                                                path: 'generate_message@example.com')
    @message = Message.new(notification: @notification,
                           context: asset,
                           user: user,
                           communication_channel: @cc,
                           asset_context: asset_context,
                           data: data)
    @message.delayed_messages = []
    @message.parse!(path_type.to_s)
    @message
  end
end
