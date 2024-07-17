# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Api::V1::EnrollmentTerm
  include Api::V1::Json

  def enrollment_term_json(enrollment_term, user, session, enrollments = [], includes = [], course_counts = nil, filtered_terms = nil)
    api_json(enrollment_term, user, session, only: %w[id name start_at end_at workflow_state grading_period_group_id created_at]).tap do |hash|
      hash["sis_term_id"] = enrollment_term.sis_source_id if enrollment_term.root_account.grants_any_right?(user, :read_sis, :manage_sis)
      if enrollment_term.root_account.grants_right?(user, :manage_sis)
        hash["sis_import_id"] = enrollment_term.sis_batch_id
      end
      hash["start_at"], hash["end_at"] = enrollment_term.overridden_term_dates(enrollments) if enrollments.present?
      hash["overrides"] = date_overrides_json(enrollment_term) if includes.include?("overrides")
      if includes.include?("course_count")
        counts = course_counts || EnrollmentTerm.course_counts(enrollment_term)
        hash["course_count"] = counts[enrollment_term.id] || 0
      end
      if filtered_terms
        hash["used_in_subaccount"] = filtered_terms.include?(enrollment_term.id)
      end
    end
  end

  def enrollment_terms_json(enrollment_terms, user, session, root_account, enrollments = [], includes = [], subaccount_id = nil)
    if includes.include?("overrides")
      ActiveRecord::Associations.preload(enrollment_terms, :enrollment_dates_overrides)
    end
    filtered_terms = nil
    if subaccount_id
      filtered_term_ids = Account.find(subaccount_id).associated_courses.pluck(:enrollment_term_id).uniq
      default_id = root_account.default_enrollment_term.id
      filtered_term_ids.append(default_id)
      filtered_terms = filtered_term_ids.to_set
    end
    course_counts = EnrollmentTerm.course_counts(enrollment_terms) if includes.include?("course_count")
    enrollment_terms.map { |t| enrollment_term_json(t, user, session, enrollments, includes, course_counts, filtered_terms) }
  end

  protected

  def date_overrides_json(term)
    term.enrollment_dates_overrides.select { |o| o.start_at || o.end_at }.each_with_object({}) do |override, json|
      json[override.enrollment_type] = override.attributes.slice("start_at", "end_at")
    end
  end
end
