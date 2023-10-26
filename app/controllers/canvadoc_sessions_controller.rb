# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class CanvadocSessionsController < ApplicationController
  include CanvadocsHelper
  include CoursesHelper
  include HmacHelper

  def create
    submission_attempt, submission_id = params.require([:submission_attempt, :submission_id])

    begin
      submission = Submission.active.find(submission_id)
    rescue ActiveRecord::RecordNotFound
      return render_unauthorized_action
    end

    return unless authorized_action(submission, @current_user, :read)
    return render_unauthorized_action if submission.assignment.annotatable_attachment_id.blank?

    is_draft = submission_attempt == "draft"

    if is_draft && submission.attempts_left == 0
      error_message = "There are no more attempts available for this submission"
      return render json: { error: error_message }, status: :bad_request
    end

    annotation_context = if is_draft
                           submission.annotation_context(draft: true)
                         else
                           submission.annotation_context(attempt: submission_attempt.to_i)
                         end

    if annotation_context.nil?
      return render json: { error: "No annotations associated with that submission_attempt" }, status: :bad_request
    end

    # Check whether the user can view annotations
    enable_annotations = annotation_context.grants_right?(@current_user, :read)
    # Allow observers to continue with annotations disabled (viewing draft) while others are unauthorized
    return render_unauthorized_action unless enable_annotations || submission.observer?(@current_user)

    render json: {
      annotation_context_launch_id: annotation_context.launch_id,
      canvadocs_session_url: canvadocs_session_url(
        @current_user,
        annotation_context,
        submission,
        true,
        enable_annotations
      )
    }
  end

  # @API Document Previews
  # This API can only be accessed when another endpoint provides a signed URL.
  # It will simply redirect you to the 3rd party document preview.
  def show
    blob = extract_blob(params[:hmac],
                        params[:blob],
                        "user_id" => @current_user.try(:global_id),
                        "type" => "canvadoc")
    attachment = Attachment.find(blob["attachment_id"])

    if attachment.canvadocable?
      opts = {
        preferred_plugins: [Canvadocs::RENDER_PDFJS, Canvadocs::RENDER_BOX, Canvadocs::RENDER_CROCODOC],
        enable_annotations: blob["enable_annotations"],
        use_cloudfront: true
      }
      opts[:send_usage_metrics] = @current_user.account.feature_enabled?(:send_usage_metrics) if @current_user

      submission_id = blob["submission_id"]
      if submission_id
        submission = Submission.preload(:assignment).find(submission_id)
        options = { submission: }

        if blob["annotation_context"]
          attempt = submission.canvadocs_annotation_contexts.find_by(launch_id: blob["annotation_context"])&.submission_attempt
          options[:attempt] = attempt if attempt && attempt != submission.attempt
        end

        user_session_params = Canvadocs.user_session_params(@current_user, **options)
      else
        user_session_params = Canvadocs.user_session_params(@current_user, attachment:)
      end

      if opts[:enable_annotations]
        assignment = submission.assignment
        # Docviewer only cares about the enrollment type when we're doing annotations
        opts[:disable_annotation_notifications] = blob["disable_annotation_notifications"] || false
        # We need to have another mechanism in which we can set enrollment type in the case
        # that it's not provided in the params from a valid context i.e. ePortfolios
        opts[:enrollment_type] = blob["enrollment_type"] || user_type(assignment.context, @current_user)
        # If we STILL don't have a role, something went way wrong so let's be unauthorized.
        return render(plain: "unauthorized", status: :unauthorized) if opts[:enrollment_type].blank?

        # If we're doing annotations, DocViewer needs additional information to send notifications
        opts[:canvas_base_url] = assignment.course.root_account.domain
        opts[:user_id] = @current_user.id
        opts[:submission_user_ids] = submission.group_id ? submission.group.users.pluck(:id) : [submission.user_id]
        opts[:course_id] = assignment.context_id
        opts[:assignment_id] = assignment.id
        opts[:submission_id] = submission.id
        opts[:post_manually] = assignment.post_manually?
        opts[:posted_at] = submission.posted_at
        opts[:assignment_name] = assignment.name

        opts[:audit_url] = submission_docviewer_audit_events_url(submission_id) if assignment.auditable?
        opts[:anonymous_instructor_annotations] = !!blob["anonymous_instructor_annotations"] if blob["anonymous_instructor_annotations"]

        # "annotation_context" should be present only when the assignment is a student annotation.
        if blob["annotation_context"].present?
          opts[:annotation_context] = blob["annotation_context"]
          annotation_context = submission.canvadocs_annotation_contexts.find_by(launch_id: opts[:annotation_context])
          opts[:read_only] = !annotation_context.grants_right?(@current_user, :annotate)
        end
      end

      if @domain_root_account.settings[:canvadocs_prefer_office_online]
        opts[:preferred_plugins].unshift Canvadocs::RENDER_O365
      end

      if blob["annotation_context"]
        annotation_context_id = if ApplicationController.test_cluster?
                                  # since Canvas test environments are often configured to point at production
                                  # DocViewer environments, this prevents making an annotation on Canavs beta and
                                  # having it show up on Canvas prod.  See CAS-1551
                                  # TODO: a proper Canvas/DocViewer environment pairing and beta refresh from prod on DocViewer
                                  blob["annotation_context"] + "-#{ApplicationController.test_cluster_name}"
                                else
                                  blob["annotation_context"]
                                end
        opts[:annotation_context] = annotation_context_id
      end
      attachment.submit_to_canvadocs(1, **opts) unless attachment.canvadoc_available?

      url = attachment.canvadoc.session_url(opts.merge(user_session_params))
      # For the purposes of reporting student viewership, we only
      # care if the original attachment owner is looking
      # Depending on how the attachment came to exist that might be
      # either the context of the attachment or the attachments' user
      if (attachment.context == @current_user) || (attachment.user == @current_user)
        attachment.touch(:viewed_at)
        @current_user&.mark_submission_annotations_read!(submission) if submission && opts[:enable_annotations]
      end

      redirect_to url
    else
      render plain: "Not found", status: :not_found
    end
  rescue HmacHelper::Error => e
    Canvas::Errors.capture_exception(:canvadocs, e, :info)
    render plain: "unauthorized", status: :unauthorized
  rescue Timeout::Error, Canvadocs::BadGateway, Canvadocs::ServerError, Canvadocs::HeavyLoadError => e
    Canvas::Errors.capture_exception(:canvadocs, e, :warn)
    render plain: "Service is currently unavailable. Try again later.",
           status: :service_unavailable
  rescue Canvadocs::BadRequest => e
    Canvas::Errors.capture_exception(:canvadocs, e, :info)
    render plain: "Canvadocs Bad Request", status: :bad_request
  rescue Canvadocs::HttpError => e
    Canvas::Errors.capture_exception(:canvadocs, e, :error)
    render plain: "Unknown Canvadocs Error", status: :service_unavailable
  end
end
