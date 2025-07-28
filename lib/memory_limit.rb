# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

# example usage:
#
# MemoryLimit.apply(2.gigabytes) do
#   (something we want to guard against unbounded memory usage)
# end
#
# note that this applies to the entire process via rlimit, not to the block or thread,
# although it changes the rlimit back afterward

class MemoryLimit
  def self.apply(allowed_memory)
    # retrieve the current and maximum limits
    # note that lowering the maximum limit is irreversible so we will be careful to preserve it
    cur, max = Process.getrlimit(:DATA)

    begin
      Process.setrlimit(:DATA, allowed_memory, max)
    rescue Errno::EINVAL
      # if the OS doesn't like our limit, just run the block
      Rails.logger.warn "MemoryLimit: failed to set limit to #{allowed_memory}"
      return yield
    end

    # run the block, then restore the original limit
    begin
      yield
    ensure
      Process.setrlimit(:DATA, cur, max)
    end
  end
end
