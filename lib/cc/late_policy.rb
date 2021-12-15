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
#
module CC
  module LatePolicy
    def add_late_policy(document = nil)
      return nil unless @course.late_policy

      if document
        meta_file = nil
        rel_path = nil
      else
        meta_file = File.new(File.join(@canvas_resource_dir, CCHelper::LATE_POLICY), "w")
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::LATE_POLICY)
        document = Builder::XmlMarkup.new(target: meta_file, indent: 2)
      end

      late_policy = @course.late_policy

      document.instruct!
      document.late_policy(
        :identifier => create_key(late_policy),
        "xmlns" => CCHelper::CANVAS_NAMESPACE,
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |late_policy_node|
        late_policy_node.missing_submission_deduction_enabled late_policy.missing_submission_deduction_enabled
        late_policy_node.missing_submission_deduction late_policy.missing_submission_deduction
        late_policy_node.late_submission_deduction_enabled late_policy.late_submission_deduction_enabled
        late_policy_node.late_submission_deduction late_policy.late_submission_deduction
        late_policy_node.late_submission_interval late_policy.late_submission_interval
        late_policy_node.late_submission_minimum_percent_enabled late_policy.late_submission_minimum_percent_enabled
        late_policy_node.late_submission_minimum_percent late_policy.late_submission_minimum_percent
      end

      meta_file&.close
      rel_path
    end
  end
end
