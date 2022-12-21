# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class SentryProxy
  def self.capture(exception, data, level = :error)
    if exception.is_a?(String) || exception.is_a?(Symbol)
      Sentry.capture_message(exception.to_s, **data) if reportable?(exception.to_s, level)
    elsif reportable?(exception, level)
      Sentry.capture_exception(exception, **data)
    end
  end

  # There are some errors we don't care to report to sentry because
  # they don't indicate a problem, but not all of them are necessarily
  # in the canvas codebase (and so we might not know about them at the time we
  #  configure the sentry client in an initializer).  This allows plugins and extensions
  # to register their own errors that they don't want to get reported to sentry
  def self.register_ignorable_error(error_class)
    @ignorable_errors = (ignorable_errors << error_class.to_s).uniq
  end

  def self.ignorable_errors
    @ignorable_errors ||= []
  end

  def self.clear_ignorable_errors
    @ignorable_errors = []
  end

  def self.reportable?(exception, error_level)
    # :info and :warn levels specifically introduced
    # to avoid sentry noise for inactionable errors.
    return false unless error_level == :error

    if exception.is_a?(String)
      !ignorable_errors.include?(exception.to_s)
    else
      !ignorable_errors.include?(exception.class.to_s)
    end
  end
end
