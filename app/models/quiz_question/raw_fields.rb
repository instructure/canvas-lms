class QuizQuestion::RawFields
  def initialize(fields)
    @fields = fields
  end

  def fetch_any(key, default="")
    unless key.is_a?(Array)
      @fields[key] || default
    else
      found = key.find { |k| @fields.key?(k) }
      @fields[found] || default
    end
  end

  def fetch_with_enforced_length(key, opts={})
    default = opts.fetch(:default, "")
    max_size = opts.fetch(:max_size, 16.kilobyte)

    check_length(fetch_any(key, default), key_to_type(key), max_size)
  end

  def sanitize(html)
    Sanitize.clean(html || "", Instructure::SanitizeField::SANITIZE)
  end

  private
  def check_length(html, type, max)
    raise "The text for #{type} is too long, max length is #{max}" if html && html.length > max
    html
  end

  def key_to_type(key)
    key.to_s.humanize.downcase
  end
end
