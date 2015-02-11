#
# Copyright (C) 2012 Instructure, Inc.
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

class SelfEnrollmentsController < ApplicationController
  before_filter :infer_signup_info, :only => [:new]

  include Api::V1::Course

  def new
    @domain_root_account.reload
    js_env :PASSWORD_POLICY => @domain_root_account.password_policy
    @login_label_name = t("email")

    login_handle_name = @domain_root_account.login_handle_name
    @login_label_name = login_handle_name if login_handle_name

    if !@current_user && delegated_authentication_url?
      store_location
      flash[:notice] = t('notices.login_required', "Please log in to join this course.")
      return redirect_to login_url
    end
  end

  private

  def infer_signup_info
    @embeddable = true
    @course = @domain_root_account.self_enrollment_course_for(params[:self_enrollment_code])

    # TODO: have a join code field in new.html.erb if none is provided in the url
    raise ActiveRecord::RecordNotFound unless @course
  end
end
