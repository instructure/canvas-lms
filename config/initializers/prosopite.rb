# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module ProsopiteInitializer
  def self.configure!
    Rails.application.config.after_initialize do
      # Only report N+1 cases where query count is >= 3
      Prosopite.min_n_queries = 3
      # Send warnings to the Rails log
      Prosopite.rails_logger = true
      # Send warnings to log/prosopite.log for development
      Prosopite.prosopite_logger = true if Rails.env.development?
    end
  end
end

ProsopiteInitializer.configure!
