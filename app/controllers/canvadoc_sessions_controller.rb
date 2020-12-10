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

# @API Document Previews
# This API can only be accessed when another endpoint provides a signed URL.
# It will simply redirect you to the 3rd party document preview..
#
class CanvadocSessionsController < ApplicationController
  include HmacHelper

  def show
    blob = extract_blob(params[:hmac], params[:blob],
                        "user_id" => @current_user.try(:global_id),
                        "type" => "canvadoc")
    attachment = Attachment.find(blob["attachment_id"])

    if attachment.canvadocable?
      opts = {
        preferred_plugins: [Canvadocs::RENDER_PDFJS, Canvadocs::RENDER_BOX, Canvadocs::RENDER_CROCODOC],
        enable_annotations: blob['enable_annotations']
      }

      submission_id = blob["submission_id"]
      if submission_id
        submission = Submission.preload(:assignment).find(submission_id)
        user_session_params = Canvadocs.user_session_params(@current_user, submission: submission)
      else
        user_session_params = Canvadocs.user_session_params(@current_user, attachment: attachment)
      end

      if opts[:enable_annotations]
        # Docviewer only cares about the enrollment type when we're doing annotations
        opts[:enrollment_type] = blob["enrollment_type"]
        # If we STILL don't have a role, something went way wrong so let's be unauthorized.
        return render(plain: 'unauthorized', status: :unauthorized) if opts[:enrollment_type].blank?
        assignment = submission.assignment
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
      end

      if @domain_root_account.settings[:canvadocs_prefer_office_online]
        opts[:preferred_plugins].unshift Canvadocs::RENDER_O365
      end

      attachment.submit_to_canvadocs(1, opts) unless attachment.canvadoc_available?

      url = attachment.canvadoc.session_url(opts.merge(user_session_params))
      # For the purposes of reporting student viewership, we only
      # care if the original attachment owner is looking
      # Depending on how the attachment came to exist that might be
      # either the context of the attachment or the attachments' user
      if (attachment.context == @current_user) || (attachment.user == @current_user)
        attachment.touch(:viewed_at)
      end

      redirect_to url
    else
      render :plain => "Not found", :status => :not_found
    end

  rescue HmacHelper::Error => e
    Canvas::Errors.capture_exception(:canvadocs, e, :info)
    render :plain => 'unauthorized', :status => :unauthorized
  rescue Timeout::Error, Canvadocs::BadGateway, Canvadocs::ServerError => e
    Canvas::Errors.capture_exception(:canvadocs, e, :warn)
    render :plain => "Service is currently unavailable. Try again later.",
           :status => :service_unavailable
  rescue Canvadocs::BadRequest => e
    Canvas::Errors.capture_exception(:canvadocs, e, :info)
    render :plain => 'Canvadocs Bad Request', :status => :bad_request
  rescue Canvadocs::HttpError => e
    Canvas::Errors.capture_exception(:canvadocs, e, :error)
    render :plain => 'Unknown Canvadocs Error', :status => :service_unavailable
  end
end
