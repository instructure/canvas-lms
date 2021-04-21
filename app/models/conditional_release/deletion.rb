# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

# yes this isn't really any different than SoftDeletable but this preserves the db structure
# from conditional_release and workflow_state kind of sucks anyway
module ConditionalRelease
  module Deletion
    extend ActiveSupport::Concern

    included do
      scope :active, -> { where(:deleted_at => nil) }

      alias_method :destroy_permanently!, :destroy
      def destroy
        return true if deleted_at.present?
        self.deleted_at = Time.now.utc
        run_callbacks(:destroy) { save(validate: false) }
      end

      def restore
        self.deleted_at = nil
        save!
        true
      end
    end
  end
end
