#
# Copyright (C) 2014 Instructure, Inc.
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

module Filters::LiveAssessments
  protected

  # be sure to have a valid context before calling this
  def require_assessment
    id = params.has_key?(:assessment_id) ? params[:assessment_id] : params[:id]

    @assessment = LiveAssessments::Assessment.find(id)
    reject! 'assessment does not belong to the given context' unless @assessment.context == @context
    @assessment
  end
end
