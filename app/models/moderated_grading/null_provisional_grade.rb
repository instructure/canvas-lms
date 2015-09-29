class ModeratedGrading::NullProvisionalGrade
  def initialize(scorer_id, final)
    @scorer_id = scorer_id
    @final = final
  end

  def grade_attributes
    {
      'provisional_grade_id' => nil,
      'grade' => nil,
      'score' => nil,
      'graded_at' => nil,
      'scorer_id' => @scorer_id,
      'final' => @final,
      'grade_matches_current_submission' => true
    }
  end

  def submission_comments
    SubmissionComment.none
  end
end
