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

class Mutations::AssignmentOverrideCreateOrUpdate < GraphQL::Schema::InputObject
  argument :id, ID, required: false
  argument :due_at, Types::DateTimeType, required: false
  argument :lock_at, Types::DateTimeType, required: false
  argument :unlock_at, Types::DateTimeType, required: false

  argument :course_section_id, ID, required: false
  argument :group_id, ID, required: false
  argument :student_ids, [ID], required: false
  argument :noop_id, ID, required: false
  argument :title, String, required: false
end

class Mutations::AssignmentModeratedGradingUpdate < GraphQL::Schema::InputObject
  argument :enabled, Boolean, required: false
  argument :grader_count, Int, required: false
  argument :grader_comments_visible_to_graders, Boolean, required: false
  argument :grader_names_visible_to_final_grader, Boolean, required: false
  argument :graders_anonymous_to_graders, Boolean, required: false
  argument :final_grader_id, ID, required: false
end

class Mutations::AssignmentPeerReviewsUpdate < GraphQL::Schema::InputObject
  argument :enabled, Boolean, required: false
  argument :count, Int, required: false
  argument :due_at, Types::DateTimeType, required: false
  argument :intra_reviews, Boolean, required: false
  argument :anonymous_reviews, Boolean, required: false
  argument :automatic_reviews, Boolean, required: false
end

class Mutations::AssignmentInputBase < GraphQL::Schema::InputObject
  argument :assignment_group_id, ID, required: false
  argument :assignment_overrides, [Mutations::AssignmentOverrideCreateOrUpdate], required: false
  argument :due_at, Types::DateTimeType, required: false
  argument :grading_standard_id, ID, required: false
  argument :grading_type, Types::AssignmentType::AssignmentGradingType, required: false
  argument :group_category_id, ID, required: false
  argument :intra_reviews, Boolean, required: false
  argument :lock_at, Types::DateTimeType, required: false
  argument :only_visible_to_overrides, Boolean, required: false
  argument :peer_reviews, Mutations::AssignmentPeerReviewsUpdate, required: false
  argument :points_possible, Float, required: false
  argument :post_to_sis, Boolean, required: false
  argument :unlock_at, Types::DateTimeType, required: false
  argument :for_checkpoints, Boolean, required: false
end

class Mutations::AssignmentCreate < Mutations::AssignmentInputBase
  argument :course_id, ID, required: true
  argument :name, String, required: true
end

class Mutations::AssignmentUpdate < Mutations::AssignmentInputBase
  argument :set_assignment, Boolean, required: false
end

class Mutations::AssignmentBase < Mutations::BaseMutation
  # we are required to wrap the update method with a proxy class because
  # we are required to include `Api` for instance methods within the module.
  # the main problem is that including the `Api` module conflicts with the
  # `Mutations::BaseMutation` class. so we have to segregate the two.
  #
  # probably a good idea to segregate anyways so we dont accidentally include
  # processing we dont want.
  class ApiProxy
    include Api
    include Api::V1::Assignment

    def initialize(request, working_assignment, session, current_user)
      @request = request
      @working_assignment = working_assignment
      @session = session
      @current_user = current_user
      @context = working_assignment.context
    end

    attr_reader :session

    def context
      @working_assignment.context
    end

    def grading_periods?
      @working_assignment.context.try(:grading_periods?)
    end

    def strong_anything
      ArbitraryStrongishParams::ANYTHING
    end

    def value_to_boolean(value)
      Canvas::Plugin.value_to_boolean(value)
    end

    def process_incoming_html_content(html)
      Api::Html::Content.process_incoming(html)
    end

    def load_root_account
      @domain_root_account = @request.env["canvas.domain_root_account"] || LoadAccount.default_domain_root_account
    end
  end

  # input arguments
  argument :state, Types::AssignmentType::AssignmentStateType, required: false
  argument :due_at, Types::DateTimeType, required: false
  argument :lock_at, Types::DateTimeType, required: false
  argument :unlock_at, Types::DateTimeType, required: false
  argument :description, String, required: false
  argument :assignment_overrides, [Mutations::AssignmentOverrideCreateOrUpdate], required: false
  argument :position, Int, required: false
  argument :points_possible, Float, required: false
  argument :grading_type, Types::AssignmentType::AssignmentGradingType, required: false
  argument :allowed_extensions, [String], required: false
  argument :assignment_group_id, ID, required: false
  argument :group_set_id, ID, required: false
  argument :allowed_attempts, Int, required: false
  argument :only_visible_to_overrides, Boolean, required: false
  argument :submission_types, [Types::AssignmentSubmissionType], required: false
  argument :grading_standard_id, ID, required: false
  argument :peer_reviews, Mutations::AssignmentPeerReviewsUpdate, required: false
  argument :moderated_grading, Mutations::AssignmentModeratedGradingUpdate, required: false
  argument :grade_group_students_individually, Boolean, required: false
  argument :group_category_id, ID, required: false
  argument :omit_from_final_grade, Boolean, required: false
  argument :anonymous_instructor_annotations, Boolean, required: false
  argument :post_to_sis, Boolean, required: false
  argument :anonymous_grading,
           Boolean,
           "requires anonymous_marking course feature to be set to true",
           required: false
  argument :module_ids, [ID], required: false
  argument :for_checkpoints, Boolean, required: false

  # the return data if the update is successful
  field :assignment, Types::AssignmentType, null: true

  def prepare_input_params!(input_hash, api_proxy)
    prepare_overrides!(input_hash, api_proxy)
    prepare_moderated_grading!(input_hash)
    prepare_peer_reviews!(input_hash)
    prepare_dates!(input_hash)

    # prepare other ids
    if input_hash.key? :assignment_group_id
      input_hash[:assignment_group_id] = GraphQLHelpers.parse_relay_or_legacy_id(input_hash[:assignment_group_id], "AssignmentGroup")
    end
    if input_hash.key? :group_set_id
      input_hash[:group_category_id] = GraphQLHelpers.parse_relay_or_legacy_id(input_hash.delete(:group_set_id), "GroupSet")
    end

    input_hash
  end

  def prepare_module_ids!(input_hash)
    if input_hash.key? :module_ids
      input_hash.delete(:module_ids).map { |id| GraphQLHelpers.parse_relay_or_legacy_id(id, "Module") }.map(&:to_i)
    end
  end

  def prepare_overrides!(input_hash, api_proxy)
    if input_hash.key?(:assignment_overrides) && input_hash[:assignment_overrides].present?
      if input_hash[:for_checkpoints]
        raise GraphQL::ExecutionError, "Assignment overrides are not allowed in the parent assignment for checkpoints."
      end

      api_proxy.load_root_account
      input_hash[:assignment_overrides].each do |override|
        if override[:id].blank?
          override.delete :id
        else
          override[:id] = GraphQLHelpers.parse_relay_or_legacy_id(override[:id], "AssignmentOverride")
        end
        override[:course_section_id] = GraphQLHelpers.parse_relay_or_legacy_id(override[:section_id], "Section") if override.key?(:section_id) && override[:section_id].present?
        override[:group_id] = GraphQLHelpers.parse_relay_or_legacy_id(override[:group_id], "Group") if override.key?(:group_id) && override[:group_id].present?
        override[:student_ids] = override[:student_ids].map { |id| GraphQLHelpers.parse_relay_or_legacy_id(id, "User") } if override.key?(:student_ids) && override[:student_ids].present?
      end
    end
  end

  def prepare_moderated_grading!(input_hash)
    if input_hash.key? :moderated_grading
      moderated_grading = input_hash.delete(:moderated_grading)
      input_hash[:moderated_grading] = moderated_grading[:enabled] if moderated_grading.key? :enabled
      input_hash.merge!(moderated_grading.slice(:grader_count,
                                                :grader_comments_visible_to_graders,
                                                :grader_names_visible_to_final_grader,
                                                :graders_anonymous_to_graders))
      if moderated_grading.key? :final_grader_id
        input_hash[:final_grader_id] = GraphQLHelpers.parse_relay_or_legacy_id(moderated_grading[:final_grader_id], "User")
      end
    end
  end

  def prepare_peer_reviews!(input_hash)
    if input_hash.key?(:peer_reviews) && input_hash[:peer_reviews].present?
      peer_reviews = input_hash.delete(:peer_reviews)
      input_hash[:peer_reviews] = peer_reviews[:enabled] if peer_reviews.key?(:enabled) && peer_reviews[:enabled].present?
      input_hash[:peer_review_count] = peer_reviews[:count] if peer_reviews.key?(:count) && peer_reviews[:count].present?
      input_hash[:anonymous_peer_reviews] = peer_reviews[:anonymous_reviews] if peer_reviews.key?(:anonymous_reviews) && peer_reviews[:anonymous_reviews].present?
      input_hash[:automatic_peer_reviews] = peer_reviews[:automatic_reviews] if peer_reviews.key?(:automatic_reviews) && peer_reviews[:automatic_reviews].present?

      # checking peer_reviews[:intra_reviews].present? does not apply since it's a bool, fails in the false case.
      # peer_reviews.key?(:intra_reviews) should be sufficient.
      input_hash[:intra_group_peer_reviews] = peer_reviews[:intra_reviews] if peer_reviews.key?(:intra_reviews)

      # this should be peer_reviews_due_at, but its not permitted in the backend and peer_reviews_assign_at
      # is transformed into peer_reviews_due_at. that's probably a bug, but just to keep this update resilient
      # well get it working and if the bug needs to be addressed, we can later.
      input_hash[:peer_reviews_assign_at] = peer_reviews[:due_at]
    end
  end

  def prepare_dates!(input)
    # graphql gives us back proper date objects but `update_assignment`
    # wants strings
    %i[due_at lock_at unlock_at peer_reviews_assign_at].each do |date_field|
      if input[date_field]
        input[date_field] = input[date_field].iso8601
      end
    end
  end

  def ensure_modules(required_module_ids)
    content_tags = ContentTag.find(@working_assignment.context_module_tag_ids)
    current_module_ids = content_tags.map(&:context_module_id).uniq

    required_module_ids = required_module_ids.to_set
    current_module_ids = current_module_ids.to_set

    # we dont need to do anything if the current and required are the same.
    return if required_module_ids == current_module_ids

    # first, add all modules that are missing
    module_ids_to_add = (required_module_ids - current_module_ids).to_a
    unless module_ids_to_add.empty?
      ContextModule.find(module_ids_to_add).each do |context_module|
        context_module.add_item(id: @working_assignment.id, type: "assignment")
      end
    end

    # now remove all _tags_ that are not required
    (current_module_ids - required_module_ids).to_set.each do |module_id_to_remove|
      # assignments can be part of multiple modules, so we have to search through all the tags
      # and if context_module_id is the module to remove, then we need to delete the tag
      content_tags.each do |tag|
        if tag.context_module_id == module_id_to_remove
          tag.destroy
        end
      end
    end

    # we need to reload the assignment so things get returned correctly
    @working_assignment.reload
  end

  def ensure_destroyed
    # check for permissions no matter what
    raise GraphQL::ExecutionError, "insufficient permission" unless @working_assignment.grants_right? current_user, :delete

    # if we are already destroyed, then dont do anything
    return if @working_assignment.workflow_state == "deleted"

    # actually destroy now.
    SubmissionLifecycleManager.with_executing_user(@current_user) do
      @working_assignment.destroy
    end
  end

  def ensure_restored
    raise GraphQL::ExecutionError, "insufficient permission" unless @working_assignment.grants_right? current_user, :delete
    # if we are already not destroyed, then dont do anything
    return if @working_assignment.workflow_state != "deleted"

    @working_assignment.restore
  end

  def validate_for_checkpoints(input_hash)
    return unless input_hash[:for_checkpoints]

    restricted_keys = %i[points_possible due_at lock_at unlock_at].freeze

    restricted_keys.each do |key|
      if input_hash.key?(key)
        raise GraphQL::ExecutionError, "Cannot set #{key} in the parent assignment for checkpoints."
      end
    end
  end
end
