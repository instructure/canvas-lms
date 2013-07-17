class QuizQuestion::FileUploadAnswer < QuizQuestion::UserAnswer 
  def initialize(question_id,points_possible,answer_data)
    super(question_id, points_possible, answer_data)
    self.answer_details = {:attachment_ids => attachment_ids }
  end

  def attachment_ids
    return nil unless data = @answer_data["question_#{question_id}".to_sym]
    ids = data.select(&:present?)
    ids.present? ? ids : nil
  end
end

