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

describe InfoController do
  describe "#avatar_image_url" do
    it "should clear the cache on avatar update" do
      Account.default.tap { |a| a.enable_service(:avatars) }.save
      enable_cache do
        user_factory
        get "/images/users/#{@user.id}"
        expect(response).to be_redirect
        expect(response['Location']).to match(%r{avatar-50})

        @user.avatar_image = { 'type' => 'attachment', 'url' => '/images/thumbnails/blah' }
        @user.save!

        get "/images/users/#{@user.id}"
        expect(response).to be_redirect
        expect(response['Location']).not_to match(%r{avatar-50})
        expect(response['Location']).to match(%r{/images/thumbnails/blah})
      end
    end
  end
end
