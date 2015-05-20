#
# Copyright (C) 2015 Instructure, Inc.
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

class AccountAuthorizationConfig::Twitter < AccountAuthorizationConfig::Oauth
  def self.singleton?
    true
  end

  def self.recognized_params
    if globally_configured?
      [].freeze
    else
      [ :consumer_key, :consumer_secret ].freeze
    end
  end

  SENSITIVE_PARAMS = [ :consumer_secret ].freeze

  def self.globally_configured?
    Canvas::Plugin.find(:twitter).enabled?
  end

  # Rename db field
  def consumer_key
    self.class.globally_configured? ? settings[:consumer_key] : super
  end

  def consumer_secret
    if self.class.globally_configured?
      settings[:consumer_secret_dec]
    else
      super
    end
  end

  def unique_id(token)
    token.params[:user_id]
  end

  protected

  def settings
    Canvas::Plugin.find(:twitter).settings
  end

  def consumer_options
    {
      site: 'https://api.twitter.com'.freeze,
      authorize_path: '/oauth/authenticate'.freeze
    }
  end
end
