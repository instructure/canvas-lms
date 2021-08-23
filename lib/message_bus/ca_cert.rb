# frozen_string_literal: true

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

##
# CaCert wraps the process of ensuring we have a trust
# certificate on disk in a known location for the pulsar client
# to reference. This is necessary to make a trusted connection
# ( https://pulsar.apache.org/docs/en/security-tls-transport/ )
# and is pretty safe to have everywhere because it's the public
# side of the certificate authority keypair.
#
# If you are wanting to use the message bus library and are here
# trying to figure out what you need to do with this class,
# the answer SHOULD be "nothing".  This is an internal
# implementation detail, you should interact with the
# MessageBus outer module directly.
module MessageBus
  class CertSyncError < StandardError
  end

  module CaCert
    def self.ensure_presence!(config_hash)
      cert_path_on_disk = config_hash.fetch("PULSAR_CERT_PATH", nil)
      if cert_path_on_disk.nil?
        Rails.logger.info "[MESSAGE_BUS] No cert path found in config, assuming we have a non-auth pulsar cluster here."
        return true
      end
      return true if File.exist?(cert_path_on_disk)

      cert_vault_path = config_hash.fetch("PULSAR_CERT_VAULT_PATH")
      process_file_version = cert_path_on_disk.gsub(".pem", "-#{Process.pid}-#{Thread.current.object_id}.pem")
      self.write_cert(cert_vault_path, process_file_version)
      # it's possible another process has already
      # moved this file into place, in which case do nothing.
      return true if File.exist?(cert_path_on_disk)
      # renaming is atomic, and overwrites silently.
      # if two processes are racing and each write
      # their own version of the file and rename them into place, the last write wins,
      # which is fine because the content is the same
      File.rename(process_file_version, cert_path_on_disk)
      true
    end

    def self.write_cert(cert_vault_path, process_file_version)
      vault_contents = Canvas::Vault.read(cert_vault_path)
      cert_string = vault_contents.fetch(:certificate)
      File.open(process_file_version, "wb") { |f| f.write(cert_string) }
    end
  end
end