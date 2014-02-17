class EquationImagesController < ApplicationController

  # Facade to codecogs API so we retain control
  def show
    # TODO: escape id here, and stop double escaping it in
    # public/javascripts/tinymce/jscripts/tiny_mce/plugins/instructure_equation/editor_plugin.js
    # this will require a corresponding data migration to fix
    base_url = Setting.get('codecogs.equation_image_link', 'http://latex.codecogs.com/gif.latex')
    redirect_to base_url + '?' + params[:id]
  end

end
