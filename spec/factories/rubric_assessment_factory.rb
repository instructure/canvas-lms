#
# Copyright (C) 2011 Instructure, Inc.
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

module Factories
  def rubric_assessment_model(opts={})
    rubric_association_model(opts)
    @rubric_assessment = @rubric_association.rubric_assessments.create!(:user => opts[:user], :assessor => opts[:user], :rubric => @rubric, :artifact => @rubric_association.association_object, :assessment_type => opts[:assessment_type] || 'no_reason')
  end

  def valid_rubric_assessment_attributes
    {
    }
  end
end
