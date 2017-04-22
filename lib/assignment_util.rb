module AssignmentUtil
  def self.due_date_required?(assignment)
    assignment.post_to_sis.present? && due_date_required_for_account?(assignment.context)
  end

  def self.due_date_ok?(assignment)
    !due_date_required?(assignment) ||
    assignment.due_at.present? ||
    assignment.grading_type == 'not_graded'
  end

  def self.assignment_name_length_required?(assignment)
    assignment.post_to_sis.present? && name_length_required_for_account?(assignment.context)
  end

  def self.assignment_max_name_length(context)
    account = Context.get_account(context)
    account.try(:sis_assignment_name_length_input).try(:[], :value).to_i
  end

  def self.post_to_sis_friendly_name(context)
    account = Context.get_account(context)
    account.try(:root_account).try(:settings).try(:[], :sis_name) || "SIS"
  end

  def self.name_length_required_for_account?(context)
    account = Context.get_account(context)
    account.try(:sis_syncing).try(:[], :value) &&
    account.try(:sis_assignment_name_length).try(:[], :value) &&
    sis_integration_settings_enabled?(context)
  end

  def self.due_date_required_for_account?(context)
    account = Context.get_account(context)
    account.try(:sis_syncing).try(:[], :value).present? &&
    account.try(:sis_require_assignment_due_date).try(:[], :value) &&
    sis_integration_settings_enabled?(context)
  end

  def self.sis_integration_settings_enabled?(context)
    account = Context.get_account(context)
    account.try(:feature_enabled?, 'new_sis_integrations').present?
  end
end
