# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

module LinkedAttachmentHandler
  SPECIAL_CONCERN_FIELDS = %w[syllabus_body terms_of_use].freeze

  def self.included(klass)
    klass.send(:attr_accessor, :saving_user)

    klass.after_save :update_attachment_associations
    klass.extend(ClassMethods)
  end

  def update_attachment_associations
    return unless attachment_associations_enabled?

    self.class.html_fields.each do |field|
      next unless send("saved_change_to_#{field}?")

      context_concern = field if SPECIAL_CONCERN_FIELDS.include?(field)
      UserContent.associate_attachments_to_rce_object(send(field), self, context_field_name: context_concern, user: saving_user, feature_enabled: attachment_associations_enabled?)
    end
  end

  def attachment_associations_enabled?
    root_account.feature_enabled?(:file_association_access)
  end

  module ClassMethods
    def html_fields
      raise NotImplementedError
    end
  end
end
