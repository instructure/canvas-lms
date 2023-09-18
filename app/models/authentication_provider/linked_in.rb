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

class AuthenticationProvider::LinkedIn < AuthenticationProvider::OAuth2
  include AuthenticationProvider::PluginSettings
  self.plugin = :linked_in
  plugin_settings :client_id, client_secret: :client_secret_dec

  def self.sti_name
    "linkedin"
  end

  def self.recognized_params
    super + [:login_attribute, :jit_provisioning].freeze
  end

  def self.login_attributes
    ["id", "emailAddress"].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    %w[
      emailAddress
      firstName
      id
      lastName
    ].freeze
  end

  def login_attribute
    super || "id"
  end

  def unique_id(token)
    person(token)[login_attribute]
  end

  def provider_attributes(token)
    person(token)
  end

  protected

  def person(token)
    result = me(token)
    result = result.merge(email(token)) if email_required?
    result
  end

  def me(token)
    token.options[:me] ||= begin
      data = token.get("/v2/me").parsed
      {
        "id" => data["id"],
        "firstName" => get_localized_field(data["firstName"]),
        "lastName" => get_localized_field(data["lastName"])
      }
    end
  end

  def get_localized_field(localized_field)
    localized_field["localized"].first.last
  end

  def email(token)
    token.options[:emailAddress] ||= token.get("/v2/emailAddress?q=members&projection=(elements*(handle~))").parsed["elements"].first["handle~"]
  end

  def email_required?
    login_attribute == "emailAddress" ||
      federated_attributes.any? { |(_k, v)| v["attribute"] == "emailAddress" }
  end

  def client_options
    {
      site: "https://api.linkedin.com",
      authorize_url: "https://www.linkedin.com/oauth/v2/authorization",
      token_url: "https://www.linkedin.com/oauth/v2/accessToken",
      auth_scheme: :request_body
    }
  end

  def authorize_options
    { scope: }
  end

  def scope
    if email_required?
      "r_liteprofile r_emailaddress"
    else
      "r_liteprofile"
    end
  end
end
