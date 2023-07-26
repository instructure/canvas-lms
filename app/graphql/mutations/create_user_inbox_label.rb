# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
class Mutations::CreateUserInboxLabel < Mutations::BaseMutation
  argument :names, [String], required: true

  field :inbox_labels, [String], null: true

  def resolve(input:)
    return unless current_user

    ret = nil
    names = input[:names]
    inbox_labels = current_user.inbox_labels

    names.each do |name|
      if name && name.strip.empty?
        ret = validation_error(I18n.t("Invalid label name. It cannot be blank."))
        break
      elsif inbox_labels.include? name
        ret = validation_error(I18n.t("Invalid label name. It already exists."))
        break
      else
        inbox_labels.push(name)
      end
    end

    if ret
      ret
    else
      current_user.preferences[:inbox_labels] = inbox_labels
      current_user.save!

      { inbox_labels: }
    end
  end
end
