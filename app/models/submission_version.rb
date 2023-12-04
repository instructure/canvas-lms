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
#

class SubmissionVersion < ActiveRecord::Base
  belongs_to :assignment, class_name: "AbstractAssignment"
  belongs_to :context, polymorphic: [:course]
  belongs_to :root_account, class_name: "Account"

  # despite the fact that "Version" is aliased to "SimplyVersioned::Version"
  # the classname inference here doesn't see that as an option and fails
  # with a name error if you don't specify the class.
  # Since "::Version" doesn't make it very clear WHY you have to
  # specify the name, we might as well use the whole module/class name
  belongs_to :version, class_name: "SimplyVersioned::Version"

  validates :context_id, :version_id, :user_id, :assignment_id, presence: true

  class << self
    def index_version(version)
      attributes = extract_version_attributes(version)
      SubmissionVersion.create(attributes) if attributes
    end

    def index_versions(versions, options = {})
      records = versions.filter_map { |version| extract_version_attributes(version, options) }
      bulk_insert(records) if records.present?
    end

    private

    def extract_version_attributes(version, options = {})
      model = if options[:ignore_errors]
                begin
                  Submission.active.where(id: version.versionable_id).exists? && version.model
                rescue Psych::SyntaxError
                  nil
                end
              else
                version.model
              end
      return nil unless model.try(:assignment_id) # model _could_ be false here, so don't use &.

      {
        context_id: model.course_id,
        context_type: "Course",
        user_id: model.user_id,
        assignment_id: model.assignment_id,
        version_id: version.id,
        root_account_id: model.root_account_id
      }
    end
  end
end
