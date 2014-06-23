#
# Copyright (C) 2011 Instructure, Inc.
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

require_dependency 'sis/common'

module SIS
  class BaseImporter
    def initialize(root_account, opts)
      @root_account = root_account
      @batch = opts[:batch]
      @batch_user = opts[:batch_user]
      @logger = opts[:logger] || Rails.logger
      @sis_options = {
          :override_sis_stickiness => opts[:override_sis_stickiness],
          :add_sis_stickiness => opts[:add_sis_stickiness],
          :clear_sis_stickiness => opts[:clear_sis_stickiness]
        }
    end
  end
end
