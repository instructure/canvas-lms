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
  belongs_to :assignment
  belongs_to :context, polymorphic: [:course]
  belongs_to :root_account, class_name: "Account"
  belongs_to :version

  validates_presence_of :context_id, :version_id, :user_id, :assignment_id

  class << self
    def index_version(version)
      attributes = extract_version_attributes(version)
      SubmissionVersion.create(attributes) if attributes
    end

    def index_versions(versions, options = {})
      records = versions.map{ |version| extract_version_attributes(version, options) }.compact
      bulk_insert(records) if records.present?
    end

    private
    def extract_version_attributes(version, options = {})
      model = if options[:ignore_errors]
        begin
          return nil unless Submission.active.where(id: version.versionable_id).exists?

          version.model
        rescue Psych::SyntaxError
          return nil
        end
      else
        version.model
      end
    return nil unless model.assignment_id

      {
        :context_id => model.course_id,
        :context_type => 'Course',
        :user_id => model.user_id,
        :assignment_id => model.assignment_id,
        :version_id => version.id,
        :root_account_id => model.root_account_id
      }
    end
  end
end
