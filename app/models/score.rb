#
# Copyright (C) 2011 - present Instructure, Inc.
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

  belongs_to :enrollment, inverse_of: :scores
  belongs_to :grading_period, optional: true
  belongs_to :assignment_group, optional: true
  has_one :course, through: :enrollment
  has_one :score_metadata

  validates :enrollment, presence: true
  validates :current_score, :unposted_current_score,
    :final_score, :unposted_final_score, :override_score,
    numericality: true, allow_nil: true

  validate :scorable_association_check

  before_validation :set_course_score, unless: :course_score_changed?

  set_policy do
    given do |user, _session|
      (user&.id == enrollment.user_id && !course.hide_final_grades?) ||
        course.grants_any_right?(user, :manage_grades, :view_all_grades) ||
        enrollment.user.grants_right?(user, :read_as_parent)
    end
    can :read
  end

  alias original_destroy destroy
  private :original_destroy
  def destroy
    score_metadata.destroy if score_metadata.present?
    original_destroy
  end

  alias original_destroy_permanently! destroy_permanently!
  private :original_destroy_permanently!
  def destroy_permanently!
    ScoreMetadata.where(score: self).delete_all
    original_destroy_permanently!
  end

  alias original_undestroy undestroy
  private :original_undestroy
  def undestroy
    score_metadata.undestroy if score_metadata.present?
    original_undestroy
  end

  def current_grade
    score_to_grade(current_score)
  end

  def unposted_current_grade
    score_to_grade(unposted_current_score)
  end

  def final_grade
    score_to_grade(final_score)
  end

  def unposted_final_grade
    score_to_grade(unposted_final_score)
  end

  def effective_final_score
    override_score || final_score
  end

  def effective_final_score_lower_bound
    score = effective_final_score
    return score unless course.grading_standard_enabled?
    course.grading_standard_or_default.lower_bound(score)
  end

  def effective_final_grade
    score_to_grade(effective_final_score)
  end

  def scorable
    # if you're calling this method, you might want to preload objects to avoid N+1
    grading_period || assignment_group || enrollment.course
  end

  def overridden?
    override_score.present?
  end

  def self.params_for_course
    { course_score: true }
  end

  delegate :score_to_grade, to: :course

  private

  def set_course_score
    gpid = read_attribute(:grading_period_id)
    agid = read_attribute(:assignment_group_id)
    write_attribute(:course_score, (gpid || agid).nil?)
    true
  end

  def scorable_association_check
    scc = scorable_association_count
    if scc == 0 && !course_score
      errors.add(:course_score, "should be true when there are no scorable associations")
    elsif scc == 1 && course_score
      errors.add(:course_score, "should be false when there is a scorable association")
    elsif scc > 1
      errors.add(:base, "may not have multiple scorable associations")
    else
      return true
    end
  end

  def scorable_association_count
    [grading_period_id, assignment_group_id].compact.length
  end
end
