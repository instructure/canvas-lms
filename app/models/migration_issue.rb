class MigrationIssue < ActiveRecord::Base
  include Workflow

  attr_accessible :issue_type, :description, :fix_issue_html_url, :error_message, :error_report_id, :workflow_state

  belongs_to :content_migration
  belongs_to :error_report

  validates_presence_of :issue_type, :content_migration_id, :workflow_state
  validates_inclusion_of :issue_type, :in => %w( todo warning error )

  workflow do
    state :active do
      event :resolve, :transitions_to => :resolved
    end

    state :resolved
  end

  scope :active, -> { where(:workflow_state => 'active') }
  scope :by_created_at, -> { order(:created_at) }

  set_policy do
    given { |user| Account.site_admin.grants_right?(user, :view_error_reports) }
    can :read_errors
  end

end
