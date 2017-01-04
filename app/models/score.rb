#
# Copyright (C) 2016 Instructure, Inc.
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

class Score < ActiveRecord::Base
  include Canvas::SoftDeletable

  attr_accessible :current_score, :final_score, :grading_period

  belongs_to :enrollment
  belongs_to :grading_period
  has_one :course, through: :enrollment

  validates :enrollment, presence: true
  validates :current_score, :final_score, numericality: true, allow_nil: true
  validates_uniqueness_of :enrollment_id, scope: :grading_period_id, conditions: -> { active }

  def current_grade
    score_to_grade(current_score)
  end

  def final_grade
    score_to_grade(final_score)
  end

  delegate :score_to_grade, to: :course
end
