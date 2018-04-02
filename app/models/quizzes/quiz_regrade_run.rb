#
# Copyright (C) 2013 - present Instructure, Inc.
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

class Quizzes::QuizRegradeRun < ActiveRecord::Base
  self.table_name = 'quiz_regrade_runs'

  belongs_to :quiz_regrade, class_name: 'Quizzes::QuizRegrade'

  validates_presence_of :quiz_regrade_id

  def self.perform(regrade)
    run = create!(quiz_regrade_id: regrade.id, started_at: Time.now)
    yield
    run.finished_at = Time.now
    run.save!
  end

  has_a_broadcast_policy
  set_broadcast_policy do |policy|
    policy.dispatch :quiz_regrade_finished
    policy.to { teachers }
    policy.whenever { |run| run.send_messages? }
  end

  def send_messages?
    old, new = saved_changes['finished_at']
    !!(new && old.nil?) && Quizzes::QuizRegradeRun.where(quiz_regrade_id: quiz_regrade).count == 1
  end

  delegate :teachers, :quiz, to: :quiz_regrade
end
