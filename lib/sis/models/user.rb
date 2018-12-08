#
# Copyright (C) 2017 - present Instructure, Inc.
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

module SIS
  module Models
    class User
      attr_accessor :user_id, :login_id, :status, :first_name, :last_name,
                    :email, :password, :ssha_password, :integration_id,
                    :short_name, :full_name, :sortable_name, :lineno, :csv,
                    :authentication_provider_id, :sis_batch_id

      def initialize(user_id:, login_id:, status:, first_name: nil, last_name: nil,
                     email: nil, password: nil, ssha_password: nil,
                     integration_id: nil, short_name: nil, full_name: nil,
                     sortable_name: nil, authentication_provider_id: nil,
                     sis_batch_id: nil, lineno: nil, csv: nil)
        self.user_id = user_id
        self.login_id = login_id
        self.status = status
        self.first_name = first_name
        self.last_name = last_name
        self.email = email
        self.password = password
        self.ssha_password = ssha_password
        self.integration_id = integration_id
        self.short_name = short_name
        self.full_name = full_name
        self.sortable_name = sortable_name
        self.authentication_provider_id = authentication_provider_id
        self.lineno = lineno
        self.csv = csv
        self.sis_batch_id = sis_batch_id
      end

      def to_a
        [user_id.to_s, login_id.to_s, status, first_name, last_name, email,
         password.to_s, ssha_password.to_s, integration_id.to_s, short_name,
         full_name, sortable_name, authentication_provider_id]
      end

      def row_info
        [user_id: user_id, login_id: login_id, status: status,
         first_name: first_name, last_name: last_name, email: email,
         integration_id: integration_id, short_name: short_name,
         full_name: full_name, sortable_name: sortable_name,
         authentication_provider_id: authentication_provider_id].to_s
      end
    end
  end
end


