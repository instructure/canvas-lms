class QuizRegradeRun < ActiveRecord::Base
  belongs_to :quiz_regrade
  attr_accessible :quiz_regrade_id, :started_at, :finished_at
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
    policy.whenever do |run|
      old,new = run.changes['finished_at']
      !!(new && old.nil?)
    end
  end

  delegate :teachers, :quiz, to: :quiz_regrade
end
