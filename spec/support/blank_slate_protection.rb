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

require_relative "call_stack_utils"

module BlankSlateProtection
  module ActiveRecord
    def create_or_update(*, **)
      return super unless BlankSlateProtection.enabled?
      return super if caller.grep(BlankSlateProtection.exempt_patterns).present?

      location = CallStackUtils.best_line_for(caller)
      if caller.grep(/_context_hooks/).present?
        warn "\e[31mError: Don't create records inside `:all` hooks!"
        warn "See: " + location.join("\n") + "\e[0m"
        $stderr.puts
        warn "\e[33mTIP:\e[0m change this to `:each`, or if you are really concerned"
        warn "about performance, use `:once`. `:all` hooks are dangerous because"
        warn "they can leave around garbage that affects later specs"
      else
        warn "\e[31mError: Don't create records outside the rspec lifecycle! See: " + location.join("\n") + "\e[0m"
        $stderr.puts
        warn "\e[33mTIP:\e[0m move this into a `before`, `let` or `it`. Otherwise it will exist"
        warn "before *any* specs start, and possibly be deleted/modified before the"
        warn "spec that needs it actually runs."
      end
      $stderr.puts
      exit! 1
    end
  end

  module Example
    def run(*)
      BlankSlateProtection.disable { super }
    end
  end

  # switchman and once-ler have special snowflake context hooks where data
  # setup is allowed
  EXEMPT_PATTERNS = %w[
    specs_require_sharding
    r_spec_helper
    add_onceler_hooks
    recreate_persistent_test_shards
    truncate_all_tables
  ].freeze

  class << self
    def enabled?
      @enabled
    end

    def install!
      ::RSpec::Core::Example.prepend Example
      ::ActiveRecord::Base.include ActiveRecord
      @enabled = true
    end

    def disable
      @enabled = false
      yield
    ensure
      @enabled = true
    end

    def exempt_patterns
      Regexp.new(EXEMPT_PATTERNS.map { |pattern| Regexp.escape(pattern) }.join("|"))
    end
  end
end
