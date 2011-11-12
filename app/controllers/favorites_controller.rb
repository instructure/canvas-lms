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

class FavoritesController < ApplicationController

  before_filter :check_defaults, :only => [:create, :destroy]
  after_filter :touch_user, :only => [:create, :destroy]

  def create
    favorite = @current_user.favorites.build(params[:favorite])

    response = { :params => params }

    if favorite.save
      response[:favorite] = favorite
    else
      response[:errors] = favorite.errors
    end

    render :json => response
  end

  def destroy
    if params[:id].match(/\A\d+\z/).nil?
      @current_user.favorites.by(params[:id]).destroy_all
      render :json => { :status => 'ok' }
      return
    end

    not_cool = @current_user.favorites.find(:first, :conditions => {
      :context_type => params[:context_type],
      :context_id => params[:id].to_i
    })

    if not_cool
      not_cool.destroy
      render :json => { :status => 'ok' }
      return
    end

    render :json => { :status => 'not found' }
  end

  protected

  # When we have other favorites, this needs to be modified to handle the other
  # types, rather than just courses.
  def check_defaults
    return unless @current_user.favorites.count == 0
    @current_user.menu_courses.each do |course|
      @current_user.favorites.create :context => course
    end
  end

  def touch_user
    # Menu is cached, clear it
    @current_user.touch
  end

end
