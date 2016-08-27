class EquationImagesController < ApplicationController

  # Facade to codecogs API for gif generation or microservice MathMan for svg
  def show
    # At the moment, the latex string is stored in the db double escaped. By
    # the time the value gets here as `params[:id]` it has been unescaped once.
    # This is nearly how we want it to pass it on to the next service, except
    # `+` signs are in tact. Since normally the `+` signifies a space and we
    # want the `+` signs for real, we need to encode them.
    @latex = params[:id].gsub('+', '%2B')
    redirect_to url
  end

  private
  def url
    if MathMan.use_for_svg?
      MathMan.url_for(latex: @latex, target: :svg)
    else
      Setting.get('equation_image_url', 'http://latex.codecogs.com/gif.latex?') + @latex
    end
  end
end
