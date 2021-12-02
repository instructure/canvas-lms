# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require "inst_access"

class InstAccessSupport
  def self.configure_inst_access!
    conf = Rails.application.credentials.inst_access_signature
    if conf
      InstAccess.configure(
        signing_key: Base64.decode64(conf[:private_key]),
        encryption_key: Base64.decode64(conf[:encryption_public_key])
      )
    end
  end
end
