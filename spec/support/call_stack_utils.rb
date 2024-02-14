# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module CallStackUtils
  def self.best_line_for(call_stack)
    lines = CallStackUtils.prune_backtrace!(call_stack)
    root = Rails.root.to_s + "/"
    lines.map { |line| line.sub(root, "").sub(/:in .*/, "") }
  end

  # (re-)raise the exception while preserving its backtrace
  def self.raise(exception)
    super(exception.class, exception.message, exception.backtrace)
  end

  APP_IGNORE_REGEX = %r{/spec/(support|selenium/test_setup/)}
  def self.prune_backtrace!(bt)
    line_regex = RSpec.configuration.in_project_source_dir_regex
    # remove things until we get to the frd error cause
    if bt.any? { |line| line =~ line_regex && line !~ APP_IGNORE_REGEX }
      bt.shift while bt.first !~ line_regex || bt.first =~ APP_IGNORE_REGEX
      bt.pop while bt.last !~ line_regex || bt.last =~ APP_IGNORE_REGEX
    end
    bt
  end

  module ExceptionPresenter
    def exception_backtrace
      bt = super
      # for our custom matchers/validators/finders/etc., prune their lines
      # from the top of the stack so that you get a pretty/useful error
      # message and backtrace
      if /\A(RSpec::|Selenium::WebDriver::Error::|SeleniumExtensions::|GreatExpectations::)/.match?(exception_class_name)
        CallStackUtils.prune_backtrace! bt
      end
      bt
    end
  end
end

ignore_regex = RSpec::CallerFilter::IGNORE_REGEX
RSpec::CallerFilter.send :remove_const, :IGNORE_REGEX # rubocop:disable RSpec/RemoveConst
RSpec::CallerFilter::IGNORE_REGEX = Regexp.union(ignore_regex, CallStackUtils::APP_IGNORE_REGEX)
RSpec::Core::Formatters::ExceptionPresenter.prepend CallStackUtils::ExceptionPresenter
