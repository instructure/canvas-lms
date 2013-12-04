module QuizQuestion::AnswerParsers
  class Calculated < AnswerParser
    def parse(question)
      question[:formulas] = format_formulas(question[:formulas])
      question[:variables] = format_variables(question[:variables])

      @answers.map! do |answer_group, answer|
        answer_params = {:weight => 100, :variables => []}
        answer_params[:answer] = answer[:answer_text].to_f

        variables = hash_to_array(answer[:variables])
        variables.each do |variable|
          variable = QuizQuestion::RawFields.new(variable)
          answer_params[:variables] << {
            :name => variable.fetch_with_enforced_length(:name),
            :value => variable.fetch(:value).to_f
          }
        end

         answer = QuizQuestion::AnswerGroup::Answer.new(answer_params)
         answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
         answer
      end

      question.answers = @answers
      question
    end

    private
    def format_formulas(formulas)
      formulas = hash_to_array(formulas)
      formulas.map do |formula|
        formula = QuizQuestion::RawFields.new({formula: trim_length(formula)})
        { formula: formula.fetch_with_enforced_length(:formula) }
      end
    end

    def format_variables(variables)
      hash_to_array(variables).map do |variable|
        variable = QuizQuestion::RawFields.new(variable.merge({name: trim_length(variable[:name])}))
        {
          name: variable.fetch_with_enforced_length(:name),
          min: variable.fetch(:min).to_f,
          max: variable.fetch(:max).to_f,
          scale: variable.fetch(:scale).to_i
        }
      end
    end

    def trim_length(field)
      field[0..1024]
    end

    def hash_to_array(obj)
      if obj.respond_to?(:values)
        obj.values
      else
        obj || []
      end
    end

    def trim_padding(n)
      n.to_s[9..-1].to_i
    end

  end
end
