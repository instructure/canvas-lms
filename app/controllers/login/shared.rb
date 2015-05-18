module Login::Shared
  def reset_session_for_login
    reset_session_saving_keys(:return_to,
                              :oauth,
                              :oauth2,
                              :confirm,
                              :enrollment,
                              :expected_user_id,
                              :masquerade_return_to,
                              :oauth2_nonce)
  end

  def successful_login(user, pseudonym, otp_passed = false)
    CanvasBreachMitigation::MaskingSecrets.reset_authenticity_token!(cookies)
    Auditors::Authentication.record(@current_pseudonym, 'login')

    # Since the user just logged in, we'll reset the context to include their info.
    setup_live_events_context
    # TODO: Only send this if the current_pseudonym's root account matches the current root
    # account?
    Canvas::LiveEvents.logged_in(session)

    otp_passed ||= user.validate_otp_secret_key_remember_me_cookie(cookies['canvas_otp_remember_me'], request.remote_ip)
    unless otp_passed
      mfa_settings = user.mfa_settings
      if (user.otp_secret_key && mfa_settings == :optional) ||
          mfa_settings == :required
        session[:pending_otp] = true
        return redirect_to otp_login_url
      end
    end

    if pseudonym.account_id != (@real_domain_root_account || @domain_root_account).id
      flash[:notice] = t("You are logged in at %{institution1} using your credentials from %{institution2}",
                         institution1: (@real_domain_root_account || @domain_root_account).name,
                         institution2: pseudonym.account.name)
    end

    if pseudonym.account_id == Account.site_admin.id && Account.site_admin.delegated_authentication?
      cookies['canvas_sa_delegated'] = {
          :value => '1',
          :domain => remember_me_cookie_domain,
          :httponly => true,
          :secure => CanvasRails::Application.config.session_options[:secure]
      }
    end
    session[:require_terms] = true if @domain_root_account.require_acceptance_of_terms?(user)

    respond_to do |format|
      if (oauth = session[:oauth2])
        provider = Canvas::Oauth::Provider.new(oauth[:client_id], oauth[:redirect_uri], oauth[:scopes], oauth[:purpose])
        return redirect_to Canvas::Oauth::Provider.confirmation_redirect(self, provider, user)
      elsif session[:course_uuid] && user &&
          (course = Course.where(uuid: session[:course_uuid], workflow_state: "created").first)
        claim_session_course(course, user)
        format.html { redirect_to(course_url(course, :login_success => '1')) }
      elsif session[:confirm]
        format.html do
          redirect_to(registration_confirmation_path(session.delete(:confirm),
                                                     enrollment: session.delete(:enrollment),
                                                     login_success: 1,
                                                     confirm: (user.id == session.delete(:expected_user_id) ? 1 : nil)))
        end
      else
        # the URL to redirect back to is stored in the session, so it's
        # assumed that if that URL is found rather than using the default,
        # they must have cookies enabled and we don't need to worry about
        # adding the :login_success param to it.
        format.html { redirect_back_or_default(dashboard_url(:login_success => '1')) }
      end
      format.json { render :json => pseudonym.as_json(:methods => :user_code), :status => :ok }
    end
  end

  def logout_current_user
    CanvasBreachMitigation::MaskingSecrets.reset_authenticity_token!(cookies)
    Auditors::Authentication.record(@current_pseudonym, 'logout')
    Canvas::LiveEvents.logged_out
    Lti::LogoutService.queue_callbacks(@current_pseudonym)
    super
  end

  def forbid_on_files_domain
    if HostUrl.is_file_host?(request.host_with_port)
      reset_session
      return redirect_to dashboard_url(:host => HostUrl.default_host)
    end
    true
  end

  def check_sa_delegated_cookie
    if cookies['canvas_sa_delegated']
      @real_domain_root_account = @domain_root_account
      @domain_root_account = Account.site_admin
    end
  end

  include PseudonymSessionsController
  def remember_me_cookie_domain
    otp_remember_me_cookie_domain
  end
end
