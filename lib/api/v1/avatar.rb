#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::Avatar
  include Api::V1::Json
  include Api::V1::Attachment

  def avatars_json_for_user(user, includes={})
    avatars = []
    avatars << avatar_json(user, user.gravatar_url(50, "/images/dotted_pic.png", request), {
      :type => 'gravatar',
      :alt => 'gravatar pic'
    })
    user.profile_pics_folder.active_file_attachments({:include => :thumbnail}).select{|a| a.content_type.match(/\Aimage\//) && a.thumbnail}.sort_by(&:id).reverse_each do |image|
      avatars << avatar_json(user, image, {
        :type => 'attachment',
        :alt => image.display_name,
        :pending => image.thumbnail.nil?
      })
    end
    # send the dotted box as the last option
    avatars << avatar_json(user, User.avatar_fallback_url('/images/dotted_pic.png', request), {
      :type => 'no_pic',
      :alt => 'no pic'
    })
    avatars
  end

  def avatar_json(user, attachment_or_url, options = {})
    json = if options[:type] == 'attachment'
      attachment_json(attachment_or_url, user, {}, { :thumbnail_url => true })
    else
      { 'url' => attachment_or_url }
    end

    json['type'] = options[:type]
    json['display_name'] ||= options[:alt]
    json['pending'] = options[:pending] unless api_request?
    json['token'] = construct_token(user, json['type'], json['url'])
    json
  end

  def construct_token(user, type, url)
    token = "#{user.id}::#{type}::#{url}"
    Canvas::Security.hmac_sha1(token)
  end

  def avatar_for_token(user, token)
    avatars_json_for_user(user).detect { |j| Canvas::Security.verify_hmac_sha1(token, "#{user.id}::#{j['type']}::#{j['url']}") }
  end
end
