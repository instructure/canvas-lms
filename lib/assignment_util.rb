module AssignmentUtil
  def self.due_date_required?(assignment)
    assignment.post_to_sis.present? && due_date_required_for_account?(assignment)
  end

  def self.due_date_ok?(assignment)
    !due_date_required?(assignment) || assignment.due_at.present?
  end

  def self.assignment_name_length_required?(assignment)
    assignment.post_to_sis.present? && name_length_required_for_account?(assignment)
  end

  def self.assignment_max_name_length(assignment)
    assignment.try(:context).try(:account).try(:sis_assignment_name_length_input).try(:[], :value).to_i
  end

  def self.post_to_sis_friendly_name(assignment)
    assignment.try(:context).try(:account).try(:root_account).try(:settings).try(:[], :sis_name) || "SIS"
  end

  def self.name_length_required_for_account?(assignment)
    assignment.try(:context).try(:account).try(:sis_syncing).try(:[], :value) &&
    assignment.try(:context).try(:account).try(:sis_assignment_name_length).try(:[], :value) &&
    assignment.try(:context).try(:account).try(:feature_enabled?, 'new_sis_integrations').present?
  end

  def self.due_date_required_for_account?(assignment)
    assignment.try(:context).try(:account).try(:sis_syncing).try(:[], :value).present? &&
    assignment.try(:context).try(:account).try(:sis_require_assignment_due_date).try(:[], :value) &&
    assignment.try(:context).try(:account).try(:feature_enabled?, 'new_sis_integrations').present?
  end
end
