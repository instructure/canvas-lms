# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class AuthenticationProvider::Clever < AuthenticationProvider::OAuth2
  include AuthenticationProvider::PluginSettings
  self.plugin = :clever
  plugin_settings :client_id, client_secret: :client_secret_dec

  def self.singleton?
    false
  end

  def self.recognized_params
    super + %i[login_attribute district_id jit_provisioning].freeze
  end

  def self.login_attributes
    %w[id sis_id email student_number teacher_number state_id district_username].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    (login_attributes + %w[first_name last_name home_language]).freeze
  end

  # Rename db field
  alias_attribute :district_id, :auth_filter

  def login_attribute
    super || "id"
  end

  def unique_id(token)
    data = me(token)

    if district_id.present? && data["district"] != district_id
      # didn't make a "nice" exception for this, cause it should never happen.
      # either we got MITM'ed (on the server side), or Clever's docs lied;
      # this check is just an extra precaution
      raise "Non-matching district: #{data["district"].inspect}"
    end

    data[login_attribute]
  end

  def provider_attributes(token)
    me(token)
  end

  protected

  def me(token)
    token.options[:me] ||= begin
      raw_data = token.get("/v2.1/me").parsed
      data = raw_data["data"].dup
      data = data.merge(token.get("/v2.1/#{raw_data["type"]}s/#{data["id"]}").parsed["data"])
      data["first_name"] = data.dig("name", "first")
      data["last_name"] = data.dig("name", "last")
      data["district_username"] = data.dig("credentials", "district_username")
      data.slice!(*(self.class.recognized_federated_attributes + ["district"]))
      data
    end
  end

  def client_options
    {
      site: "https://api.clever.com",
      authorize_url: "https://clever.com/oauth/authorize",
      token_url: "https://clever.com/oauth/tokens",
      auth_scheme: :basic_auth,
    }
  end

  def authorize_options
    result = { scope: }
    result[:district_id] = district_id if district_id.present?
    result
  end

  def scope
    "read:user_id"
  end
end
