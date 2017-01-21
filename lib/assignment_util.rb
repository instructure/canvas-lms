module AssignmentUtil
  def self.due_date_required?(assignment)
    assignment.post_to_sis.present? &&
    assignment.try(:context).try(:account).try(:sis_require_assignment_due_date).try(:[], :value) &&
    assignment.try(:context).try(:account).try(:feature_enabled?, 'new_sis_integrations').present?
  end

  def self.due_date_ok?(assignment)
    !due_date_required?(assignment) || assignment.due_at.present?
  end
end

