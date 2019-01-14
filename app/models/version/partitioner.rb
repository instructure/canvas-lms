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

class Version::Partitioner
  cattr_accessor :logger

  def self.precreate_tables
    Setting.get('versions_precreate_tables', 2).to_i
  end

  def self.process
    Shackles.activate(:deploy) do
      Version.transaction do
        log '*' * 80
        log '-' * 80

        partman = CanvasPartman::PartitionManager.create(Version)

        partman.ensure_partitions(precreate_tables)

        log 'Done. Bye!'
        log '*' * 80
      end
      ActiveRecord::Base.connection_pool.current_pool.disconnect! unless Rails.env.test?
    end
  end

  def self.log(*args)
    logger.info(*args) if logger
  end
end
