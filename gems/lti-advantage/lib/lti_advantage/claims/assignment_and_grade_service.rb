#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'active_model'

module LtiAdvantage::Claims
  # Class represeting an LTI 1.3 message AGS "endpoint" claim.
  # https://purl.imsglobal.org/spec/lti-ags/claim/endpoint
  class AssignmentAndGradeService
    include ActiveModel::Model

    attr_accessor :scope,
                  :lineitems,
                  :lineitem

    validates_presence_of :scope
  end
end
