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

class CreateInitialQuizSubmissionEventPartitions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    Quizzes::QuizSubmissionEventPartitioner.process(true)
  end

  def down
    # We can't delete the partitions because we no longer know which partitions
    # we created in this first place at this stage; Time.now() which was used
    # in #up may not be in the same month #down() is called.
  end
end
