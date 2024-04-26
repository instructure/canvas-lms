# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

class TranslationController < ApplicationController
  before_action :require_context, only: :translate
  before_action :require_user

  # Skip the authenticity token as this is an API endpoint.
  skip_before_action :verify_authenticity_token, only: [:translate]

  def translate
    # Don't allow users that can't access, or if translation is not available
    return render_unauthorized_action unless Translation.available?(@context) && @context.grants_right?(@current_user, session, :read)

    # Call the translation service.
    render json: { translated_text: Translation.create(src_lang: required_params[:src_lang],
                                                       tgt_lang: required_params[:tgt_lang],
                                                       text: required_params[:text]) }
  end

  private

  def required_params
    params.require(:inputs).permit(:src_lang, :tgt_lang, :text)
  end
end
