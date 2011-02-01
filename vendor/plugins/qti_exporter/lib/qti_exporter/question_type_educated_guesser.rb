module Qti
class QuestionTypeEducatedGuesser < AssessmentItemConverter
  def educatedly_guess_type
    begin
      create_doc
      if @doc.at_css('choiceinteraction')
        # multiple choice, matching, multiple response, true/false, and respondus algorithm question
        if @doc.css('choiceinteraction').length > 1
          # only matching has more than one choiceinteraction
          if @doc.at_css('outcomedeclaration[identifier^=RESPONDUS]')
            return ['choiceinteraction', 'respondus_matching']
          else
            return ['choiceinteraction', 'matching']
          end
        end
        return ['choiceinteraction', nil]
      end
      if @doc.at_css('associateinteraction')
        return ['associateinteraction', 'matching']
      end
      if@doc.at_css('extendedtextinteraction')
        return ['extendedtextinteraction', nil]
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