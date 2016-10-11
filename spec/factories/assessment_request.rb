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
  def assessment_request_model(opts={})
    @user = user_model
    @user2 = user_model
    @user3 = user_model
    @submission = submission_model

    @assessment_request = AssessmentRequest.create!(:user => @user, :assessor_asset => @user2, :assessor => @user3, :asset => @submission)

    @assessment_request
  end
end
