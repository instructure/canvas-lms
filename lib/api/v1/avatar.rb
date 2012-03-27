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
    if feature_enabled?(:facebook) && facebook = user.facebook
      # TODO: add facebook picture if enabled
    end
    if feature_enabled?(:twitter) && twitter = user.user_services.for_service('twitter').first
      url = URI.parse("http://twitter.com/users/show.json?user_id=#{twitter.service_user_id}")
      data = JSON.parse(Net::HTTP.get(url)) rescue nil
      if data
        avatars << avatar_json(user, data['profile_image_url_https'], {
          :type => 'twitter',
          :alt => 'twitter pic'
        })
      end
    end
    if feature_enabled?(:linked_in) && linked_in = user.user_services.for_service('linked_in').first
      self.extend LinkedIn
      profile = linked_in_profile
      if profile && profile['picture_url']
        avatars << avatar_json(user, profile['picture_url'], {
          :type => 'linked_in',
          :alt => 'linked_in pic'
        })
      end
    end
    avatars << avatar_json(user, user.gravatar_url(50, "/images/dotted_pic.png", request), {
      :type => 'gravatar',
      :alt => 'gravatar pic'
    })
    user.profile_pics_folder.active_file_attachments({:include => :thumbnail}).select{|a| a.content_type.match(/\Aimage\//) && a.thumbnail}.sort_by(&:id).reverse.each do |image|
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
      attachment_json(attachment_or_url, {}, { :thumbnail_url => true })
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
    uid = user.is_a?(User) ? user.id : user
    token = "#{uid}::#{type}::#{url}"
    Canvas::Security.hmac_sha1(token)
  end

  def avatar_for_token(user, token)
    avatars_json_for_user(user).select{ |j| j['token'] == token }.first
  end
end
