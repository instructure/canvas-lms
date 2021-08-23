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

class RemoveWeirdOldQuizSubmissionEventPartitions < ActiveRecord::Migration[4.2]
  tag :postdeploy

  BAD_PARTITIONS = [
    Time.new(2014, 11),
    Time.new(2014, 12),
    Time.new(2015, 1)
  ].freeze

  def up
    partman = CanvasPartman::PartitionManager.create(Quizzes::QuizSubmissionEvent)

    # These partitions should have long since been recycled, unless your db
    # was created in the last 6 months or so. Remove them since 1. they
    # aren't needed and 2. they make snapshot<->full migration testing a
    # little harder.
    #
    # TODO: This migration can be safely removed once we're sure all
    # environments have run it (since no other migrations will create
    # these partitions again)
    BAD_PARTITIONS.each do |date|
      partman.drop_partition(date) if partman.partition_exists?(date)
    end
  end
end
