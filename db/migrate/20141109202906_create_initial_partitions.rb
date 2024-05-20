# frozen_string_literal: true

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

class CreateInitialPartitions < ActiveRecord::Migration[7.0]
  tag :predeploy

  def up
    [Auditors::ActiveRecord::AuthenticationRecord,
     Auditors::ActiveRecord::CourseRecord,
     Auditors::ActiveRecord::FeatureFlagRecord,
     Auditors::ActiveRecord::GradeChangeRecord,
     Auditors::ActiveRecord::PseudonymRecord].each do |klass|
      CanvasPartman::PartitionManager.create(klass).create_initial_partitions
    end
    CanvasPartman::PartitionManager.create(Message)
                                   .create_initial_partitions(Messages::Partitioner::PRECREATE_TABLES)
    Quizzes::QuizSubmissionEventPartitioner.process(true)
    CanvasPartman::PartitionManager.create(SimplyVersioned::Version)
                                   .create_initial_partitions(SimplyVersioned::Partitioner::PRECREATE_TABLES)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
