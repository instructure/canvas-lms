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

module AccountServices
  class AllowedServicesHash < Hash
    def _dump(*)
      ""
    end

    def self._load(*); end
  end

  def self.allowable_services
    AllowedServicesHash.new.merge({
                                    google_drive: {
                                      name: I18n.t("Google Drive"),
                                      description: "",
                                      expose_to_ui: :service,
                                      expose_to_ui_proc: proc { !!GoogleDrive::Connection.config }
                                    },
                                    google_docs_previews: {
                                      name: I18n.t("Google Docs Preview"),
                                      description: "",
                                      expose_to_ui: :service
                                    },
                                    skype: {
                                      name: I18n.t("Skype"),
                                      description: "",
                                      expose_to_ui: :service
                                    },
                                    diigo: {
                                      name: I18n.t("Diigo"),
                                      description: "",
                                      expose_to_ui: :service,
                                      expose_to_ui_proc: proc { !!Diigo::Connection.config }
                                    },
                                    # TODO: move avatars to :settings hash, it makes more sense there
                                    # In the meantime, we leave it as a service but expose it in the
                                    # "Features" (settings) portion of the account admin UI
                                    avatars: {
                                      name: I18n.t("User Avatars"),
                                      description: "",
                                      default: false,
                                      expose_to_ui: :setting
                                    },
                                    account_survey_notifications: {
                                      name: I18n.t("Account Surveys"),
                                      description: "",
                                      default: false,
                                      expose_to_ui: :setting,
                                      expose_to_ui_proc: proc do |user, account|
                                                           user && account && account.grants_right?(user, :manage_site_settings)
                                                         end
                                    },
                                  }).merge(@plugin_services || {}).freeze
  end

  def self.register_service(service_name, info_hash)
    @plugin_services ||= {}
    @plugin_services[service_name.to_sym] = info_hash.freeze
  end

  def self.default_allowable_services
    res = allowable_services.dup
    res.reject! { |_, info| info[:default] == false }
    res
  end
end
