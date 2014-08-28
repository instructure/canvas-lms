module Api::V1::GradingStandard
  include Api::V1::Json

  def grading_standard_json(grading_standard, user, session)
    api_json(grading_standard, user, session, :only => %w(id title context_type context_id)).tap do |hash|
      hash[:grading_scheme] = grading_standard['data'].map{|a| {name:a[0], value:a[1]}}
    end
  end

end