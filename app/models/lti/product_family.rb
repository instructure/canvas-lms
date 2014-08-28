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

module Lti
  class ProductFamily < ActiveRecord::Base

    attr_accessible :vendor_code, :product_code, :vendor_name, :vendor_description, :website, :vendor_email, :root_account

    belongs_to :root_account, class_name: 'Account'
    has_many :tool_proxies, class_name: "Lti::ToolProxy"

    validates_presence_of :vendor_code, :product_code, :vendor_name, :root_account
    validates_uniqueness_of :product_code, scope: [:vendor_code, :root_account_id]

  end
end

