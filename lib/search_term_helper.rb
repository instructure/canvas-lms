module SearchTermHelper
  MIN_SEARCH_TERM_LENGTH = 3

  module ClassMethods
    def search_by_attribute(scope, attr, search_term)
      if search_term.present?
        SearchTermHelper.validate_search_term(search_term)
        scope = scope.where(wildcard("#{self.table_name}.#{attr}", search_term))
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
end