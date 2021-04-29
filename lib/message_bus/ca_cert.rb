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

      cert_uri = config_hash.fetch("PULSAR_CERT_URI")
      lock_key = "message_bus_cert_file"
      nonce = LocalCache.lock(lock_key, {})
      if nonce
        if File.exist?(cert_path_on_disk)
          # it got written by another process after checking but before obtaining the lock
          LocalCache.unlock(lock_key, nonce)
          return true
        end
        self.write_cert(cert_uri, cert_path_on_disk)
        LocalCache.unlock(lock_key, nonce)
        return true
      else
        # some other process on the box is currently writing the cert, give it a minute
        wait_count = 0
        return true if File.exist?(cert_path_on_disk)

        while wait_count <= 5 do
          sleep(0.2)
          return true if File.exist?(cert_path_on_disk)
          wait_count += 1
        end
        raise ::MessageBus::CertSyncError, "Failure to synchronize politely on #{cert_path_on_disk} while fetching message bus hash"
      end
    end

    def self.write_cert(uri, path)
      cert_uri = URI.parse(uri)
      conn = CanvasHttp.connection_for_uri(cert_uri)
      conn.start()
      conn.get(cert_uri.path) do |response|
        File.open(path, "wb") { |f| f.write(response) }
      end
    ensure
      conn.finish()
    end
  end
end