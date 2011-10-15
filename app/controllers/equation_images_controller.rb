class EquationImagesController < ApplicationController

  # Facade to codecogs API so we retain control
  def show
    redirect_to 'http://latex.codecogs.com/gif.latex?' + params[:id]
  end

end