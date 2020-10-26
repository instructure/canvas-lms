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

module SearchTermHelper
  MIN_SEARCH_TERM_LENGTH = 2

  module ClassMethods
    def search_by_attribute(scope, attr, search_term)
      if search_term.present?
        SearchTermHelper.validate_search_term(search_term)
        if scope.respond_to?(:where)
          scope = scope.where(wildcard("#{self.table_name}.#{attr}", search_term))
        else
          scope = scope.select{|item| item.matches_attribute?(attr, search_term)}
        end
      end
      scope
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  class SearchTermTooShortError < ArgumentError
    def skip_error_report?
      true
    end

    def response_status
      :bad_request
    end

    def error_json
      {
        "errors" => [{
          "field" => "search_term",
          "code" => "invalid",
          "message" => "#{SearchTermHelper::MIN_SEARCH_TERM_LENGTH} or more characters is required"
        }]
      }
    end
  end

  def self.valid_search_term?(search_term)
    search_term.is_a?(String) && search_term.length >= MIN_SEARCH_TERM_LENGTH
  end

  def self.validate_search_term(search_term)
    raise SearchTermTooShortError unless valid_search_term?(search_term)
  end

  def matches_attribute?(attr, search_term)
    self[attr].to_s.downcase.include?(search_term.downcase)
  end
end
