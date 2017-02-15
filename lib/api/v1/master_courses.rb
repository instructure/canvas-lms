module Api::V1::MasterCourses
  def master_template_json(template, user, session, opts={})
    api_json(template, user, session, :only => %w(id course_id), :methods => %w{last_export_completed_at})
  end

  def master_migration_json(migration, user, session, opts={})
    hash = api_json(migration, user, session,
      :only => %w(id user_id workflow_state created_at exports_started_at imports_queued_at imports_completed_at))
    hash['template_id'] = migration.master_template_id
    hash
  end
end
