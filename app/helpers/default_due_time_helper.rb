# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DefaultDueTimeHelper
  def default_due_time_options(context)
    inherited_value = if context.is_a?(Course)
                        context.account.default_due_time&.dig(:value)
                      elsif !context.root_account?
                        context.parent_account.default_due_time&.dig(:value)
                      end
    inherited_value ||= "23:59"

    format_time = ->(ts) { I18n.l(Time.zone.parse(ts), format: :tiny) }
    time_option = ->(ts) { [format_time.call(ts), ts] } # [human-readable text, option value] pair

    all_times = (1..23).map { |hour| time_option.call(format("%02d:00:00", hour)) } + [time_option.call("23:59:59")]

    # if the current setting isn't on the hour, add it to the options so saving account settings won't clear it
    current_setting = context.default_due_time
    current_setting = current_setting[:value] if current_setting.is_a?(Hash)
    current_setting = normalize_due_time(current_setting)
    if current_setting && !all_times.map(&:last).include?(current_setting)
      all_times << time_option.call(current_setting)
      all_times.sort_by!(&:last)
    end

    [[I18n.t("Account default (%{time})", time: format_time.call(inherited_value)), "inherit"]] + all_times
  end

  def default_due_time_key(context)
    if context.is_a?(Course)
      normalize_due_time(context.settings[:default_due_time]) || "inherit"
    else
      h = context.default_due_time
      (h&.dig(:value).nil? || h[:inherited]) ? "inherit" : normalize_due_time(h[:value])
    end
  end

  def normalize_due_time(due_time)
    return nil if due_time.blank? || due_time == "inherit"

    Time.zone.parse(due_time)&.strftime("%H:%M:%S")
  rescue ArgumentError
    nil
  end
end
