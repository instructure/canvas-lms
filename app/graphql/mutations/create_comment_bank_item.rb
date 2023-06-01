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

class Mutations::CreateCommentBankItem < Mutations::BaseMutation
  graphql_name "CreateCommentBankItem"

  argument :course_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
  argument :comment, String, required: true
  field :comment_bank_item, Types::CommentBankItemType, null: true

  def resolve(input:)
    course = get_course(input[:course_id])
    record = CommentBankItem.new(course:, user: current_user, comment: input[:comment])
    verify_authorized_action!(record, :create)
    return errors_for(record) unless record.save

    { comment_bank_item: record }
  end

  private

  def get_course(course_id)
    Course.active.find_by(id: course_id).tap do |course|
      raise GraphQL::ExecutionError, I18n.t("Course not found") if course.nil?
    end
  end
end
