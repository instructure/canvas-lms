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

class CommunicationChannelsController < ApplicationController
  before_filter :require_user, :only => [:create, :destroy]
  
  def create
    if params[:build_pseudonym]
      params[:pseudonym][:account] = @domain_root_account
      @pseudonym = @current_user.pseudonyms.build(params[:pseudonym])
      @pseudonym.generate_temporary_password
      return render :json => @pseudonym.errors.to_json, :status => :bad_request unless @pseudonym.valid?
    end
    @cc = @current_user.communication_channels.find_or_initialize_by_path_and_path_type(params[:pseudonym][:unique_id], params[:path_type])
    if (!@cc.new_record? && !@cc.retired?)
      @cc.errors.add(:path, "unique!")
      return render :json => @cc.errors.to_json, :status => :bad_request
    end

    @cc.user = @current_user
    @cc.workflow_state = 'unconfirmed'
    @cc.build_pseudonym_on_confirm = params[:build_pseudonym] == '1'
    if @cc.save
      @cc.send_confirmation!
      flash[:notice] = "Contact method registered!"
      render :json => @cc.to_json(:only => [:id, :user_id, :path, :path_type])
    else
      render :json => @cc.errors.to_json, :status => :bad_request
    end
  end

  def confirm
    nonce = params[:nonce]
    cc = CommunicationChannel.unretired.find_by_confirmation_code(nonce)
    @enrollment = Enrollment.find_by_uuid_and_workflow_state(params[:enrollment], 'invited') if params[:enrollment]
    @course = @enrollment && @enrollment.course
    @headers = false
    @root_account = @course.root_account if @course
    @root_account ||= @domain_root_account
    if cc
      @communication_channel = cc
      @user = cc.user

      # load merge opportunities
      other_ccs = CommunicationChannel.find(:all, :conditions => ["path=? AND path_type=? AND user_id<>? AND workflow_state='active'", cc.path, cc.path_type, @user.id])
      CommunicationChannel.send(:preload_associations, other_ccs, :user)
      @merge_opportunities = other_ccs.map(&:user).uniq
      @merge_opportunities.reject! { |u| u == @current_user }
      User.send(:preload_associations, @merge_opportunities, { :pseudonyms => :account })
      @merge_opportunities.reject! { |u| u.pseudonyms.all? { |p| p.deleted? } }

      if @current_user && params[:merge] == 'self'
        cc.confirm
        @enrollment.accept if @enrollment
        @user.move_to_user(@current_user)
      elsif @current_user && @enrollment && params[:transfer_enrollment]
        cc.active? || cc.confirm
        @enrollment.user = @current_user
        # accept will save it
        @enrollment.accept
      elsif @user.registered?
        unless @current_user
          session[:return_to] = request.url
          return redirect_to login_url
        end
        # Present merge opportunities to a registered user
        return if (!@merge_opportunities.empty? || @current_user != @user) && !params[:confirm]

        # Auto-confirm a CC that has been added to a registered account, and no merge opportunities
        # OR the user clicked "confirm" on confirmation page
        failed = true unless cc.active? || cc.confirm
        @enrollment.accept if !failed && @enrollment
      elsif cc.active?
        # !user.registered? && cc.active? ?!?
        # This state really isn't supported; just error out
        failed = true
      else
        # Open registration and admin-created users are pre-registered, and have already claimed a CC, but haven't
        # set up a password yet
        @pseudonym = @user.pseudonyms.active.find(:first, :conditions => {:password_auto_generated => true, :account_id => @root_account.id} ) if @user.pre_registered? || @user.creation_pending?
        # Users implicitly created via course enrollment or account admin creation are creation pending, and don't have a pseudonym yet
        @pseudonym ||= @user.pseudonyms.build(:account => @root_account, :unique_id => cc.path) if @user.creation_pending?
        # We create the pseudonym with unique_id = cc.path, but if that unique_id is taken, just nil it out and make the user come
        # up with something new
        @pseudonym.unique_id = '' if @pseudonym && @pseudonym.new_record? && @root_account.pseudonyms.active.find_by_unique_id(@pseudonym.unique_id)

        # Have to either have a pseudonym to register with, or be registered, or be looking at merge opportunities
        return render :action => 'confirm_failed', :status => :bad_request unless @user.registered? || @pseudonym || !@merge_opportunities.empty? || (@current_user && @current_user != @user)

        # User chose to continue with this cc/pseudonym/user combination on confirmation page
        if params[:register]
          @user.name = params[:user].try(:[], :name) || @user.name
          @user.name = @pseudonym.unique_id if !@user.name || @user.name.empty?
          @user.time_zone = params[:user].try(:[], :time_zone) || @user.time_zone
          @user.short_name = params[:user].try(:[], :short_name) || @user.short_name
          @user.subscribe_to_emails = params[:user].try(:[], :subscribe_to_emails) || @user.subscribe_to_emails
          @pseudonym.unique_id = params[:pseudonym].try(:[], :unique_id) || @pseudonym.unique_id
          if params[:pseudonym].try(:[], :password)
            @pseudonym.password = params[:pseudonym][:password]
            @pseudonym.password_confirmation = params[:pseudonym][:password_confirmation]
          end
          @pseudonym.communication_channel = cc

          # trick pseudonym into validating the e-mail address
          @pseudonym.account = nil
          unless @pseudonym.valid?
            return
          end
          @pseudonym.account = @root_account

          return unless @pseudonym.valid?

          # They may have switched e-mail address when they logged in; create a CC if so
          if @pseudonym.unique_id != cc.path
            new_cc = @user.communication_channels.find_or_initialize_by_path_and_path_type(@pseudonym.unique_id, 'email')
            new_cc.user = @user
            new_cc.workflow_state = 'unconfirmed' if new_cc.retired?
            new_cc.send_confirmation! if new_cc.unconfirmed?
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
          return # render
        end
      end
    else
      failed = true
    end
    if failed
      respond_to do |format|
        format.html { render :action => "confirm_failed", :status => :bad_request }
        format.json { render :json => {}.to_json, :status => :bad_request }
      end
    else
      flash[:notice] = t 'notices.registration_confirmed', "Registration confirmed!"
      respond_to do |format|
        format.html { @enrollment ? redirect_to(course_url(@course)) : redirect_back_or_default(dashboard_url) }
        format.json { render :json => cc.to_json(:except => [:confirmation_code] ) }
      end
    end
  end

  def re_send_confirmation
    @user = User.find(params[:user_id])
    @enrollment = params[:enrollment_id] && @user.enrollments.find(params[:enrollment_id])
    if @enrollment && (@enrollment.invited? || @enrollment.active?)
      @enrollment.re_send_confirmation!
    else
      @cc = @user.communication_channels.find(params[:id])
      @cc.send_confirmation!
    end
    render :json => {:re_sent => true}
  end

  def destroy
    @cc = @current_user.communication_channels.find_by_id(params[:id]) if params[:id]
    if !@cc || @cc.destroy
      render :json => @cc.to_json
    else
      render :json => @cc.errors.to_json, :status => :bad_request
    end
  end
  
end
