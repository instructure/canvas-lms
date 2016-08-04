class ModeratedGrading::NullProvisionalGrade
  def initialize(submission, scorer_id, final)
    @submission = submission
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
      'graded_anonymously' => nil,
      'final' => @final,
      'grade_matches_current_submission' => true
    }
  end

  def submission_comments
    @submission.submission_comments
  end
end
