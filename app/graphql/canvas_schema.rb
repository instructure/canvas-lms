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

class CanvasSchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter

  query Types::QueryType
  mutation Types::MutationType

  use GraphQL::Batch

  def self.id_from_object(obj, type_def, ctx)
    case obj
    when MediaObject
      GraphQL::Schema::UniqueWithinType.encode(type_def.name, obj.media_id)
    else
      GraphQL::Schema::UniqueWithinType.encode(type_def.name, obj.id)
    end
  end

  def self.object_from_id(relay_id, ctx)
    type, id = GraphQL::Schema::UniqueWithinType.decode(relay_id)

    GraphQLNodeLoader.load(type, id, ctx)
  end

  def self.resolve_type(type, obj, _ctx)
    case obj
    when Course then Types::CourseType
    when Assignment then Types::AssignmentType
    when AssignmentGroup then Types::AssignmentGroupType
    when CourseSection then Types::SectionType
    when User then Types::UserType
    when Enrollment then Types::EnrollmentType
    when Submission then Types::SubmissionType
    when SubmissionComment then Types::SubmissionCommentType
    when Group then Types::GroupType
    when GroupCategory then Types::GroupSetType
    when GradingPeriod then Types::GradingPeriodType
    when ContextModule then Types::ModuleType
    when PostPolicy then Types::PostPolicyType
    when WikiPage then Types::PageType
    when Attachment then Types::FileType
    when DiscussionTopic then Types::DiscussionType
    when Quizzes::Quiz then Types::QuizType
    when Progress then Types::ProgressType
    when MediaObject then Types::MediaObjectType
    when ContentTag
      if !type.nil? && type.name == "ModuleItemInterface"
        return Types::ExternalUrlType if obj.content_type == "ExternalUrl"
        return Types::ModuleExternalToolType if obj.content_type == "ContextExternalTool"
      else
        Types::ModuleItemType
      end
    when ContextExternalTool then Types::ExternalToolType
    end
  end

  orphan_types [Types::PageType, Types::FileType, Types::ExternalUrlType,
                Types::ExternalToolType, Types::ModuleExternalToolType,
                Types::ProgressType]
end
