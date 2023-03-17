# frozen_string_literal: true

class Login::AlphacampController < ApplicationController
  include Login::Shared

  def new
    # 如果轉跳時有需要帶入 flash alert 可以在此帶入，否則可不用帶入參數
    # message_class: 'alert', 'notice'
    # message_code: 'unauthenticated'
    sso = SingleSignOn.generate_sso(message_class: params[:message_class], message_code: params[:message_code])
    redirect_to sso.to_url
  end

  def sso_login
    sso = SingleSignOn.parse(sso_params[:sso], sso_params[:sig])

    unless sso.nonce_valid?
      return render status: 419, json: { text: "Account login timed out, please try logging in again." }
    end

    sso.expire_nonce!

    # 參考 OAuthController

    user, pseudonym = sso.lookup_or_create_user

    PseudonymSession.create!(pseudonym, false)
    successful_login(user, pseudonym)
  end

  def destroy; end

  private

  def sso_params
    params.permit(:sso, :sig)
  end
end
