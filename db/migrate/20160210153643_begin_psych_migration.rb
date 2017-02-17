class BeginPsychMigration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def runnable?
    Shard.current.default?
  end

  def up
    if User.exists? # don't raise for a fresh install
      raise "WARNING:\n
        This migration needs to be run with the release/2016-04-23 version of canvas-lms to
        change all yaml columns in the database to a Psych compatible format.\n"
    end
  end

  def down
  end
end
