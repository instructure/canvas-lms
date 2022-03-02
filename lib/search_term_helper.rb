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
    # Searches the given scope for rows with column values
    # like the search term.
    #
    # @param scope The scope to limit the search to
    # @param attr  The attribute (column) the search should consider
    # @param search_term The term being searched for
    # @param normalize_unicode Defaults to false. If set to true, the
    #   search will consider the NFC and NFD representations of the
    #   given search_term
    #
    # @returns A new scope with the search filter applied. If the given
    #   scope was something like an AR relation (i.e. responds to 'where')
    #   returns a new scope of the same type. Otherwise returns an Array
    def search_by_attribute(scope, attr, search_term, normalize_unicode: false)
      return scope unless search_term.present?

      SearchTermHelper.validate_search_term(search_term)
      filtered_scope(scope, attr, search_term, normalize_unicode)
    end

    private

    def filtered_scope(*filter_args, normalize_unicode)
      # Return the filter query, don't bother worrying about unicode
      # normalization.
      return non_normalized_results(*filter_args) unless normalize_unicode

      # Return the filter query, but do worry about doing basic
      # unicode normalization. Adds an OR to the query to take into
      # account both NFC and NFD representations of the search_term
      #
      # See https://www.win.tue.nl/~aeb/linux/uc/nfc_vs_nfd.html
      normalized_results(*filter_args)
    end

    def non_normalized_results(scope, attr, search_term)
      return scope.where(wildcard("#{table_name}.#{attr}", search_term)) if scope.respond_to?(:where)

      scope.select { |item| item.matches_attribute?(attr, search_term) }
    end

    def normalized_results(scope, attr, search_term)
      # TODO: investigate the PG "NORMALIZE" function once on PG 13
      nfc_search_term, nfd_search_term = normalized_search_terms(search_term)

      if scope.respond_to?(:where)
        # Consider the NFC and NFD representations of the search_term by using an
        # OR operator
        return scope.where(wildcard("#{table_name}.#{attr}", nfc_search_term)).or(
          scope.where(wildcard("#{table_name}.#{attr}", nfd_search_term))
        )
      end

      scope.select do |item|
        item.matches_attribute?(attr, nfc_search_term) ||
          item.matches_attribute?(attr, nfd_search_term)
      end
    end

    def normalized_search_terms(search_term)
      [
        search_term.unicode_normalize,
        search_term.unicode_normalize(:nfd)
      ]
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  class SearchTermTooShortError < ArgumentError
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
