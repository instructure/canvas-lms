# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Canvas
  module AWS
    OLD_KEYS_SYMBOLS = %i[kinesis_endpoint
                          kinesis_port
                          s3_endpoint
                          s3_port
                          server
                          port
                          sqs_endpoint
                          sqs_port
                          use_ssl].freeze
    OLD_KEYS = (OLD_KEYS_SYMBOLS + OLD_KEYS_SYMBOLS.map(&:to_s)).freeze

    def self.validate_v2_config(config, source)
      old_keys = config.keys & OLD_KEYS
      unless old_keys.empty?
        ActiveSupport::Deprecation.warn(
          "Configuration options #{old_keys.join(", ")} for #{source} are no longer supported; just configure endpoint with a full URI and/or use region to form regional endpoints",
          caller(1)
        )
        config = config.except(*OLD_KEYS)
      end
      unless config.key?(:region) || config.key?("region")
        ActiveSupport::Deprecation.warn("Please supply region for #{source}; for now defaulting to us-east-1", caller(1))
        config = config.dup
        config[:region] = "us-east-1"
      end
      config
    end
  end
end
