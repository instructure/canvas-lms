#
# Copyright (C) 2011 - present Instructure, Inc.
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
