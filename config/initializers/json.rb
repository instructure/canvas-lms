# A bunch of optimizations to Rails 2.3.x JSON handling
if CANVAS_RAILS2
  # CVE-2013-0333
  # https://groups.google.com/d/topic/rubyonrails-security/1h2DR63ViGo/discussion
  # With Rails 2.3.16 we could remove this line, but we still prefer JSONGem for performance reasons
  ActiveSupport::JSON.backend = "JSONGem"
  # MultiJson default options for oj are:
  # defaults :load, :mode => :strict, :symbolize_keys => false
  # defaults :dump, :mode => :compat, :time_format => :ruby
  #
  # This gives us ActiveSupport-compatible behavior for to_json and time formats
  MultiJson.use(:oj)

  module ActionController
    ParamsParser.class_eval do
      # Unfortunately we have to override this whole method just to make the
      # one-line change to the JSON parsing. See the commented line for what
      # changed. We don't want to override ActiveSupoort::JSON.decode globally
      # in Rails 2.3, due to some incompatabilities.
      #
      # This all goes away in Rails 3.2 due to the new
      # ActiveSupport::JSON.backend support.
      def parse_formatted_parameters(env)
        request = Request.new(env)

        return false if request.content_length.zero?

        mime_type = content_type_from_legacy_post_data_format_header(env) || request.content_type
        strategy = ActionController::Base.param_parsers[mime_type]

        return false unless strategy

        case strategy
          when Proc
            strategy.call(request.raw_post)
          when :xml_simple, :xml_node
            body = request.raw_post
            body.blank? ? {} : Hash.from_xml(body).with_indifferent_access
          when :yaml
            YAML.load(request.raw_post)
          when :json
            body = request.raw_post
            if body.blank?
              {}
            else
              # Here is the changed line, just using a faster JSON parser
              data = MultiJson.load(body)
              data = {:_json => data} unless data.is_a?(Hash)
              data.with_indifferent_access
            end
          else
            false
        end
      rescue Exception => e # YAML, XML or Ruby code block errors
        logger.debug "Error occurred while parsing request parameters.\nContents:\n\n#{request.raw_post}"

        raise
          { "body" => request.raw_post,
            "content_type" => request.content_type,
            "content_length" => request.content_length,
            "exception" => "#{e.message} (#{e.class})",
            "backtrace" => e.backtrace }
      end
    end
  end

  # JSON::Ext overwrites Rails' implemenation of these.
  # And does dumb stuff instantiating a state object and temp buffer and crap
  # which is really slow if you have 50,000 nil values.
  # Just return teh constant values.
  class NilClass
    def as_json(*args)
      self
    end

    def to_json(*args)
      'null'
    end
  end

  class FalseClass
    def as_json(*args)
      self
    end

    def to_json(*args)
      'false'
    end
  end

  class TrueClass
    def as_json(*args)
      self
    end

    def to_json(*args)
      'true'
    end
  end

  # This changes a "perfect" reference check for a fast one.  If you see this
  # exception, you can comment this out, and then the actual rails code will
  # raise a similar exception on the very first duplicate object, to help you
  # pinpoint the problem.
  ActiveSupport::JSON::Encoding.module_eval do
    def self.encode(value, options = nil)
      options = {} unless Hash === options
      depth = (options[:recursion_depth] ||= 1)
      raise CircularReferenceError, 'something references itself (probably)' if depth > 1000
      options[:recursion_depth] = depth + 1
      Api.stringify_json_ids(value) if options[:stringify_json_ids]
      value.to_json(options)
    ensure
      options[:recursion_depth] = depth
    end
  end
else
  # In rails 3.2, this calls MultiJson.use(:oj)
  ActiveSupport::JSON.backend = :oj
  MultiJson.dump_options = {:escape_mode => :xss_safe}

  # Rails4 gives an option to opt out of encoding BigDecimal json as a string
  if ActiveSupport.respond_to?(:encode_big_decimal_as_string)
    ActiveSupport.encode_big_decimal_as_string = false

  # Rails3 changes BigDecimal #to_json to encode as a string. This breaks
  # bw-compat in our apis, so this switches it back to the native behavior.
  else
    require 'bigdecimal'

    class BigDecimal
      def as_json(options = nil)
        if finite?
          self
        else
          NilClass::AS_JSON
        end
      end
    end
  end
end
