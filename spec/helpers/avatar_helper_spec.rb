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

describe AvatarHelper do
  include AvatarHelper

  context "avatars" do
    before do
      @services = {}
    end

    def avatar_size; 50; end

    def service_enabled?(type)
      @services[type]
    end

    it "should return full URIs for users" do
      user = user()
      avatar_url_for_user(user).should match(%r{\Ahttps?://})
      avatar_url_for_user(user, true).should match(%r{\Ahttps?://})

      @services[:avatars] = true
      avatar_url_for_user(user).should match(%r{\Ahttps?://})
      avatar_url_for_user(user, true).should match(%r{\Ahttps?://})

      user.avatar_image_source = 'no_pic'
      user.save!
      avatar_url_for_user(user).should match(%r{\Ahttps?://})
      avatar_url_for_user(user, true).should match(%r{\Ahttps?://})
    end

    it "should return full URIs for groups" do
      avatar_url_for_group.should match(%r{\Ahttps?://})
      avatar_url_for_group(true).should match(%r{\Ahttps?://})
    end
  end
end
