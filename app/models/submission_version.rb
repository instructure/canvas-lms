#
# Copyright (C) 2013 Instructure, Inc.
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
  attr_accessible :context_id, :context_type, :user_id, :assignment_id, :version_id

  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => false, :in => ['Course']

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
      # TODO make context extraction more efficient in bulk case
      model = if options[:ignore_errors]
        begin
          return nil unless Submission.where(:id => version.versionable_id).exists?
          version.model
        rescue ArgumentError
          return nil
        end
      else
        version.model
      end
      assignment = model.assignment
      return nil unless assignment
      {
        :context_id => assignment.context_id,
        :context_type => assignment.context_type,
        :user_id => model.user_id,
        :assignment_id => model.assignment_id,
        :version_id => version.id
      }
    end
  end
end
