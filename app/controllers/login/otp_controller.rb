#
# Copyright (C) 2015 Instructure, Inc.
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

require 'barby'
require 'barby/barcode/qr_code'
require 'barby/outputter/png_outputter'
require 'rotp'

class Login::OtpController < ApplicationController
  include Login::Shared
  include Login::OtpHelper

  before_action :require_user
  before_action :require_password_session
  before_action :forbid_on_files_domain

  def new
    # if we waiting on OTP for login, but we're not yet configured, start configuring
    # OR if we're not waiting on OTP, we're configuring
    if session[:pending_otp] && !secret_key ||
        !session[:pending_otp] && !configuring?
      session[:pending_otp_secret_key] = ROTP::Base32.random_base32
      @first_reconfiguration = true
    end
    if session[:pending_otp_communication_channel_id]
      @cc = @current_user.communication_channels.find(session[:pending_otp_communication_channel_id])
    elsif !configuring?
      @cc = @current_user.otp_communication_channel
    end

    send_otp unless configuring?
  end

  def send_via_sms
    return render status: 400, text: "can't change destination until you're logged in" unless configuring?

    if params[:otp_login].try(:[], :otp_communication_channel_id)
      cc = @current_user.communication_channels.sms.unretired.find(params[:otp_login][:otp_communication_channel_id])
      session[:pending_otp_communication_channel_id] = cc.id
    end
    if session[:pending_otp_secret_key] && params[:otp_login].try(:[], :phone_number)
      path = "#{params[:otp_login][:phone_number].gsub(/[^\d]/, '')}@#{params[:otp_login][:carrier]}"
      cc = @current_user.communication_channels.sms.by_path(path).first
      cc ||= @current_user.communication_channels.sms.create!(:path => path)
      if cc.retired?
        cc.workflow_state = 'unconfirmed'
        cc.save!
      end
      session[:pending_otp_communication_channel_id] = cc.id
    end
    send_otp(cc)

    redirect_to otp_login_url
  end

  def create
    verification_code = params[:otp_login][:verification_code]
    if Canvas.redis_enabled?
      key = "otp_used:#{@current_user.global_id}:#{verification_code}"
      if Canvas.redis.get(key)
        force_fail = true
      else
        Canvas.redis.setex(key, 10.minutes, '1')
      end
    end

    drift = 30
    # give them 5 minutes to enter an OTP sent via SMS
    drift = 300 if session[:pending_otp_communication_channel_id] ||
        (!session[:pending_otp_secret_key] && @current_user.otp_communication_channel_id)

    if !force_fail && ROTP::TOTP.new(secret_key).verify_with_drift(verification_code, drift)
      if configuring?
        @current_user.otp_secret_key = session.delete(:pending_otp_secret_key)
        @current_user.otp_communication_channel_id = session.delete(:pending_otp_communication_channel_id)
        @current_user.otp_communication_channel.try(:confirm)
        @current_user.save!
      end

      if params[:otp_login][:remember_me] == '1'
        now = Time.now.utc
        old_cookie = cookies['canvas_otp_remember_me']
        old_cookie = nil unless @current_user.validate_otp_secret_key_remember_me_cookie(old_cookie)
        cookies['canvas_otp_remember_me'] = {
            :value => @current_user.otp_secret_key_remember_me_cookie(now, old_cookie, request.remote_ip),
            :expires => now + 30.days,
            :domain => remember_me_cookie_domain,
            :httponly => true,
            :secure => CanvasRails::Application.config.session_options[:secure],
            :path => '/login'
        }
      end
      if session.delete(:pending_otp)
        successful_login(@current_user, @current_pseudonym, true)
      else
        flash[:notice] = t "Multi-factor authentication configured"
        redirect_to settings_profile_url
      end
    else
      flash[:error] = t 'errors.invalid_otp', "Invalid verification code, please try again"
      redirect_to otp_login_url
    end
  end

  def destroy
    if params[:user_id] == 'self'
      user = @current_user
    else
      user = User.find(params[:user_id])
    end
    return unless authorized_action(user, @current_user, :reset_mfa)

    user.otp_secret_key = nil
    user.otp_communication_channel = nil
    user.save!

    render :json => {}
  end

  protected

  def send_otp(cc = nil)
    cc ||= @current_user.otp_communication_channel
    cc.try(:send_later_if_production_enqueue_args, :send_otp!,
      { :priority => Delayed::HIGH_PRIORITY, :max_attempts => 1 },
      ROTP::TOTP.new(secret_key).now)
  end

  def secret_key
    session[:pending_otp_secret_key] || @current_user.otp_secret_key
  end
end
