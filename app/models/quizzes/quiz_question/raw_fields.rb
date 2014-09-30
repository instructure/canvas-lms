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

class Quizzes::QuizQuestion::RawFields

  class FieldTooLongError < RuntimeError; end

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
    Sanitize.clean(html || "", CanvasSanitize::SANITIZE)
  end

  private
  def check_length(html, type, max)
    if html && html.length > max
      raise FieldTooLongError.new("#{type} is too long, max length is #{max} characters" )
    end
    html
  end

  def key_to_type(key)
    key.to_s.humanize.downcase
  end
end
