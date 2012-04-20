class EquationImagesController < ApplicationController

  # Facade to codecogs API so we retain control
  def show
    # TODO: escape id here, and stop double escaping it in
    # public/javascripts/tinymce/jscripts/tiny_mce/plugins/instructure_equation/editor_plugin.js
    # this will require a corresponding data migration to fix
    redirect_to 'http://latex.codecogs.com/gif.latex?' + params[:id]
  end

end
