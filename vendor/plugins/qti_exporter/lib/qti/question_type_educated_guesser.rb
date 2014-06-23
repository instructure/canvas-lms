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
    rescue => e
      message = "There was an error educatedly guessing the type for an assessment question"
      @question[:qti_error] = "#{message} - #{e.to_s}"
      @question[:question_type] = "Error"
      @log.error "#{e.to_s}: #{e.backtrace}"
    end
    [nil,nil]
  end
end
end