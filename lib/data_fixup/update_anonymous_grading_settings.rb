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
#

module DataFixup::UpdateAnonymousGradingSettings
  def self.run_for_courses_in_range(start_at, end_at)
    courses_to_disable = Course.joins(:feature_flags).
      where("courses.id >= ? AND courses.id <= ?", start_at, end_at).
      where(feature_flags: {feature: 'anonymous_grading', state: 'on'})

    courses_to_disable.find_each(start: 0) do |course|
      course.assignments.except(:order).
        where.not(anonymous_grading: true).
        in_batches.update_all(anonymous_grading: true)
      course.enable_feature!(:anonymous_marking)

      # Remove these flags one by one (as opposed to en masse at the end of the
      # fixup) so that we keep track of which courses we've processed in case we
      # get interrupted midway through.
      course.feature_flag(:anonymous_grading).destroy
    end
  end

  def self.run_for_accounts_in_range(start_at, end_at)
    accounts_to_disable = Account.joins(:feature_flags).
      where("accounts.id >= ? AND accounts.id <= ?", start_at, end_at).
      where(feature_flags: {feature: 'anonymous_grading', state: 'on'})

    accounts_to_disable.find_each(start: 0) do |account|
      # If an account has the feature flag forced to ON, we need to get all
      # the courses belonging to that account and every account below it.
      # That said, we don't actually need do any work on said courses (since
      # they won't have the flag set specifically), only on the assignments
      # in the courses
      descendant_account_ids = [account.id] + Account.sub_account_ids_recursive(account.id)

      courses_to_process = Course.published.where(account_id: descendant_account_ids)
      courses_to_process.find_ids_in_batches do |course_ids|
        assignments = Assignment.published.
          where(context_id: course_ids, context_type: 'Course').
          where.not(anonymous_grading: true)
        assignments.find_ids_in_batches do |assignment_ids|
          Assignment.where(id: assignment_ids).update_all(anonymous_grading: true)
        end
      end

      account.enable_feature!(:anonymous_marking)

      # As above, remove these flags one by one to keep track of where we are.
      account.feature_flag(:anonymous_grading).destroy
    end
  end

  def self.destroy_allowed_and_off_flags
    # Note that only accounts can have an 'allowed' state
    FeatureFlag.where(feature: 'anonymous_grading').where.not(state: 'on').in_batches.destroy_all
  end
end
