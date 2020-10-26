# frozen_string_literal: true

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

module Qti
class QuestionTypeEducatedGuesser < AssessmentItemConverter
  def educatedly_guess_type
    begin
      create_doc
      if @doc.at_css('choiceInteraction')
        # multiple choice, matching, multiple response, true/false, and respondus algorithm question
        if @doc.css('choiceInteraction').length > 1
          # only matching has more than one choiceInteraction
          if @doc.at_css('outcomeDeclaration[identifier^=RESPONDUS]')
            return ['choiceInteraction', 'respondus_matching']
          else
            return ['choiceInteraction', 'matching']
          end
        end
        return ['choiceInteraction', nil]
      end
      if @doc.at_css('associateInteraction')
        return ['associateinteraction', 'matching']
      end
      if @doc.at_css('extendedTextInteraction')
        return ['extendedTextInteraction', nil]
      end
      if @doc.at_css('textEntryInteraction')
        return ['textEntryInteraction', 'text_entry_interaction']
      end
      if @doc.at_css('matchInteraction')
        return ['matchInteraction', 'matching']
      end
      if @doc.at_css('itemBody inlineChoiceInteraction')
        return ['multiple_dropdowns_question', 'inline_choice']
      end
    rescue => e
      message = "There was an error educatedly guessing the type for an assessment question"
      @question[:qti_error] = "#{message} - #{e}"
      @question[:question_type] = "Error"
      @log.error "#{e}: #{e.backtrace}"
    end
    [nil,nil]
  end
end
end
