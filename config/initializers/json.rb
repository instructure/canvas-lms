#
# Copyright (C) 2011 - present Instructure, Inc.
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
