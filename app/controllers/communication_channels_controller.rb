#
# Copyright (C) 2011 Instructure, Inc.
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

# @API Communication Channels
#
# API for accessing users' email addresses, SMS phone numbers, Twitter,
# and Facebook communication channels.
#
# In this API, the `:user_id` parameter can always be replaced with `self` if
# the requesting user is asking for his/her own information.
#
# @model CommunicationChannel
#     {
#       "id": "CommunicationChannel",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The ID of the communication channel.",
#           "example": 16,
#           "type": "integer"
#         },
#         "address": {
#           "description": "The address, or path, of the communication channel.",
#           "example": "sheldon@caltech.example.com",
#           "type": "string"
#         },
#         "type": {
#           "description": "The type of communcation channel being described. Possible values are: 'email', 'sms', 'chat', 'facebook' or 'twitter'. This field determines the type of value seen in 'address'.",
#           "example": "email",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "email",
#               "sms",
#               "chat",
#               "facebook",
#               "twitter"
#             ]
#           }
#         },
#         "position": {
#           "description": "The position of this communication channel relative to the user's other channels when they are ordered.",
#           "example": 1,
#           "type": "integer"
#         },
#         "user_id": {
#           "description": "The ID of the user that owns this communication channel.",
#           "example": 1,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "The current state of the communication channel. Possible values are: 'unconfirmed' or 'active'.",
#           "example": "active",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "unconfirmed",
#               "active"
#             ]
#           }
#         }
#       }
#     }
#
class CommunicationChannelsController < ApplicationController
  before_filter :require_user, :only => [:create, :destroy]
  before_filter :reject_student_view_student

  include Api::V1::CommunicationChannel

  # @API List user communication channels
  #
  # Returns a list of communication channels for the specified user, sorted by
  # position.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/12345/communication_channels \ 
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [CommunicationChannel]
  def index
    @user = api_find(User, params[:user_id])
    return unless authorized_action(@user, @current_user, :read)

    channels = Api.paginate(@user.communication_channels.unretired, self,
      api_v1_communication_channels_url).map do |cc|
        communication_channel_json(cc, @current_user, session)
      end

    render :json => channels
  end

  # @API Create a communication channel
  #
  # Creates a new communication channel for the specified user.
  #
  # @argument communication_channel[address] [Required, String]
  #   An email address or SMS number.
  #
  # @argument communication_channel[type] [Required, String, "email"|"sms"|"push"]
  #   The type of communication channel.
  #
  #   In order to enable push notification support, the server must be
  #   properly configured (via sns.yml) to communicate with Amazon
  #   Simple Notification Services, and the developer key used to create
  #   the access token from this request must have an SNS ARN configured on
  #   it.
  #
  # @argument skip_confirmation [Boolean]
  #   Only valid for site admins and account admins making requests; If true, the channel is
  #   automatically validated and no confirmation email or SMS is sent.
  #   Otherwise, the user must respond to a confirmation message to confirm the
  #   channel.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/1/communication_channels \
  #          -H 'Authorization: Bearer <token>' \
  #          -d 'communication_channel[address]=new@example.com' \
  #          -d 'communication_channel[type]=email' \
  #
  # @returns CommunicationChannel
  def create
    @user = api_request? ? api_find(User, params[:user_id]) : @current_user

    return render_unauthorized_action unless has_api_permissions?

    params.delete(:build_pseudonym) if api_request?

    skip_confirmation = value_to_boolean(params[:skip_confirmation]) &&
        (Account.site_admin.grants_right?(@current_user, :manage_students) || @domain_root_account.grants_right?(@current_user, :manage_students))

    # If a new pseudonym is requested, build (but don't save) a pseudonym to ensure
    # that the unique_id is valid. The pseudonym will be created on approval of the
    # communication channel.
    if params[:build_pseudonym]
      @pseudonym = @domain_root_account.pseudonyms.build(:user => @user,
        :unique_id => params[:communication_channel][:address])
      @pseudonym.generate_temporary_password

      unless @pseudonym.valid?
        return render :json => @pseudonym.errors.as_json, :status => :bad_request
      end
    end

    if params[:communication_channel][:type] == CommunicationChannel::TYPE_PUSH
      if !@access_token
        return render :json => { errors: { type: 'Push is only supported when using an access token'}}, status: :bad_request
      end
      if !@access_token.developer_key.try(:sns_arn)
        return render :json => { errors: { type: 'SNS is not configured for this developer key'}}, status: :bad_request
      end
      skip_confirmation = true
      @cc = @user.communication_channels.create_push(@access_token, params[:communication_channel][:address])
    end

    # Find or create the communication channel.
    @cc ||= @user.communication_channels.by_path(params[:communication_channel][:address]).
      find_by_path_type(params[:communication_channel][:type])
    @cc ||= @user.communication_channels.build(:path => params[:communication_channel][:address],
      :path_type => params[:communication_channel][:type])

    if (!@cc.new_record? && !@cc.retired? && @cc.path_type != CommunicationChannel::TYPE_PUSH)
      @cc.errors.add(:path, 'unique!')
      return render :json => @cc.errors.as_json, :status => :bad_request
    end

    @cc.user = @user
    @cc.re_activate! if @cc.retired?
    @cc.workflow_state = skip_confirmation ? 'active' : 'unconfirmed'
    @cc.build_pseudonym_on_confirm = params[:build_pseudonym].to_i > 0

    # Save channel and return response
    if @cc.save
      @cc.send_confirmation!(@domain_root_account) unless skip_confirmation

      flash[:notice] = t('profile.notices.contact_registered', 'Contact method registered!')
      render :json => communication_channel_json(@cc, @current_user, session)
    else
      render :json => @cc.errors.as_json, :status => :bad_request
    end
  end

  def confirm
    @nonce = params[:nonce]
    cc = CommunicationChannel.unretired.find_by_confirmation_code(@nonce)
    @headers = false
    if cc
      @communication_channel = cc
      @user = cc.user
      @enrollment = @user.enrollments.find_by_uuid_and_workflow_state(params[:enrollment], 'invited') if params[:enrollment].present?
      @course = @enrollment && @enrollment.course
      @root_account = @course.root_account if @course
      @root_account ||= @user.pseudonyms.first.try(:account) if @user.pre_registered?
      @root_account ||= @user.enrollments.first.try(:root_account) if @user.creation_pending?
      unless @root_account
        account = @user.all_accounts.first
        @root_account = account.try(:root_account)
      end
      @root_account ||= @domain_root_account

      # now that we've retrieved a communication channel record with our
      # nonce we can set the locale based on the associated models
      I18n.localizer = lambda {
        infer_locale :user => @user,
                     :root_account => @root_account
      }

      # logged in as an unconfirmed user?! someone's masquerading; just pretend we're not logged in at all
      if @current_user == @user && !@user.registered?
        @current_user = nil
      end

      if @user.registered? && cc.unconfirmed?
        unless @current_user == @user
          session[:return_to] = request.url
          flash[:notice] = t 'notices.login_to_confirm', "Please log in to confirm your e-mail address"
          return redirect_to login_url(:pseudonym_session => { :unique_id => @user.pseudonym.try(:unique_id) }, :expected_user_id => @user.id)
        end

        cc.confirm
        @user.touch
        flash[:notice] = t 'notices.registration_confirmed', "Registration confirmed!"
        return respond_to do |format|
          format.html { redirect_back_or_default(user_profile_url(@current_user)) }
          format.json { render :json => cc.as_json(:except => [:confirmation_code] ) }
        end
      end

      # load merge opportunities
      merge_users = cc.merge_candidates
      merge_users << @current_user if @current_user && !@user.registered? && !merge_users.include?(@current_user)
      # remove users that don't have a pseudonym for this account, or one can't be created
      merge_users = merge_users.select { |u| u.find_or_initialize_pseudonym_for_account(@root_account, @domain_root_account) }
      @merge_opportunities = []
      merge_users.each do |user|
        account_to_pseudonyms_hash = {}
        root_account_pseudonym = user.find_pseudonym_for_account(@root_account)
        if root_account_pseudonym
          @merge_opportunities << [user, [root_account_pseudonym]]
        else
          user.all_active_pseudonyms.each do |p|
            # populate reverse association
            p.user = user
            (account_to_pseudonyms_hash[p.account] ||= []) << p
          end
          @merge_opportunities << [user, account_to_pseudonyms_hash.map do |(account, pseudonyms)|
            pseudonyms.detect { |p| p.sis_user_id } || pseudonyms.sort_by(&:position).first
          end]
          @merge_opportunities.last.last.sort! { |a, b| Canvas::ICU.compare(a.account.name, b.account.name) }
        end
      end
      @merge_opportunities.sort_by! { |a| [a.first == @current_user ? CanvasSort::First : CanvasSort::Last, Canvas::ICU.collation_key(a.first.name)] }

      js_env :PASSWORD_POLICY => @domain_root_account.password_policy

      if @current_user && params[:confirm].present? && @merge_opportunities.find { |opp| opp.first == @current_user }
        @user.transaction do
          @current_user.transaction do
            cc.confirm
            @enrollment.accept if @enrollment
            UserMerge.from(@user).into(@current_user) if @user != @current_user
            # create a new pseudonym if necessary and possible
            pseudonym = @current_user.find_or_initialize_pseudonym_for_account(@root_account, @domain_root_account)
            pseudonym.save! if pseudonym && pseudonym.changed?
          end
        end
      elsif @current_user && @current_user != @user && @enrollment && @user.registered?

        if params[:transfer_enrollment].present?
          @user.transaction do
            @current_user.transaction do
              cc.active? || cc.confirm
              @enrollment.user = @current_user
              # accept will save it
              @enrollment.accept
              @user.touch
              @current_user.touch
            end
          end
        else
          # render
          return
        end
      elsif @user.registered?
        # render
        return unless @merge_opportunities.empty?
        failed = true
      elsif cc.active?
        # !user.registered? && cc.active? ?!?
        # This state really isn't supported; just error out
        failed = true
      else
        # Open registration and admin-created users are pre-registered, and have already claimed a CC, but haven't
        # set up a password yet
        @pseudonym = @root_account.pseudonyms.active.where(:password_auto_generated => true, :user_id => @user).first if @user.pre_registered? || @user.creation_pending?
        # Users implicitly created via course enrollment or account admin creation are creation pending, and don't have a pseudonym yet
        @pseudonym ||= @root_account.pseudonyms.build(:user => @user, :unique_id => cc.path) if @user.creation_pending?
        # We create the pseudonym with unique_id = cc.path, but if that unique_id is taken, just nil it out and make the user come
        # up with something new
        @pseudonym.unique_id = '' if @pseudonym && @pseudonym.new_record? && @root_account.pseudonyms.active.custom_find_by_unique_id(@pseudonym.unique_id)

        # Have to either have a pseudonym to register with, or be looking at merge opportunities
        return render :action => 'confirm_failed', :status => :bad_request if !@pseudonym && @merge_opportunities.empty?

        # User chose to continue with this cc/pseudonym/user combination on confirmation page
        if @pseudonym && params[:register]
          @user.require_acceptance_of_terms = require_terms?
          @user.attributes = params[:user]
          @pseudonym.attributes = params[:pseudonym]
          @pseudonym.communication_channel = cc

          # ensure the password gets validated, but don't require confirmation
          @pseudonym.require_password = true
          @pseudonym.password_confirmation = @pseudonym.password = params[:pseudonym][:password] if params[:pseudonym]

          valid = @pseudonym.valid?
          valid = @user.valid? && valid # don't want to short-circuit, since we are interested in the errors
          unless valid
            return render :json => {
                            :errors => {
                              :user => @user.errors.as_json[:errors],
                              :pseudonym => @pseudonym.errors.as_json[:errors]
                            }
                          }, :status => :bad_request
          end

          # They may have switched e-mail address when they logged in; create a CC if so
          if @pseudonym.unique_id != cc.path
            new_cc = @user.communication_channels.email.by_path(@pseudonym.unique_id).first
            new_cc ||= @user.communication_channels.build(:path => @pseudonym.unique_id)
            new_cc.user = @user
            new_cc.workflow_state = 'unconfirmed' if new_cc.retired?
            new_cc.send_confirmation!(@root_account) if new_cc.unconfirmed?
            new_cc.save! if new_cc.changed?
            @pseudonym.communication_channel = new_cc
          end
          @pseudonym.communication_channel.pseudonym = @pseudonym

          @user.save!
          @pseudonym.save!

          if cc.confirm
            @enrollment.accept if @enrollment
            reset_session_saving_keys(:return_to)
            @user.register

            # Login, since we're satisfied that this person is the right person.
            @pseudonym_session = PseudonymSession.new(@pseudonym, true)
            @pseudonym_session.save
          else
            failed = true
          end
        else
          @request = request
          return # render
        end
      end
    else
      failed = true
    end
    if failed
      respond_to do |format|
        format.html { render :action => "confirm_failed", :status => :bad_request }
        format.json { render :json => {}, :status => :bad_request }
      end
    else
      flash[:notice] = t 'notices.registration_confirmed', "Registration confirmed!"
      @current_user ||= @user # since dashboard_url may need it
      respond_to do |format|
        format.html { @enrollment ? redirect_to(course_url(@course)) : redirect_back_or_default(dashboard_url) }
        format.json { render :json => {:url => @enrollment ? course_url(@course) : dashboard_url} }
      end
    end
  end

  # params[:enrollment_id] is optional
  def re_send_confirmation
    @user = User.find(params[:user_id])
    @enrollment = params[:enrollment_id] && @user.enrollments.find(params[:enrollment_id])
    if @enrollment && (@enrollment.invited? || @enrollment.active?)
      @enrollment.re_send_confirmation!
    else
      @cc = params[:id].present? ? @user.communication_channels.find(params[:id]) : @user.communication_channel
      @cc.send_confirmation!(@domain_root_account)
    end
    render :json => {:re_sent => true}
  end

  # @API Delete a communication channel
  #
  # Delete an existing communication channel.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/5/communication_channels/3
  #          -H 'Authorization: Bearer <token>
  #          -X DELETE
  #
  # @returns CommunicationChannel
  def destroy
    @user = api_request? ? api_find(User, params[:user_id]) : @current_user
    if params[:type] && params[:address]
      @cc = @user.communication_channels.unretired.of_type(params[:type]).by_path(params[:address]).first
      raise ActiveRecord::RecordNotFound unless @cc
    else
      @cc = @user.communication_channels.unretired.find(params[:id])
    end

    return render_unauthorized_action unless has_api_permissions?
    if @cc.imported? && !@domain_root_account.edit_institution_email?
      return render_unauthorized_action
    end

    if @cc.destroy
      @user.touch
      if api_request?
        render :json => communication_channel_json(@cc, @current_user, session)
      else
        render :json => @cc.as_json
      end
    else
      render :json => @cc.errors, :status => :bad_request
    end
  end

  protected
  def has_api_permissions?
    @user == @current_user ||
      @user.grants_right?(@current_user, session, :manage_user_details)
  end

  def require_terms?
    @domain_root_account.require_acceptance_of_terms?(@user)
  end
  helper_method :require_terms?
end
