# frozen_string_literal: true

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
  query Types::QueryType
  mutation Types::MutationType

  use GraphQL::Batch

  connections.add(Array, PatchedArrayConnection)
  connections.add(DynamoQuery, DynamoConnection)
  connections.add(AddressBook::MessageableUser::Collection, CollectionConnection)
  connections.add(BookmarkedCollection::Proxy, CollectionConnection)

  def self.id_from_object(obj, type_def, _ctx)
    case obj
    when MediaObject
      GraphQL::Schema::UniqueWithinType.encode(type_def.graphql_name, obj.media_id)
    else
      GraphQL::Schema::UniqueWithinType.encode(type_def.graphql_name, obj.id)
    end
  end

  def self.object_from_id(relay_id, ctx)
    type, id = GraphQL::Schema::UniqueWithinType.decode(relay_id)

    GraphQLNodeLoader.load(type, id, ctx)
  end

  def self.resolve_type(abstract_type, obj, _ctx)
    case obj
    when Account then Types::AccountType
    when Course then Types::CourseType
    when Assignment then Types::AssignmentType
    when AssignmentGroup then Types::AssignmentGroupType
    when CommentBankItem then Types::CommentBankItemType
    when Conversation then Types::ConversationType
    when CourseSection then Types::SectionType
    when User then Types::UserType
    when Enrollment then Types::EnrollmentType
    when EnrollmentTerm then Types::TermType
    when Submission then Types::SubmissionType
    when SubmissionComment then Types::SubmissionCommentType
    when SubmissionDraft then Types::SubmissionDraftType
    when Group then Types::GroupType
    when GroupCategory then Types::GroupSetType
    when GradingPeriod then Types::GradingPeriodType
    when ContextModule then Types::ModuleType
    when PostPolicy then Types::PostPolicyType
    when WikiPage then Types::PageType
    when Attachment then Types::FileType
    when DiscussionTopic then Types::DiscussionType
    when DiscussionEntry then Types::DiscussionEntryType
    when Quizzes::Quiz then Types::QuizType
    when OutcomeCalculationMethod then Types::OutcomeCalculationMethodType
    when OutcomeProficiency then Types::OutcomeProficiencyType
    when Progress then Types::ProgressType
    when Rubric then Types::RubricType
    when MediaObject then Types::MediaObjectType
    when LearningOutcomeGroup then Types::LearningOutcomeGroupType
    when LearningOutcome then Types::LearningOutcomeType
    when OutcomeFriendlyDescription then Types::OutcomeFriendlyDescriptionType
    when ContentTag
      if abstract_type&.graphql_name == "ModuleItemInterface"
        case obj.content_type
        when "ContextModuleSubHeader" then Types::ModuleSubHeaderType
        when "ExternalUrl" then Types::ExternalUrlType
        when "ContextExternalTool" then Types::ModuleExternalToolType
        end
      else
        Types::ModuleItemType
      end
    when ContextExternalTool then Types::ExternalToolType
    when Setting then Types::InternalSettingType
    when AssessmentRequest then Types::AssessmentRequestType
    end
  end

  def self.unauthorized_object(error)
    raise GraphQL::ExecutionError,
          I18n.t("An object of type %{graphql_type} was hidden due to insufficient scopes on access token",
                 graphql_type: error.type.graphql_name)
  end

  orphan_types [Types::PageType, Types::FileType, Types::ExternalUrlType,
                Types::ExternalToolType, Types::ModuleExternalToolType,
                Types::ProgressType, Types::ModuleSubHeaderType,
                Types::InternalSettingType]

  def self.for_federation
    @federatable_schema ||= Class.new(CanvasSchema) do
      include ApolloFederation::Schema

      # TODO: once https://github.com/Gusto/apollo-federation-ruby/pull/135 is
      # merged and published, we can update the `apollo-federation` gem and
      # remove this line
      query Types::QueryType
    end
  end
end
