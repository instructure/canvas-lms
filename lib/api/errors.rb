# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Api
  module Errors
    # As we define potentially hundreds of errors here, I'm not sure yet how
    # we'll keep it organized.

    mattr_accessor :errors
    self.errors = {}

    def self.define_error(error_id, opts)
      errors[error_id] = opts
    end

    define_error :deprecated_request_syntax,
                 message: "This request syntax has been deprecated",
                 status: :bad_request

    define_error :mixing_authentication_types,
                 message: "Can not mix authentication types"

    define_error :multiple_cas_configs,
                 message: "Only one CAS config is supported"

    def self.error_message(error_id)
      error_info = Api::Errors.errors[error_id]
      raise(ArgumentError, "unknown api error #{error_id}") unless error_info

      error_info[:message]
    end

    # This is the official, publicly documented error response formatter for our
    # API JSON error responses.
    class Reporter
      def self.to_hash(errors)
        errors = errors.map do |error|
          {
            field: (error.attribute == :base) ? nil : error.attribute,
            message: error.message || ::Api::Errors.errors[error.type].try(:[], :message),
            error_code: error.type,
          }
        end

        { errors: }
      end
    end
  end
end
