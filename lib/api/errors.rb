#
# Copyright (C) 2013 Instructure, Inc.
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

class Error < RuntimeError
  attr_accessor :error_id, :response_status
  def initialize(error_id, opts)
    super(opts[:message])
    self.error_id = error_id
    self.response_status = opts[:status]
  end
end

module Errors
  # As we define potentially hundreds of errors here, I'm not sure yet how
  # we'll keep it organized.

  mattr_accessor :errors
  self.errors = {}

  def self.define_error(error_id, opts)
    self.errors[error_id] = opts
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

  module ControllerMethods
    def api_raise(error_id)
      error_info = Api::Errors.errors[error_id]
      # this will cause a 500 error, which is appropriate in this case
      raise(ArgumentError, "unknown api error #{error_id}") unless error_info
      raise Api::Error.new(error_id, error_info)
    end
  end

  # This is the official, publicly documented error response formatter for our
  # API JSON error responses.
  class Reporter < ActiveModel::BetterErrors::HashReporter
    def to_hash
      error_list = collection.to_hash.inject([]) do |list, (attribute, error_message_set)|
        error_message_set.each do |error_message|
          list << format_error_message(attribute, error_message)
        end
        list
      end
      { errors: error_list }
    end

    def format_error_message(attribute, error_message)
      field = (attribute == :base) ? nil : attribute
      {
        field: field,
        message: MessageFormatter.new(base, error_message).format_message,
        error_code: error_message.type,
      }
    end
  end

  class MessageFormatter < ::ActiveModel::BetterErrors::Formatter
    def format_message
      error_message.message || ::Api::Errors.errors[error_message.type].try(:[], :message)
    end
  end
end

end
