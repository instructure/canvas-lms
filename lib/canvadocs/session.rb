
module Canvadocs
  module Session
    # this expects the class to have submissions and attachment defined

    def canvadocs_session_url(opts = {})
      user = opts.delete(:user)
      opts.merge! canvadoc_permissions_for_user(user)
      opts[:url] = attachment.authenticated_s3_url(expires_in: 7.days)
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

    def canvadoc_permissions_for_user(user)
      return {} unless canvadocs_can_annotate? user

      annotation_context = "default"
      if ApplicationController.respond_to?(:test_cluster?) && ApplicationController.test_cluster?
        annotation_context = "default-#{ApplicationController.test_cluster_name}"
      end

      opts = {
        annotation_context: annotation_context,
        permissions: "readwrite",
        user_id: user.global_id.to_s,
        user_name: user.short_name.gsub(",", ""),
        user_role: "",
        user_filter: user.global_id.to_s,
      }

      if user.crocodoc_id != nil
        opts[:user_crocodoc_id] = user.crocodoc_id
      end

      return opts if submissions.empty?

      if submissions.any? { |s| s.grants_right? user, :read_grade }
        opts.delete :user_filter
      end

      # no commenting when anonymous peer reviews are enabled
      if submissions.map(&:assignment).any? { |a| a.peer_reviews? && a.anonymous_peer_reviews? }
        opts = {}
      end

      opts
    end
    private :canvadoc_permissions_for_user

    def canvadocs_can_annotate?(user)
      user && has_annotations?
    end
    private :canvadocs_can_annotate?

  end
end
