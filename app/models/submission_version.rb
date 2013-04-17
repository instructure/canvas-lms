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
  belongs_to :version

  class << self
    def index_version(version)
      SubmissionVersion.create(extract_version_attributes(version))
    end

    def index_versions(versions)
      records = versions.map{ |version| extract_version_attributes(version) }
      connection.bulk_insert(table_name, records)
    end

    def reindex_version(version)
      attributes = extract_version_attributes(version)
      attributes.delete(:version_id)
      SubmissionVersion.where(:version_id => version).update_all(attributes)
    end

    private
    def extract_version_attributes(version)
      # TODO make context extraction more efficient in bulk case
      model = version.model
      assignment = model.assignment
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
