class AccountNotificationsController < ApplicationController
  before_filter :require_account_admin
  
  def create
    @notification = AccountNotification.new(params[:account_notification])
    @notification.account = @account
    @notification.user = @current_user
    respond_to do |format|
      if @notification.save
        flash[:notice] = t(:announcement_created_notice, "Announcement successfully created")
        format.html { redirect_to account_settings_path(@account, :anchor => 'tab-announcements') }
        format.json { render :json => @notification }
      else
        flash[:error] = t(:announcement_creation_failed_notice, "Announcement creation failed")
        format.html { redirect_to account_settings_path(@account, :anchor => 'tab-announcements') }
        format.json { render :json => @notification.errors, :status => :bad_request }
      end
    end
  end
  
  def destroy
    @notification = @account.announcements.find(params[:id])
    @notification.destroy
    respond_to do |format|
      flash[:message] = t(:announcement_deleted_notice, "Announcement successfully deleted")
      format.html { redirect_to account_settings_path(@account, :anchor => 'tab-announcements') }
      format.json { render :json => @notification }
    end
  end
  
  protected
  def require_account_admin
    get_context
    if !@account || @account.parent_account_id
      flash[:notice] = t(:permission_denied_notice, "You cannot create announcements for that account")
      redirect_to account_settings_path(params[:account_id])
      return false
    end
    return false unless authorized_action(@account, @current_user, :manage_alerts)
  end
end
