class ToursController < ApplicationController

  ##
  # Prevents the current version of the tour from displaying ever again to the
  # current user.

  def dismiss
    tour = find_tour_from_params
    dismissed = @current_user.preferences[:dismissed_tours] ||= {}
    dismissed[tour[:name]] = tour[:version]
    @current_user.save!
    render :json => true
  end

  ##
  # Dismisses the tour for this session only.

  def dismiss_session
    tour = find_tour_from_params
    (session[:dismissed_tours] ||= {})[tour[:name]] = tour[:version]
    render :json => true
  end

  private

  def find_tour_from_params
    name = params[:name].underscore.to_sym
    tour = Tour.tours[name]
  end

end

