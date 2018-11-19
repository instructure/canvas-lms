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

module Lti::Ims
  module AdvantageErrors
    class AdvantageServiceError < StandardError
      attr_accessor :field, :api_message, :status_code, :opts

      def initialize(msg=nil, opts={})
        super(msg)
        @api_message = opts.fetch(:api_message, 'Failed LTI Advantage service invocation')
        @status_code = opts.fetch(:status_code, :internal_server_error)
        @opts = opts
      end

      def message
        [super, api_message].compact.uniq.join(" :: ")
      end
    end

    # Anything that could reasonably map to a 4xx response
    class AdvantageClientError < AdvantageServiceError
      def initialize(msg=nil, opts={})
        super(msg, { api_message: 'Invalid LTI Advantage service invocation', status_code: :bad_request }.merge(opts))
      end
    end

    class InvalidLaunchError < AdvantageClientError
      def initialize(msg=nil, opts={})
        super(msg, { api_message: 'Invalid LTI launch attempt', status_code: :bad_request }.merge(opts))
      end
    end

    class AdvantageSecurityError < AdvantageClientError
      def initialize(msg=nil, opts={})
        super(msg, { api_message:'Service invocation refused', status_code: :unauthorized }.merge(opts))
      end
    end
    class InvalidAccessToken < AdvantageSecurityError
      def initialize(msg=nil, opts={})
        super(msg, { api_message:'Invalid access token' }.merge(opts))
      end
    end
    class InvalidAccessTokenSignature < InvalidAccessToken
      def initialize(msg=nil, opts={})
        super(msg, { api_message: 'Invalid access token signature' }.merge(opts))
      end
    end
    class InvalidAccessTokenSignatureType < InvalidAccessToken
      def initialize(msg=nil, opts={})
        super(msg, { api_message: 'Access token signature algorithm not allowed' }.merge(opts))
      end
    end
    class MalformedAccessToken < InvalidAccessToken
      def initialize(msg=nil, opts={})
        super(msg, { api_message: 'Invalid access token format' }.merge(opts))
      end
    end
    class InvalidAccessTokenClaims < InvalidAccessToken
      def initialize(msg=nil, opts={})
        super(msg, { api_message: 'Access token contains invalid claims' }.merge(opts))
      end
    end

    class InvalidResourceLinkIdFilter < AdvantageClientError
      def initialize(msg=nil, opts={})
        super(msg, { api_message: 'Invalid \'rlid\' parameter' }.merge(opts))
      end
    end
  end
end
