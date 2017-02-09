module Api::V1::MasterTemplate
  def master_template_json(template, user, session, opts={})
    api_json(template, user, session, :only => %w(id course_id), :methods => %w{last_export_completed_at})
  end
end
