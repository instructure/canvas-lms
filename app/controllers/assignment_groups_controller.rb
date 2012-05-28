#
# Copyright (C) 2011 Instructure, Inc.
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

# @API Assignment Groups
#
# API for accessing Assignment Group and Assignment information.
class AssignmentGroupsController < ApplicationController
  before_filter :require_context

  include Api::V1::Assignment

  # @API List assignment groups
  # Returns the list of assignment groups for the current context. The returned
  # groups are sorted by their position field.
  #
  # @argument include[] ["assignments"] Associations to include with the group.
  #
  # @response_field id The unique identifier for the assignment group.
  # @response_field name The name of the assignment group.
  # @response_field position [Integer] The sorting order of this group in the
  #   groups for this context.
  #
  # @example_response
  #   [
  #     {
  #       "position": 7,
  #       "name": "group2",
  #       "id": 1,
  #       "group_weight": 20,
  #       "assignments": [...],
  #       "rules" : {...}
  #     },
  #     {
  #       "position": 10,
  #       "name": "group1",
  #       "id": 2,
  #       "group_weight": 20,
  #       "assignments": [...],
  #       "rules" : {...}
  #     },
  #     {
  #       "position": 12,
  #       "name": "group3",
  #       "id": 3,
  #       "group_weight": 60,
  #       "assignments": [...],
  #       "rules" : {...}
  #     }
  #   ]
  def index
    @groups = @context.assignment_groups.active

    include_assignments = Array(params[:include]).include?('assignments')
    if include_assignments
      @groups = @groups.scoped(:include => { :assignments => :rubric })
    end

    if authorized_action(@context.assignment_groups.new, @current_user, :read)

      respond_to do |format|
        format.json {
          hashes = @groups.map do |group|
            hash = group.as_json(:include_root => false,
                                 :only => %w(id name position group_weight))
            # note that 'rules_hash' gets to_jsoned as just 'rules' because that is what GradeCalculator expects. 
            hash['rules'] = group.rules_hash
            if include_assignments
              hash['assignments'] = group.assignments.active.map { |a| assignment_json(a, @current_user, session, [], @context.user_is_teacher?(@current_user)) }
            end
            hash
          end
          render :json => hashes.to_json
        }
      end
    end
  end

  def reorder
    if authorized_action(@context.assignment_groups.new, @current_user, :update)
      order = params[:order].split(',')
      ids = []
      order.each_index do |idx|
        id = order[idx]
        group = @context.assignment_groups.active.find_by_id(id) if id.present?
        if group
          group.move_to_bottom
          ids << group.id
        end
      end
      respond_to do |format|
        format.json { render :json => {:reorder => true, :order => ids}, :status => :ok }
      end
    end
  end
  
  def reorder_assignments
    @group = @context.assignment_groups.find(params[:assignment_group_id])
    if authorized_action(@group, @current_user, :update)
      order = params[:order].split(',').map{|id| id.to_i }
      group_ids = ([@group.id] + (order.empty? ? [] : @context.assignments.find_all_by_id(order).map(&:assignment_group_id))).uniq.compact
      Assignment.update_all("assignment_group_id=#{@group.id}", :id => order, :context_id => @context.id, :context_type => @context.class.to_s)
      @group.assignments.first.update_order(order) unless @group.assignments.empty?
      AssignmentGroup.update_all({:updated_at => Time.now.utc}, {:id => group_ids})
      ids = @group.assignments.map(&:id)
      @context.recompute_student_scores rescue nil
      respond_to do |format|
        format.json { render :json => {:reorder => true, :order => ids}, :status => :ok }
      end
    end
  end
  
  def show
    @assignment_group = @context.assignment_groups.find(params[:id])
    if @assignment_group.deleted?
      respond_to do |format|
        flash[:notice] = t 'notices.deleted', "This group has been deleted"
        format.html { redirect_to named_context_url(@context, :assignments_url) }
      end
      return
    end
    if authorized_action(@assignment_group, @current_user, :read)
      respond_to do |format|
        format.html { redirect_to(named_context_url(@context, :context_assignments_url, @assignment_group.context_id)) }
        format.json { render :json => @assignment_group.to_json(:permissions => {:user => @current_user, :session => session}) }
      end
    end
  end

  def create
    @assignment_group = @context.assignment_groups.new(params[:assignment_group])
    if authorized_action(@assignment_group, @current_user, :create)
      respond_to do |format|
        if @assignment_group.save
          @assignment_group.insert_at(1)
          flash[:notice] = t 'notices.created', 'Assignment Group was successfully created.'
          format.html { redirect_to named_context_url(@context, :context_assignments_url) }
          format.json { render :json => @assignment_group.to_json(:permissions => {:user => @current_user, :session => session}), :status => :created}
        else
          format.json { render :json => @assignment_group.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  def update
    @assignment_group = @context.assignment_groups.find(params[:id])
    if authorized_action(@assignment_group, @current_user, :update)
      respond_to do |format|
        if @assignment_group.update_attributes(params[:assignment_group])
          flash[:notice] = t 'notices.updated', 'Assignment Group was successfully updated.'
          format.html { redirect_to named_context_url(@context, :context_assignments_url) }
          format.json { render :json => @assignment_group.to_json(:permissions => {:user => @current_user, :session => session}), :status => :ok }
        else
          format.json { render :json => @assignment_group.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  def destroy
    @assignment_group = AssignmentGroup.find(params[:id])
    if authorized_action(@assignment_group, @current_user, :delete)
      if @assignment_group.has_frozen_assignments?(@current_user)
        @assignment_group.errors.add('workflow_state', t('errors.cannot_delete_group', "You can not delete a group with a locked assignment.", :att_name => 'workflow_state'))
        respond_to do |format|
          format.html { redirect_to named_context_url(@context, :context_assignments_url) }
          format.json { render :json => @assignment_group.errors.to_json, :status => :bad_request }
        end
        return
      end

      if params[:move_assignments_to]
        @new_group = @context.assignment_groups.active.find(params[:move_assignments_to])
        order = @new_group.assignments.active.map(&:id)
        ids_to_change = @assignment_group.assignments.active.map(&:id)
        order += ids_to_change
        Assignment.update_all({:assignment_group_id => @new_group.id, :updated_at => Time.now.utc}, {:id => ids_to_change}) unless ids_to_change.empty?
        Assignment.find_by_id(order).update_order(order) unless order.empty?
        @new_group.touch
        @assignment_group.reload
      end
      @assignment_group.destroy

      respond_to do |format|
        format.html { redirect_to(named_context_url(@context, :context_assignments_url)) }
        format.json { render :json => {:assignment_group => @assignment_group, :new_assignment_group => @new_group}.to_json(:include_root => false, :include => :active_assignments) }
      end
    end
  end
end
