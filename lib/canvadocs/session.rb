
module Canvadocs
  module Session
    # this expects the class to have submissions and attachment defined
    def canvadocs_session_url(opts = {})
      user = opts.delete(:user)
      enable_annotations = opts.delete(:enable_annotations)
      moderated_grading_whitelist = opts.delete(:moderated_grading_whitelist)
      opts.merge! canvadoc_permissions_for_user(user, enable_annotations, moderated_grading_whitelist)
      opts[:url] = attachment.public_url(expires_in: 7.days)
      opts[:locale] = I18n.locale || I18n.default_locale

      Canvas.timeout_protection("canvadocs", raise_on_timeout: true) do
        session = canvadocs_api.session(document_id, opts)
        canvadocs_api.view(session["id"])
      end
    end

    def canvadocs_api
      @canvadocs_api ||= Canvadoc.canvadocs_api
    end
    private :canvadocs_api

    def canvadoc_permissions_for_user(user, enable_annotations, moderated_grading_whitelist=nil)
      return {} unless enable_annotations && canvadocs_can_annotate?(user)
      return canvadocs_default_options_for_user(user) if submissions.empty?
      opts = canvadocs_default_options_for_user(user, observing?(user))

      opts[:read_grade] = submissions.any? { |s| s.grants_right? user, :read_grade }
      opts.delete :user_filter if opts[:read_grade]

      # no commenting when anonymous peer reviews are enabled
      if submissions.map(&:assignment).any? { |a| a.peer_reviews? && a.anonymous_peer_reviews? }
        opts = {}
      end

      canvadocs_apply_whitelist(opts, moderated_grading_whitelist) if moderated_grading_whitelist

      opts
    end
    private :canvadoc_permissions_for_user

    def observing?(user)
      user.enrollments.each do |enrollment|
        next unless enrollment.type == "ObserverEnrollment"
        submissions.each do |submission|
          if submission.assignment.context_id == enrollment.course_id &&
            submission.user_id == enrollment.associated_user_id
            return true
          end
        end
      end
      false
    end

    def canvadocs_can_annotate?(user)
      user.present?
    end
    private :canvadocs_can_annotate?

    def canvadocs_apply_whitelist(opts, moderated_grading_whitelist)
      flat_whitelist = moderated_grading_whitelist.map { |h| [h["crocodoc_id"], h["global_id"]] }.flatten.compact
      read_grade = opts.delete :read_grade
      whitelisted_users = if read_grade
                            flat_whitelist
                          else
                            [opts[:user_filter]] & flat_whitelist
                          end

      opts[:user_filter] = 'none'
      opts[:user_filter] = whitelisted_users.join(',') unless whitelisted_users.empty?

    end
    private :canvadocs_apply_whitelist

    def canvadocs_annotation_context
      if ApplicationController.respond_to?(:test_cluster?) && ApplicationController.test_cluster?
        return "default-#{ApplicationController.test_cluster_name}"
      end
      "default"
    end
    private :canvadocs_annotation_context

    def canvadocs_default_options_for_user(user, observing=false)
      opts = {
        annotation_context: canvadocs_annotation_context,
        permissions: observing ? 'read' : 'readwrite',
        user_id: user.global_id.to_s,
        user_name: user.short_name.delete(","),
        user_role: "",
        user_filter: user.global_id.to_s,
      }
      opts[:user_crocodoc_id] = user.crocodoc_id if user.crocodoc_id
      opts
    end
    private :canvadocs_default_options_for_user
  end
end
