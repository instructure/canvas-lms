
require 'json/jwt'
require 'oj_mimic_json' # have to load after json/jwt or else the oj_mimic_json will make it never load
Oj.default_options = {:escape_mode => :xss_safe}

ActiveSupport::JSON::Encoding.time_precision = 0