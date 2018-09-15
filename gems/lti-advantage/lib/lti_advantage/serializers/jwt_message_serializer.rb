#
# Copyright (C) 2018 - present Instructure, Inc.
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

module LtiAdvantage::Serializers
  class JwtMessageSerializer
    IMS_CLAIM_PREFIX = 'https://purl.imsglobal.org/spec/lti/claim/'.freeze
    DL_CLAIM_PREFIX = 'https://purl.imsglobal.org/spec/lti-dl/claim/'.freeze

    STANDARD_IMS_CLAIMS = %w(
      context
      custom
      custom
      deployment_id
      launch_presentation
      lis
      message_type
      resource_link
      role_scope_mentor
      roles
      tool_platform
      version
    ).freeze

    DEEP_LINKING_CLAIMS = %w(
      deep_linking_settings
      content_items
    ).freeze

    def initialize(object)
      @object = object
    end

    def serializable_hash
      hash = apply_claim_prefixes(@object.as_json.compact)
      promote_extensions(hash)
    end

    private

    def promote_extensions(hash)
      extensions = hash.delete('extensions')
      extensions.present? ? hash.merge(extensions) : hash
    end

    def apply_claim_prefixes(hash)
      hash.transform_keys do |key|
        if STANDARD_IMS_CLAIMS.include?(key)
          "#{IMS_CLAIM_PREFIX}#{key}"
        elsif DEEP_LINKING_CLAIMS.include?(key)
          "#{DL_CLAIM_PREFIX}#{key}"
        else
          key
        end
      end
    end
  end
end