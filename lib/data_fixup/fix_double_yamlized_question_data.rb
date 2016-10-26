module DataFixup::FixDoubleYamlizedQuestionData
  QUERY = "left(question_data, 11) LIKE '--- |\n  ---'"
  def self.run
    AssessmentQuestion.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
      AssessmentQuestion.where(:id => min_id..max_id).where(QUERY).find_each do |assessment_question|
        assessment_question.question_data = YAML.load(assessment_question.question_data)
        assessment_question.save!
      end
    end
  end
end
