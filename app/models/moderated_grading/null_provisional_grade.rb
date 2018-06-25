#
# Copyright (C) 2015 - present Instructure, Inc.
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

class ModeratedGrading::NullProvisionalGrade
  def initialize(submission, scorer_id, final)
    @submission = submission
    @scorer_id = scorer_id
    @final = final
  end

  def grade_attributes
    {
      'provisional_grade_id' => nil,
      'grade' => nil,
      'score' => nil,
      'graded_at' => nil,
      'scorer_id' => @scorer_id,
      'graded_anonymously' => nil,
      'final' => @final,
      'grade_matches_current_submission' => true
    }
  end

  def submission_comments
    @submission.submission_comments
  end

  def scorer
    return nil if @scorer_id.nil?
    @scorer ||= User.find(@scorer_id)
  end
end
