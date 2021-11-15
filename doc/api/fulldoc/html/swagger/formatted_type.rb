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
#

# This class is used to guess type information. Normally, its examples are fed
# from data given by API docs' "@object {}" descriptions.
class FormattedType
  DATE_RE = /^\d\d\d\d-\d\d-\d\d$/
  DATETIME_RE = /^\d\d\d\d-\d\d-\d\d[T ]\d\d:\d\d:\d\dZ?$/

  def initialize(example)
    @example = example
  end

  def integer?
    return true if @example.is_a?(Integer)
    return false if @example.is_a?(Float)

    begin # try to convert string to integer
      Integer(@example)
      true
    rescue ArgumentError, TypeError
      false
    end
  end

  def float?
    return true if @example.is_a?(Float)
    return false if integer?

    begin # try to convert string to float
      Float(@example)
      true
    rescue ArgumentError, TypeError
      false
    end
  end

  def boolean?
    @example == true || @example == false
  end

  def string?
    @example.is_a?(String)
  end

  def date?
    string? && @example =~ DATE_RE
  end

  def datetime?
    string? && @example =~ DATETIME_RE
  end

  def type_and_format
    if integer?
      ["integer", "int64"]
    elsif float?
      ["number", "double"]
    elsif boolean?
      ["boolean", nil]
    elsif datetime?
      ["string", "date-time"]
    elsif date?
      ["string", "date"]
    else # string?
      ["string", nil]
    end
  end

  def to_hash
    type, format = type_and_format
    if format
      { "type" => type, "format" => format }
    else
      { "type" => type }
    end
  end
end
