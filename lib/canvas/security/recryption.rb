# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module Canvas::Security
  # This was originally part of Canvas::Security directly
  # as the module method "re_encrypt_data", but with it's
  # dependencies on Models and PluginSetting, it couldn't
  # be extracted to the "canvas_security" gem, which
  # is why it now lives in it's own module.
  #
  # This operation spans all the data on a shard that is encrypted
  # in the db, decrypts it, and re-encrypts again using the same
  # key but a different salt.  This is useful in cases where, for
  # example, we're moving data between databases, and we want the
  # VALUE to remain the same at the moment but don't want the old salt present in
  # the previous database to have any utility for decrypting the
  # value from the new database.
  class Recryption
    def self.execute(encryption_key)
      {
        Account => {
          encrypted_column: :turnitin_crypted_secret,
          salt_column: :turnitin_salt,
          key: "instructure_turnitin_secret_shared"
        },
        AuthenticationProvider => {
          encrypted_column: :auth_crypted_password,
          salt_column: :auth_password_salt,
          key: "instructure_auth"
        },
        UserService => {
          encrypted_column: :crypted_password,
          salt_column: :password_salt,
          key: "instructure_user_service"
        },
        User => {
          encrypted_column: :otp_secret_key_enc,
          salt_column: :otp_secret_key_salt,
          key: "otp_secret_key"
        }
      }.each do |(model, definition)|
        model.where("#{definition[:encrypted_column]} IS NOT NULL")
             .select([:id, definition[:encrypted_column], definition[:salt_column]])
             .find_each do |instance|
          cleartext = Canvas::Security.decrypt_password(instance.read_attribute(definition[:encrypted_column]),
                                                        instance.read_attribute(definition[:salt_column]),
                                                        definition[:key],
                                                        encryption_key)
          new_crypted_data, new_salt = Canvas::Security.encrypt_password(cleartext, definition[:key])
          model.where(id: instance)
               .update_all(definition[:encrypted_column] => new_crypted_data,
                           definition[:salt_column] => new_salt)
        end
      end

      PluginSetting.find_each do |settings|
        unless settings.plugin
          warn "Unknown plugin #{settings.name}"
          next
        end
        Array(settings.plugin.encrypted_settings).each do |setting|
          cleartext = Canvas::Security.decrypt_password(settings.settings[:"#{setting}_enc"],
                                                        settings.settings[:"#{setting}_salt"],
                                                        "instructure_plugin_setting",
                                                        encryption_key)
          new_crypted_data, new_salt = Canvas::Security.encrypt_password(cleartext, "instructure_plugin_setting")
          settings.settings[:"#{setting}_enc"] = new_crypted_data
          settings.settings[:"#{setting}_salt"] = new_salt
          settings.settings_will_change!
        end
        settings.save! if settings.changed?
      end
    end
  end
end
