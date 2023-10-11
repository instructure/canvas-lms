# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Canvadocs
  module Session
    include CanvadocsHelper
    # this expects the class to have submissions and attachment defined
    def canvadocs_session_url(opts = {})
      user = opts.delete(:user)
      enable_annotations = opts.delete(:enable_annotations)
      read_only = opts.delete(:read_only) || false
      opts.reverse_merge! canvadoc_permissions_for_user(user, enable_annotations, read_only)
      opts[:url] = attachment.public_url(expires_in: 7.days)
      opts[:locale] = I18n.locale || I18n.default_locale
      opts[:send_usage_metrics] = user.account.feature_enabled?(:send_usage_metrics) if user
      opts[:is_launch_token] = Account.site_admin.feature_enabled?(:enhanced_docviewer_url_security)

      Canvas.timeout_protection("canvadocs", raise_on_timeout: true) do
        session = canvadocs_api.session(document_id, opts)
        canvadocs_api.view(session["id"])
      end
    end

    def canvadocs_api
      @canvadocs_api ||= Canvadoc.canvadocs_api
    end
    private :canvadocs_api

    def canvadoc_permissions_for_user(user, enable_annotations, read_only = false)
      return {} unless enable_annotations && canvadocs_can_annotate?(user)

      opts = canvadocs_default_options_for_user(user, read_only)
      return opts if submissions.empty?

      if submissions.any? { |s| s.user_can_read_grade?(user) }
        opts.delete :user_filter
      end

      # no commenting when anonymous peer reviews are enabled
      if submissions.map(&:assignment).any? { |a| a.peer_reviews? && a.anonymous_peer_reviews? }
        opts = {}
      end

      opts
    end
    private :canvadoc_permissions_for_user

    def submission_context_ids
      @submission_context_ids ||= submissions.map { |s| s.assignment.context_id }.uniq
    end

    def observing?(user)
      user.observer_enrollments.active.where(course_id: submission_context_ids,
                                             associated_user_id: submissions.map(&:user_id)).exists?
    end

    def managing?(user)
      is_teacher = user.teacher_enrollments.active.where(course_id: submission_context_ids).exists?
      return true if is_teacher

      course = submissions.first.assignment.course
      course.account_membership_allows(user)
    end
    private :managing?

    def canvadocs_can_annotate?(user)
      user.present?
    end
    private :canvadocs_can_annotate?

    def canvadocs_annotation_context
      if ApplicationController.test_cluster?
        return "default-#{ApplicationController.test_cluster_name}"
      end

      "default"
    end
    private :canvadocs_annotation_context

    def canvadocs_permissions(user, read_only)
      return "read" if read_only
      return "readwrite" if submissions.empty?
      return "readwritemanage" if managing?(user)
      return "read" if observing?(user)

      "readwrite"
    end
    private :canvadocs_permissions

    def canvadocs_default_options_for_user(user, read_only)
      {
        annotation_context: canvadocs_annotation_context,
        permissions: canvadocs_permissions(user, read_only),
        user_id: canvadocs_user_id(user),
        user_name: canvadocs_user_name(user),
        user_filter: canvadocs_user_id(user),
      }
    end
    private :canvadocs_default_options_for_user
  end
end
