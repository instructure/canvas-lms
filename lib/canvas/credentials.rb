# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

# Adapted from ActiveSupport::EncryptedConfiguration
module Canvas
  class Credentials
    delegate :[], :fetch, to: :config
    delegate_missing_to :options

    Canvas::Reloader.on_reload do
      @config = nil
      @options = nil
    end

    def initialize(parent)
      @parent = parent
    end

    def config
      @config ||= @parent.config.to_h.merge(unencrypted_secrets.deep_symbolize_keys).merge(vault_secrets.deep_symbolize_keys)
    end

    private
    def options
      @options ||= ActiveSupport::InheritableOptions.new(config)
    end

    def unencrypted_secrets
      return {} unless Rails.env.test?

      ConfigFile.load("credentials.#{Rails.env}", nil)
    end

    # Don't cache in redis since we are memoizing it in process memory too
    def vault_secrets
      Canvas::Vault.read(Canvas::Vault.kv_mount + '/data/secrets', required: false, cache: false)&.[](:data) || {}
    end
  end
end