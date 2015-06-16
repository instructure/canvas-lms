#
# Copyright (C) 2015 Instructure, Inc.
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

module LegalInformationHelper
  def terms_of_use_url
    Setting.get('terms_of_use_url', 'http://www.canvaslms.com/policies/terms-of-use')
  end

  def privacy_policy_url
    Setting.get('privacy_policy_url', 'http://www.canvaslms.com/policies/privacy-policy')
  end

protected
  # extension point
  def legal_information
    {}
  end
end
