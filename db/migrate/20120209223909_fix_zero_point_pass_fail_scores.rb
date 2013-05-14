class FixZeroPointPassFailScores < ActiveRecord::Migration
  def self.up
    # a bug allowed a few submissions to have their grade set to pass/fail,
    # rather than complete/incomplete. pass/fail is allowed in the api, but was
    # supposed to be translated to complete/incomplete in the db.
    Submission.where(:grade => 'pass').update_all(:grade => 'complete')
    Submission.where(:grade => 'fail').update_all(:grade => 'incomplete')
    Submission.where(:published_grade => 'pass').update_all(:published_grade => 'complete')
    Submission.where(:published_grade => 'fail').update_all(:published_grade => 'incomplete')
  end

  def self.down
  end
end
