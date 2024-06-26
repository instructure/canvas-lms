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
  require "pragmatic_segmenter"

  before_action :require_context, only: :translate
  before_action :require_user
  before_action :require_inbox_translation, only: %i[translate_paragraph translate_message]

  # Skip the authenticity token as this is an API endpoint.
  skip_before_action :verify_authenticity_token, only: [:translate]

  def translate
    # Don't allow users that can't access, or if translation is not available
    return render_unauthorized_action unless Translation.available?(@context, :translation) && @context.grants_right?(@current_user, session, :read)

    # This action is used for dicussions
    InstStatsd::Statsd.increment("translation.discussions")

    # Call the translation service.
    render json: { translated_text: Translation.create(src_lang: required_params[:src_lang],
                                                       tgt_lang: required_params[:tgt_lang],
                                                       text: required_params[:text]) }
  end

  ##
  # Translate the paragraph given to us, split the paragraph into sentences and build up the response
  # incrementally
  #
  def translate_paragraph
    # Split into paragraphs.
    text = []
    required_params[:text].split("\n").map do |paragraph|
      # Translate the paragraph
      passage = []
      PragmaticSegmenter::Segmenter.new(text: paragraph, language: required_params[:src_lang]).segment.each do |segment|
        trans = Translation.create(src_lang: required_params[:src_lang],
                                   tgt_lang: required_params[:tgt_lang],
                                   text: segment)
        passage.append(trans)
      end
      text.append(passage.join)
    end

    # This action is used for inbox_compose
    InstStatsd::Statsd.increment("translation.inbox_compose")

    render json: { translated_text: text.join("\n") }
  end

  def translate_message
    # First, check to see if the language that we've been given matches the language of the user.
    if Translation.language_matches_user_locale?(@current_user, required_params[:text])
      return render json: { status: "language_matches" }
    end

    # This action is used for inbox inbound messages
    InstStatsd::Statsd.increment("translation.inbox")

    # Translate the message
    render json: { translated_text: Translation.translate_message(text: required_params[:text], user: @current_user) }
  end

  private

  def required_params
    params.require(:inputs).permit(:src_lang, :tgt_lang, :text)
  end

  def require_inbox_translation
    render_unauthorized_action unless Translation.available?(@domain_root_account, :translate_inbox_messages)
  end
end
