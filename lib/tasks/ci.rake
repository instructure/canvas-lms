# frozen_string_literal: true

namespace :ci do
  desc "set up test shards if they don't already exist"
  task prepare_test_shards: :environment do
    raise "need to set RAILS_ENV=test" unless Rails.env.test?

    Switchman::TestHelper.recreate_persistent_test_shards
  end

  task :disable_structure_dump do
    Rake::Task["db:structure:dump"].instance_variable_set(:@already_invoked, true)
  end

  task reset_database: :environment do
    raise "need to set RAILS_ENV=test" unless Rails.env.test?

    require_relative "../../spec/support/test_database_utils"
    TestDatabaseUtils.reset_database!
  end

  task discard_past_quiz_event_partitions: :environment do
    Setting.set("quiz_events_partitions_keep_months", 0)
  end
end
