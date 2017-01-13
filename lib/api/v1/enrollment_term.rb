module Api::V1::EnrollmentTerm
  include Api::V1::Json

  def enrollment_term_json(enrollment_term, user, session, enrollments=[], includes=[])
    api_json(enrollment_term, user, session, :only => %w(id name start_at end_at workflow_state grading_period_group_id created_at)).tap do |hash|
      hash['sis_term_id'] = enrollment_term.sis_source_id if enrollment_term.root_account.grants_any_right?(user, :read_sis, :manage_sis)
      hash['start_at'], hash['end_at'] = enrollment_term.overridden_term_dates(enrollments) if enrollments.present?
      hash['overrides'] = date_overrides_json(enrollment_term) if includes.include?('overrides')
    end
  end

  def enrollment_terms_json(enrollment_terms, user, session, enrollments=[], includes=[])
    if includes.include?('overrides')
      ActiveRecord::Associations::Preloader.new.preload(enrollment_terms, :enrollment_dates_overrides)
    end
    enrollment_terms.map{ |t| enrollment_term_json(t, user, session, enrollments, includes) }
  end

  protected def date_overrides_json(term)
    term.enrollment_dates_overrides.select { |o| o.start_at || o.end_at }.inject({}) do |json, override|
      json[override.enrollment_type] = override.attributes.slice('start_at', 'end_at')
      json
    end
  end
end
