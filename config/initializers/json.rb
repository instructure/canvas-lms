# frozen_string_literal: true

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

Oj.optimize_rails

Oj.default_options = { mode: :rails, escape_mode: :xss_safe, bigdecimal_as_decimal: true }

ActiveSupport::JSON::Encoding.time_precision = 0

# This overrides the behavior defined in:
# activesupport/lib/active_support/core_ext/object/json.rb. We use BigDecimal
# in quiz numerical questions. See specs around numerical question answers in
# spec/apis/v1/quizzes/quiz_submission_questions_api_spec.rb
class BigDecimal
  remove_method :as_json

  def as_json(*) # :nodoc:
    if finite?
      CanvasRails::Application.instance.config.active_support.encode_big_decimal_as_string ? to_s : to_f
    else
      nil
    end
  end
end
