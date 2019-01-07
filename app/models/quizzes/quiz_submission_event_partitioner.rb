#
# Copyright (C) 2014 - present Instructure, Inc.
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

class Quizzes::QuizSubmissionEventPartitioner
  cattr_accessor :logger

  def self.process(in_migration=false)
    Shackles.activate(:deploy) do
      Quizzes::QuizSubmissionEvent.transaction do
        log '*' * 80
        log '-' * 80

        partman = CanvasPartman::PartitionManager.create(Quizzes::QuizSubmissionEvent)

        partman.ensure_partitions(Setting.get('quiz_events_partitions_precreate_months', 2).to_i)

        partman.prune_partitions(Setting.get("quiz_events_partitions_keep_months", 6).to_i)

        log 'Done. Bye!'
        log '*' * 80
        ActiveRecord::Base.connection_pool.current_pool.disconnect! unless in_migration || Rails.env.test?
      end
    end
  end

  def self.log(*args)
    logger.info(*args) if logger
  end
end
