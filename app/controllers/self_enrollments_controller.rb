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
  before_filter :infer_signup_info, :only => [:new, :create]
  before_filter :require_user, :only => :create

  include Api::V1::Course

  def new
    js_env :USER => {:MIN_AGE => @course.self_enrollment_min_age || User.self_enrollment_min_age}
  end

  def create
    @current_user.validation_root_account = @domain_root_account
    @current_user.require_self_enrollment_code = true
    @current_user.self_enrollment_code = params[:self_enrollment_code]
    if @current_user.save
      render :json => course_json(@current_user.self_enrollment_course, @current_user, session, [], nil)
    else
      render :json => {:user => @current_user.errors.as_json[:errors]}, :status => :bad_request
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
