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

module SIS
  module Models
    class Enrollment
      attr_accessor :course_id, :section_id, :user_id, :user_integration_id,
                    :role, :status, :associated_user_id, :root_account_id,
                    :role_id, :start_date, :end_date, :sis_batch_id,
                    :limit_section_privileges, :lineno, :csv

      def initialize(course_id: nil, section_id: nil, user_id: nil,
                     user_integration_id: nil, role: nil, status: nil,
                     associated_user_id: nil, root_account_id: nil,
                     role_id: nil, start_date: nil, end_date: nil,
                     sis_batch_id: nil, limit_section_privileges: nil,
                     lineno: nil, csv: nil)
        self.course_id = course_id
        self.section_id = section_id
        self.user_id = user_id
        self.user_integration_id = user_integration_id
        self.role = role
        self.status = status
        self.associated_user_id = associated_user_id
        self.root_account_id = root_account_id
        self.role_id = role_id
        self.limit_section_privileges = limit_section_privileges
        self.start_date = start_date
        self.end_date = end_date
        self.lineno = lineno
        self.csv = csv
        # adding sis_batch_id here for plugins that are not going through
        # the initialize of enrollment_importer
        self.sis_batch_id = sis_batch_id
      end

      def valid_context?
        !course_id.blank? || !section_id.blank?
      end

      def valid_user?
        !user_id.blank? || !user_integration_id.blank?
      end

      def valid_status?
        status =~ /\Aactive|\Adeleted|\Acompleted|\Ainactive/i
      end

      def to_a
        [course_id.to_s, section_id.to_s, user_id.to_s, role, role_id, status, start_date, end_date, associated_user_id, root_account_id]
      end

      def row_info
        [course_id: course_id,
         section_id: section_id,
         user_id: user_id,
         user_integration_id: user_integration_id,
         role: role,
         status: status,
         associated_user_id: associated_user_id,
         root_account_id: root_account_id,
         role_id: role_id,
         limit_section_privileges: limit_section_privileges,
         start_date: start_date,
         end_date: end_date].to_s
      end
    end
  end
end


