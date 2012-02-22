class FixZeroPointPassFailScores < ActiveRecord::Migration
  def self.up
    # a bug allowed a few submissions to have their grade set to pass/fail,
    # rather than complete/incomplete. pass/fail is allowed in the api, but was
    # supposed to be translated to complete/incomplete in the db.
    Submission.update_all({ :grade => 'complete' }, { :grade => 'pass' })
    Submission.update_all({ :grade => 'incomplete' }, { :grade => 'fail' })
    Submission.update_all({ :published_grade => 'complete' }, { :published_grade => 'pass' })
    Submission.update_all({ :published_grade => 'incomplete' }, { :published_grade => 'fail' })
  end

  def self.down
  end
end
