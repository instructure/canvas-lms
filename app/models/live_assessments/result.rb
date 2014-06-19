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

module LiveAssessments
  class Result < ActiveRecord::Base
    attr_accessible :user, :assessor, :passed, :assessed_at

    belongs_to :assessor, class_name: 'User'
    belongs_to :user
    belongs_to :assessment, class_name: 'LiveAssessments::Assessment'

    validates_presence_of :assessor_id, :assessment_id, :assessed_at
    validates_inclusion_of :passed, :in => [true, false]

    scope :for_user, lambda { |user| where(:user_id => user) }

    set_policy do
      given { |user, session| self.assessment.grants_right?(user, session, :update) }
      can :create

      given { |user, session| self.assessment.grants_right?(user, session, :read) }
      can :read
    end
  end
end
