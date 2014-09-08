class Quizzes::QuizRegradeRun < ActiveRecord::Base
  self.table_name = 'quiz_regrade_runs'

  belongs_to :quiz_regrade, class_name: 'Quizzes::QuizRegrade'
  attr_accessible :quiz_regrade_id, :started_at, :finished_at

  EXPORTABLE_ATTRIBUTES = [:id, :quiz_regrade_id, :started_at, :finished_at, :created_at, :updated_at]
  EXPORTABLE_ASSOCIATIONS = [:quiz_regrade]
  validates_presence_of :quiz_regrade_id

  def self.perform(regrade)
    run = create!(quiz_regrade_id: regrade.id, started_at: Time.now)
    yield
    run.finished_at = Time.now
    run.save!
  end

  has_a_broadcast_policy
  set_broadcast_policy do |policy|
    policy.dispatch :quiz_regrade_finished
    policy.to { teachers }
    policy.whenever { |run| run.send_messages? }
  end

  def send_messages?
    old, new = changes['finished_at']
    !!(new && old.nil?) && Quizzes::QuizRegradeRun.where(quiz_regrade_id: quiz_regrade).count == 1
  end

  delegate :teachers, :quiz, to: :quiz_regrade
end
