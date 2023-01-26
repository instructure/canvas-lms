# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class RemoveRedundantQuizSubmissionEventIndices < CanvasPartman::Migration
  tag :postdeploy

  self.base_class = Quizzes::QuizSubmissionEvent

  def up
    # Fix partitions that got extra indices from the now-deleted
    # AddIndicesToQuizSubmissionEvents (probaby none, unless you set up
    # your database in the last 6 months).
    #
    # TODO: This migration can be safely removed once we're sure all
    # environments have run it (since no other migrations will create
    # these extra indices again)
    with_each_partition do |partition|
      index_ns = partition.sub("quiz_submission_events", "qse")

      next unless connection.index_exists?(partition, :created_at, name: "#{index_ns}_idx_on_created_at")

      remove_index partition, name: "#{index_ns}_idx_on_created_at"
      remove_index partition, name: "#{index_ns}_predecessor_locator_idx"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
