require_relative '../sharding_spec_helper'

describe DataFixup::PsychMigration do
  before :each do
    skip("Rails 4.0 specific") unless CANVAS_RAILS4_0
  end

  let(:bad_yaml) { "--- \nsadness: \"\\xF0\\x9F\\x98\\x82\"\n"}
  let(:fixed_yaml) { "---\nsadness: \"\\U0001F602\"\n#{Syckness::TAG}" }

  it "should translate yaml in serialized columns into a psych compatible state" do
    user
    User.where(:id => @user).update_all(:preferences => bad_yaml)

    DataFixup::PsychMigration.run

    yaml = User.where(:id => @user).pluck("preferences AS p1").first
    expect(yaml).to eq fixed_yaml
  end

  it "should fix all the columns" do
    course

    Course.where(:id => @course).update_all(:tab_configuration => bad_yaml, :settings => bad_yaml)

    DataFixup::PsychMigration.run

    yamls = Course.where(:id => @course).pluck("tab_configuration AS c1, settings AS c2").first
    expect(yamls).to eq [fixed_yaml, fixed_yaml]
  end

  it "should queue a job with a progress model on production" do
    user
    User.where(:id => @user).update_all(:preferences => bad_yaml)

    DataFixup::PsychMigration.stubs(:run_immediately?).returns(false)
    DataFixup::PsychMigration.run

    expect(User.where(:id => @user).pluck("preferences AS p1").first).to eq bad_yaml # should not have run yet

    progresses = Progress.where(:tag => 'psych_migration').to_a
    expect(progresses.map{|prog| prog.results[:model_name]}).to match_array(DataFixup::PsychMigration.columns_hash.keys.map(&:name))

    progress = progresses.detect{|prog| prog.results[:model_name] == "User"}
    expect(progress).to be_queued

    run_jobs

    progresses.each do |prog|
      prog.reload
      expect(prog).to be_completed
    end

    expect(progress.results[:successful]).to be_truthy
    expect(progress.results[:changed_count]).to eq 1

    yaml = User.where(:id => @user).pluck("preferences AS p1").first
    expect(yaml).to eq fixed_yaml
  end

  it "should split into multiple jobs with id ranges if needed" do
    skip "needs AR jobs" unless Delayed::Job == Delayed::Backend::ActiveRecord::Job

    users = []
    8.times do
      user
      users << @user
    end
    User.where(:id => users).update_all(:preferences => bad_yaml)

    DataFixup::PsychMigration.stubs(:run_immediately?).returns(false)
    DataFixup::PsychMigration.stubs(:range_size).returns(3)
    DataFixup::PsychMigration.run

    user_progresses = Progress.where(:tag => 'psych_migration').to_a.select{|prog| prog.results[:model_name] == "User"}
    expect(user_progresses.count).to eq 3
    ranges = user_progresses.map{|prog| [prog[:results][:start_at], prog[:results][:end_at]]}
    expect(ranges).to match_array [
      [users[0].id, users[2].id],
      [users[3].id, users[5].id],
      [users[6].id, nil]
    ]

    prog = user_progresses.detect{|prog| prog[:results][:start_at] == users[3].id}
    job = Delayed::Job.where("handler LIKE ?", "%ActiveRecord:Progress #{prog.id}\n%").first

    run_job(job)
    prog.reload
    expect(prog).to be_completed
    expect(prog.results[:changed_count]).to eq 3

    fixed_users = [users[3], users[4], users[5]]
    expect(User.where(:id => fixed_users).pluck("preferences AS p1")).to eq ([fixed_yaml] * 3)
    expect(User.where.not(:id => fixed_users).pluck("preferences AS p1")).to eq ([bad_yaml] * 5) # should not have run everywhere else

    run_jobs

    expect(User.where(:id => users).pluck("preferences AS p1")).to eq ([fixed_yaml] * 8)
  end

  context "cross-shard" do
    specs_require_sharding

    it "should deserialize job data on the correct shard" do
      skip "needs job shard id" unless Delayed::Job == Delayed::Backend::ActiveRecord::Job && Delayed::Job.column_names.include?('shard_id')

      @utf_arg = "\xF0\x9F\x98\x82"

      @shard1.stubs(:delayed_jobs_shard).returns(Shard.default)
      @shard1.activate do
        user
        @user.send_later(:save, @utf_arg)
      end

      job = Delayed::Job.where("handler LIKE ?", "%ActiveRecord:User #{@user.local_id}\n%").first
      expect(job.shard_id).to eq @shard1.id
      fixed = job.handler
      broken = fixed.sub("\"\\U0001F602\"", "\"\\xF0\\x9F\\x98\\x82\"").sub(Syckness::TAG, "") # reconvert back into syck format for the spec
      Delayed::Job.where(:id => job).update_all(:handler => broken)

      expect(job.reload.handler).to eq broken

      DataFixup::PsychMigration.run

      expect(job.reload.handler).to eq fixed
    end
  end
end