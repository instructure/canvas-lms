
require 'json/jwt'
require 'oj_mimic_json' # have to load after json/jwt or else the oj_mimic_json will make it never load
Oj.default_options = { escape_mode: :xss_safe, bigdecimal_as_decimal: true }

ActiveSupport::JSON::Encoding.time_precision = 0

unless CANVAS_RAILS4_2
  class BigDecimal
    remove_method :as_json

    def as_json(options = nil) #:nodoc:
      if finite?
        CanvasRails::Application.instance.config.active_support.encode_big_decimal_as_string ? to_s : self
      else
        nil
      end
    end
  end
end
