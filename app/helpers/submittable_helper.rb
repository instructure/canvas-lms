#
# Copyright (C) 2016 - present Instructure, Inc.
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

module SubmittableHelper
  def check_differentiated_assignments(submittable)
    return render_unauthorized_action if submittable.for_assignment? &&
      !submittable.assignment.visible_to_user?(@current_user)
  end

  def enforce_assignment_visible(submittable)
    if @current_user && submittable.for_assignment? && !submittable.assignment.visible_to_user?(@current_user)
      respond_to do |format|
        flash[:error] = t "You do not have access to the requested resource."
        name = submittable.class.name.underscore.pluralize
        format.html { redirect_to named_context_url(@context, "context_#{name}_url".to_sym) }
      end
      return false
    end
    true
  end

  def apply_assignment_parameters(assignment_params, submittable)
    # handle creating/deleting assignment
    if assignment_params
      if assignment_params.key?(:set_assignment) &&
        !value_to_boolean(assignment_params[:set_assignment])
        if submittable.assignment && submittable.assignment.grants_right?(@current_user, session, :update)
          assignment = submittable.assignment
          submittable.assignment = nil
          submittable.save!
          assignment.send("#{submittable.class.name.underscore}=", nil)
          assignment.destroy
        end

      elsif (@assignment = submittable.assignment ||
                           submittable.restore_old_assignment ||
                           (submittable.assignment = @context.assignments.build)
            ) && @assignment.grants_right?(@current_user, session, :update)
        unless submittable.try(:group_category_id) || @assignment.has_submitted_submissions?
          assignment_params[:group_category_id] = nil
        end
        assignment_params[:published] = submittable.published?
        assignment_params[:name] = submittable.title

        submittable.assignment = @assignment
        submittable.sync_assignment
        submittable.save_without_broadcasting!

        assignment_params.except!('anonymous_peer_reviews')
        update_api_assignment(@assignment.reload, assignment_params, @current_user, @context)

        submittable.save!
      end
    end
  end
end
