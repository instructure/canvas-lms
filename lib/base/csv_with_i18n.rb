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
class CSVWithI18n < CSV
  BYTE_ORDER_MARK = "\xEF\xBB\xBF"

  def initialize(data, **options)
    @include_bom = options.delete(:include_bom)
    super(data, **options)
    raise "include_bom and write_headers cannot both be true" if write_headers? && @include_bom
  end

  def <<(row)
    if @include_bom && !@bom_written
      @io.write(BYTE_ORDER_MARK)
      @bom_written = true
    end
    super(row)
  end

  def self.csv_i18n_settings(user, options = {})
    options[:col_sep] ||= determine_column_separator(user)
    options[:encoding] ||= I18n.t("csv.encoding", "UTF-8")

    # Wikipedia: Microsoft compilers and interpreters, and many pieces of software on Microsoft Windows such as
    # Notepad treat the BOM as a required magic number rather than use heuristics. These tools add a BOM when saving
    # text as UTF-8, and cannot interpret UTF-8 unless the BOM is present or the file contains only ASCII.
    # https://en.wikipedia.org/wiki/Byte_order_mark#UTF-8
    options[:include_bom] = include_bom?(user, options[:encoding])

    options
  end

  def self.include_bom?(user, encoding)
    encoding == "UTF-8" && user.feature_enabled?(:include_byte_order_mark_in_gradebook_exports)
  end
  private_class_method :include_bom?

  def self.determine_column_separator(user)
    return ";" if user.feature_enabled?(:use_semi_colon_field_separators_in_gradebook_exports)
    return "," unless user.feature_enabled?(:autodetect_field_separators_for_gradebook_exports)

    (I18n.t("number.format.separator", ".") == ",") ? ";" : ","
  end
  private_class_method :determine_column_separator
end
