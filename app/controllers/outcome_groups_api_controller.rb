#
# Copyright (C) 2012 Instructure, Inc.
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

# @API Outcome Groups
#
# API for accessing learning outcome group information.
#
# Learning outcome groups organize outcomes within a context (or in the global
# "context" for global outcomes). Every outcome is created in a particular
# context (that context then becomes its "owning context") but may be linked
# multiple times in one or more related contexts. This allows different
# accounts or courses to organize commonly defined outcomes in ways appropriate
# to their pedagogy, including having the same outcome discoverable at
# different locations in the organizational hierarchy.
#
# While an outcome can be linked into a context (such as a course) multiple
# times, it may only be linked into a particular group once.
#
# @model OutcomeGroup
#     {
#       "id": "OutcomeGroup",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the outcome group",
#           "example": 1,
#           "type": "integer"
#         },
#         "url": {
#           "description": "the URL for fetching/updating the outcome group. should be treated as opaque",
#           "example": "/api/v1/accounts/1/outcome_groups/1",
#           "type": "string"
#         },
#         "parent_outcome_group": {
#           "description": "an abbreviated OutcomeGroup object representing the parent group of this outcome group, if any. omitted in the abbreviated form.",
#           "$ref": "OutcomeGroup"
#         },
#         "context_id": {
#           "description": "the context owning the outcome group. may be null for global outcome groups. omitted in the abbreviated form.",
#           "example": 1,
#           "type": "integer"
#         },
#         "context_type": {
#           "example": "Account",
#           "type": "string"
#         },
#         "title": {
#           "description": "title of the outcome group",
#           "example": "Outcome group title",
#           "type": "string"
#         },
#         "description": {
#           "description": "description of the outcome group. omitted in the abbreviated form.",
#           "example": "Outcome group description",
#           "type": "string"
#         },
#         "vendor_guid": {
#           "description": "A custom GUID for the learning standard.",
#           "example": "customid9000",
#           "type": "string"
#         },
#         "subgroups_url": {
#           "description": "the URL for listing/creating subgroups under the outcome group. should be treated as opaque",
#           "example": "/api/v1/accounts/1/outcome_groups/1/subgroups",
#           "type": "string"
#         },
#         "outcomes_url": {
#           "description": "the URL for listing/creating outcome links under the outcome group. should be treated as opaque",
#           "example": "/api/v1/accounts/1/outcome_groups/1/outcomes",
#           "type": "string"
#         },
#         "import_url": {
#           "description": "the URL for importing another group into this outcome group. should be treated as opaque. omitted in the abbreviated form.",
#           "example": "/api/v1/accounts/1/outcome_groups/1/import",
#           "type": "string"
#         },
#         "can_edit": {
#           "description": "whether the current user can update the outcome group",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model OutcomeLink
#     {
#       "id": "OutcomeLink",
#       "description": "",
#       "properties": {
#         "url": {
#           "description": "the URL for fetching/updating the outcome link. should be treated as opaque",
#           "example": "/api/v1/accounts/1/outcome_groups/1/outcomes/1",
#           "type": "string"
#         },
#         "context_id": {
#           "description": "the context owning the outcome link. will match the context owning the outcome group containing the outcome link; included for convenience. may be null for links in global outcome groups.",
#           "example": 1,
#           "type": "integer"
#         },
#         "context_type": {
#           "example": "Account",
#           "type": "string"
#         },
#         "outcome_group": {
#           "description": "an abbreviated OutcomeGroup object representing the group containing the outcome link.",
#           "$ref": "OutcomeGroup"
#         },
#         "outcome": {
#           "description": "an abbreviated Outcome object representing the outcome linked into the containing outcome group.",
#           "$ref": "Outcome"
#         }
#       }
#     }
#
class OutcomeGroupsApiController < ApplicationController
  include Api::V1::Outcome

  before_filter :require_user
  before_filter :get_context

  # @API Redirect to root outcome group for context
  #
  # Convenience redirect to find the root outcome group for a particular
  # context. Will redirect to the appropriate outcome group's URL.
  #
  def redirect
    if can_read_outcomes
      @outcome_group = @context ?
        @context.root_outcome_group :
        LearningOutcomeGroup.global_root_outcome_group
      redirect_to polymorphic_path [:api_v1, @context || :global, :outcome_group], :id => @outcome_group.id
    end
  end

  # @API Get all outcome groups for context
  # @beta
  #
  # @returns [OutcomeGroup]
  def index
    return unless can_read_outcomes

    url = polymorphic_url [:api_v1, @context || :global, :outcome_groups]
    groups = Api.paginate(context_outcome_groups, self, url)
    render json: groups.map { |group| outcome_group_json(group, @current_user, session) }
  end

  # @API Get all outcome links for context
  # @beta
  #
  # @argument outcome_style [Optional, String]
  #   The detail level of the outcomes. Defaults to "abbrev".
  #   Specify "full" for more information.
  #
  # @argument outcome_group_style [Optional, String]
  #   The detail level of the outcome groups. Defaults to "abbrev".
  #   Specify "full" for more information.
  #
  # @returns [OutcomeLink]
  def link_index
    return unless can_read_outcomes

    url = polymorphic_url [:api_v1, @context || :global, :outcome_group_links]
    links = Api.paginate(context_outcome_links, self, url)
    render json: links.map { |link|
      outcome_link_json(link, @current_user, session, params.slice(:outcome_style, :outcome_group_style))
    }
  end

  # @API Show an outcome group
  #
  # @returns OutcomeGroup
  #
  def show
    if can_read_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      render :json => outcome_group_json(@outcome_group, @current_user, session)
    end
  end

  # @API Update an outcome group
  #
  # Modify an existing outcome group. Fields not provided are left as is;
  # unrecognized fields are ignored.
  #
  # When changing the parent outcome group, the new parent group must belong to
  # the same context as this outcome group, and must not be a descendant of
  # this outcome group (i.e. no cycles allowed).
  #
  # @argument title [String]
  #   The new outcome group title.
  #
  # @argument description [String]
  #   The new outcome group description.
  #
  # @argument vendor_guid [String]
  #   A custom GUID for the learning standard.
  #
  # @argument parent_outcome_group_id [Integer]
  #   The id of the new parent outcome group.
  #
  # @returns OutcomeGroup
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/1/outcome_groups/2.json' \
  #        -X PUT \ 
  #        -F 'title=Outcome Group Title' \ 
  #        -F 'description=Outcome group description' \
  #        -F 'vendor_guid=customid9000' \
  #        -F 'parent_outcome_group_id=1' \ 
  #        -H "Authorization: Bearer <token>"
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/1/outcome_groups/2.json' \
  #        -X PUT \ 
  #        --data-binary '{
  #              "title": "Outcome Group Title",
  #              "description": "Outcome group description",
  #              "vendor_guid": "customid9000",
  #              "parent_outcome_group_id": 1
  #            }' \ 
  #        -H "Content-Type: application/json" \ 
  #        -H "Authorization: Bearer <token>"
  #
  def update
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      if @outcome_group.learning_outcome_group_id.nil?
        render :json => 'error'.to_json, :status => :bad_request
        return
      end
      @outcome_group.update_attributes(params.slice(:title, :description, :vendor_guid))
      if params[:parent_outcome_group_id] && params[:parent_outcome_group_id] != @outcome_group.learning_outcome_group_id
        new_parent = context_outcome_groups.find(params[:parent_outcome_group_id])
        unless new_parent.adopt_outcome_group(@outcome_group)
          render :json => 'error'.to_json, :status => :bad_request
          return
        end
      end
      if @outcome_group.save
        render :json => outcome_group_json(@outcome_group, @current_user, session)
      else
        render :json => @outcome_group.errors, :status => :bad_request
      end
    end
  end

  # @API Delete an outcome group
  #
  # Deleting an outcome group deletes descendant outcome groups and outcome
  # links. The linked outcomes themselves are only deleted if all links to the
  # outcome were deleted.
  #
  # Aligned outcomes cannot be deleted; as such, if all remaining links to an
  # aligned outcome are included in this group's descendants, the group
  # deletion will fail.
  #
  # @returns OutcomeGroup
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/1/outcome_groups/2.json' \
  #        -X DELETE \ 
  #        -H "Authorization: Bearer <token>"
  #
  def destroy
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      if @outcome_group.learning_outcome_group_id.nil?
        render :json => 'error'.to_json, :status => :bad_request
        return
      end
      begin
        @outcome_group.skip_tag_touch = true
        @outcome_group.destroy
        @context.try(:touch)
        render :json => outcome_group_json(@outcome_group, @current_user, session)
      rescue ActiveRecord::RecordNotSaved
        render :json => 'error'.to_json, :status => :bad_request
      end
    end
  end

  # @API List linked outcomes
  #
  # List the immediate OutcomeLink children of the outcome group. Paginated.
  #
  # @returns [OutcomeLink]
  #
  def outcomes
    if can_read_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])

      # get and paginate links from group
      link_scope = @outcome_group.child_outcome_links.active.order_by_outcome_title
      url = polymorphic_url [:api_v1, @context || :global, :outcome_group_outcomes], :id => @outcome_group.id
      @links = Api.paginate(link_scope, self, url)

      # pre-populate the links' groups and contexts to prevent
      # extraneous loads
      @links.each do |link|
        link.associated_asset = @outcome_group
        link.context = @outcome_group.context
      end

      # preload the links' outcomes' contexts.
      ContentTag.send(:preload_associations, @links, :learning_outcome_content => :context)

      # render to json and serve
      render :json => @links.map{ |link| outcome_link_json(link, @current_user, session) }
    end
  end

  # Intentionally undocumented in the API. Used by the UI to show a list of
  # accounts' root outcome groups for the account(s) above the context.
  def account_chain
    if authorized_action(@context, @current_user, :manage_outcomes)
      account_chain =
        if @context.is_a?(Account)
          @context.account_chain - [@context]
        else
          @context.account.account_chain
        end
      account_chain.map! {|a| {
          :id => a.root_outcome_group.id,
          :title => a.name,
          :description => t('account_group_description', 'Account level outcomes group.'),
          :dontImport => true,
          :url => polymorphic_path([:api_v1, a, :outcome_group], :id => a.root_outcome_group.id),
          :subgroups_url => polymorphic_path([:api_v1, a, :outcome_group_subgroups], :id => a.root_outcome_group.id),
          :outcomes_url => polymorphic_path([:api_v1, a, :outcome_group_outcomes], :id => a.root_outcome_group.id)
        } }
      path = polymorphic_path [:api_v1, @context, :account_chain]
      account_chain = Api.paginate(account_chain, self, path)

      render :json => account_chain
    end
  end

  # @API Create/link an outcome
  #
  # Link an outcome into the outcome group. The outcome to link can either be
  # specified by a PUT to the link URL for a specific outcome (the outcome_id
  # in the PUT URLs) or by supplying the information for a new outcome (title,
  # description, ratings, mastery_points) in a POST to the collection.
  #
  # If linking an existing outcome, the outcome_id must identify an outcome
  # available to this context; i.e. an outcome owned by this group's context,
  # an outcome owned by an associated account, or a global outcome. With
  # outcome_id present, any other parameters are ignored.
  #
  # If defining a new outcome, the outcome is created in the outcome group's
  # context using the provided title, description, ratings, and mastery points;
  # the title is required but all other fields are optional. The new outcome is
  # then linked into the outcome group.
  #
  # If ratings are provided when creating a new outcome, an embedded rubric
  # criterion is included in the new outcome. This criterion's mastery_points
  # default to the maximum points in the highest rating if not specified in the
  # mastery_points parameter. Any ratings lacking a description are given a
  # default of "No description". Any ratings lacking a point value are given a
  # default of 0. If no ratings are provided, the mastery_points parameter is
  # ignored.
  #
  # @argument outcome_id [Integer]
  #   The ID of the existing outcome to link.
  #
  # @argument title [String]
  #   The title of the new outcome. Required if outcome_id is absent.
  #
  # @argument display_name [String]
  #   A friendly name shown in reports for outcomes with cryptic titles,
  #   such as common core standards names.
  #
  # @argument description [String]
  #   The description of the new outcome.
  #
  # @argument vendor_guid [String]
  #   A custom GUID for the learning standard.
  #
  # @argument mastery_points [Integer]
  #   The mastery threshold for the embedded rubric criterion.
  #
  # @argument ratings[][description] [String]
  #   The description of a rating level for the embedded rubric criterion.
  #
  # @argument ratings[][points] [Integer]
  #   The points corresponding to a rating level for the embedded rubric criterion.
  #
  # @returns OutcomeLink
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/1/outcome_groups/1/outcomes/1.json' \
  #        -X PUT \ 
  #        -H "Authorization: Bearer <token>"
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/1/outcome_groups/1/outcomes.json' \
  #        -X POST \ 
  #        -F 'title=Outcome Title' \ 
  #        -F 'display_name=Title for reporting' \
  #        -F 'description=Outcome description' \
  #        -F 'vendor_guid=customid9000' \
  #        -F 'mastery_points=3' \ 
  #        -F 'ratings[][description]=Exceeds Expectations' \ 
  #        -F 'ratings[][points]=5' \ 
  #        -F 'ratings[][description]=Meets Expectations' \ 
  #        -F 'ratings[][points]=3' \ 
  #        -F 'ratings[][description]=Does Not Meet Expectations' \ 
  #        -F 'ratings[][points]=0' \ 
  #        -H "Authorization: Bearer <token>"
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/1/outcome_groups/1/outcomes.json' \
  #        -X POST \ 
  #        --data-binary '{
  #              "title": "Outcome Title",
  #              "display_name": "Title for reporting",
  #              "description": "Outcome description",
  #              "vendor_guid": "customid9000",
  #              "mastery_points": 3,
  #              "ratings": [
  #                { "description": "Exceeds Expectations", "points": 5 },
  #                { "description": "Meets Expectations", "points": 3 },
  #                { "description": "Does Not Meet Expectations", "points": 0 }
  #              ]
  #            }' \ 
  #        -H "Content-Type: application/json" \ 
  #        -H "Authorization: Bearer <token>"
  #
  def link
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      if params[:outcome_id]
        @outcome = context_available_outcome(params[:outcome_id])
        unless @outcome
          render :json => 'error'.to_json, :status => :bad_request
          return
        end
      else
        @outcome = context_create_outcome(params.slice(:title, :description, :ratings, :mastery_points, :vendor_guid, :display_name))
        unless @outcome.valid?
          render :json => @outcome.errors, :status => :bad_request
          return
        end
      end
      @outcome_link = @outcome_group.add_outcome(@outcome)
      render :json => outcome_link_json(@outcome_link, @current_user, session)
    end
  end

  # @API Unlink an outcome
  #
  # Unlinking an outcome only deletes the outcome itself if this was the last
  # link to the outcome in any group in any context. Aligned outcomes cannot be
  # deleted; as such, if this is the last link to an aligned outcome, the
  # unlinking will fail.
  #
  # @returns OutcomeLink
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/1/outcome_groups/1/outcomes/1.json' \
  #        -X DELETE \ 
  #        -H "Authorization: Bearer <token>"
  #
  def unlink
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      @outcome_link = @outcome_group.child_outcome_links.active.where(content_id: params[:outcome_id]).first
      raise ActiveRecord::RecordNotFound unless @outcome_link
      begin
        @outcome_link.destroy
        render :json => outcome_link_json(@outcome_link, @current_user, session)
      rescue ContentTag::LastLinkToOutcomeNotDestroyed => error
        render :json => { 'message' => error.message }, :status => :bad_request
      rescue ActiveRecord::RecordNotSaved
        render :json => 'error'.to_json, :status => :bad_request
      end
    end
  end

  # @API List subgroups
  #
  # List the immediate OutcomeGroup children of the outcome group. Paginated.
  #
  # @returns [OutcomeGroup]
  #
  def subgroups
    if can_read_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])

      # get and paginate subgroups from group
      subgroup_scope = @outcome_group.child_outcome_groups.active.order_by_title
      url = polymorphic_url [:api_v1, @context || :global, :outcome_group_subgroups], :id => @outcome_group.id
      @subgroups = Api.paginate(subgroup_scope, self, url)

      # pre-populate the subgroups' parent groups to prevent extraneous
      # loads
      @subgroups.each{ |group| group.context = @outcome_group.context }

      # render to json and serve
      render :json => @subgroups.map{ |group| outcome_group_json(group, @current_user, session, :abbrev) }
    end
  end

  # @API Create a subgroup
  #
  # Creates a new empty subgroup under the outcome group with the given title
  # and description.
  #
  # @argument title [Required, String]
  #   The title of the new outcome group.
  #
  # @argument description [String]
  #   The description of the new outcome group.
  #
  # @argument vendor_guid [String]
  #   A custom GUID for the learning standard
  #
  # @returns OutcomeGroup
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/1/outcome_groups/1/subgroups.json' \
  #        -X POST \ 
  #        -F 'title=Outcome Group Title' \ 
  #        -F 'description=Outcome group description' \
  #        -F 'vendor_guid=customid9000' \
  #        -H "Authorization: Bearer <token>"
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/1/outcome_groups/1/subgroups.json' \
  #        -X POST \ 
  #        --data-binary '{
  #              "title": "Outcome Group Title",
  #              "description": "Outcome group description",
  #              "vendor_guid": "customid9000"
  #            }' \ 
  #        -H "Content-Type: application/json" \ 
  #        -H "Authorization: Bearer <token>"
  #
  def create
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      @child_outcome_group = @outcome_group.child_outcome_groups.build(params.slice(:title, :description, :vendor_guid))
      if @child_outcome_group.save
        render :json => outcome_group_json(@child_outcome_group, @current_user, session)
      else
        render :json => 'error'.to_json, :status => :bad_request
      end
    end
  end

  # @API Import an outcome group
  #
  # Creates a new subgroup of the outcome group with the same title and
  # description as the source group, then creates links in that new subgroup to
  # the same outcomes that are linked in the source group. Recurses on the
  # subgroups of the source group, importing them each in turn into the new
  # subgroup.
  #
  # Allows you to copy organizational structure, but does not create copies of
  # the outcomes themselves, only new links.
  #
  # The source group must be either global, from the same context as this
  # outcome group, or from an associated account. The source group cannot be
  # the root outcome group of its context.
  #
  # @argument source_outcome_group_id [Required, Integer]
  #   The ID of the source outcome group.
  #
  # @returns OutcomeGroup
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/2/outcome_groups/3/import.json' \
  #        -X POST \ 
  #        -F 'source_outcome_group_id=2' \ 
  #        -H "Authorization: Bearer <token>"
  #
  def import
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])

      # source has to exist
      @source_outcome_group = LearningOutcomeGroup.active.where(id: params[:source_outcome_group_id]).first
      unless @source_outcome_group
        render :json => 'error'.to_json, :status => :bad_request
        return
      end

      # source has to be global, in same context, or in an associated
      # account
      source_context = @source_outcome_group.context
      unless !source_context || source_context == @context || @context.associated_accounts.include?(source_context)
        render :json => 'error'.to_json, :status => :bad_request
        return
      end

      # source can't be a root group
      unless @source_outcome_group.learning_outcome_group_id
        render :json => 'error'.to_json, :status => :bad_request
        return
      end

      # import the validated source
      @child_outcome_group = @outcome_group.add_outcome_group(@source_outcome_group)
      render :json => outcome_group_json(@child_outcome_group, @current_user, session)
    end
  end

  protected

  def can_read_outcomes
    if @context
      authorized_action(@context, @current_user, :read_outcomes)
    else
      authorized_action(Account.site_admin, @current_user, :read_global_outcomes)
    end
  end

  def can_manage_outcomes
    if @context
      authorized_action(@context, @current_user, :manage_outcomes)
    else
      authorized_action(Account.site_admin, @current_user, :manage_global_outcomes)
    end
  end

  # get the active outcome groups in the context/global
  def context_outcome_groups
    LearningOutcomeGroup.for_context(@context).active
  end

  def context_outcome_links
    if @context
      @context.learning_outcome_links
    # else, there's no convenient way to find the global content tags; not supporting this for now
    end
  end

  # verify the outcome is eligible to be linked into the context,
  # returning the outcome if so
  def context_available_outcome(outcome_id)
    if @context
      @context.available_outcome(outcome_id, :allow_global => true)
    else
      LearningOutcome.global.where(id: outcome_id).first
    end
  end

  def context_create_outcome(data)
    scope = @context ? @context.created_learning_outcomes : LearningOutcome.global
    outcome = scope.build(data.slice(:title, :display_name, :description, :vendor_guid))
    if data[:ratings]
      outcome.rubric_criterion = data.slice(:ratings, :mastery_points)
    end
    outcome.save
    outcome
  end
end
