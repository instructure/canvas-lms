class AdhocGroupController < ApplicationController

  before_filter :require_user
  include Common

  def render_button
    group = Group.find params[:group_id]
    if group.group_category.name != 'Ad-Hoc Groups' || group.leader_id != @current_user.id then
        render :status => :forbidden, :text => 'nope', :layout => false
        return false
    end
    @token = Base64.strict_encode64(cookies['_normandy_session'])
    render :layout => false
  end

end