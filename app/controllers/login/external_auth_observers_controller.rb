class Login::ExternalAuthObserversController < ApplicationController
  def redirect_login
    if observer_email_taken?
      render json: {error: {input_name: "pseudonym[unique_id]", message: t("Email already in use")}}, status: 422
      return
    end
    unless valid_observee_unique_id?
      render json: {error: {input_name: "observee[unique_id]", message: t("Username could not be found")}}, status: 422
      return
    end
    session[:parent_registration] = {}
    session[:parent_registration][:user] = params[:user]
    session[:parent_registration][:pseudonym] = params[:pseudonym]
    session[:parent_registration][:observee] = params[:observee]
    render(json: {redirect: saml_observee_path})
  end

  private
  def observer_email_taken?
    @domain_root_account.pseudonyms.by_unique_id(params[:pseudonym][:unique_id]).exists?
  end

  def valid_observee_unique_id?
    @domain_root_account.pseudonyms.by_unique_id(params[:observee][:unique_id]).exists?
  end
end