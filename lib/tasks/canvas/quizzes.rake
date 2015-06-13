namespace :canvas do
  namespace :quizzes do
    desc 'Generate events from snapshots for submissions to a quiz.'
    task :generate_events_from_snapshots, [ :quiz_id ] => :environment do |t, args|
      quiz_id = Array(args[:quiz_id])
      quiz_submission_ids = Quizzes::QuizSubmission.where(quiz_id: quiz_id)

      model = Quizzes::QuizSubmissionEvent
      parser = Quizzes::LogAuditing::SnapshotScraper.new

      model.transaction do
        snapshots = Quizzes::QuizSubmissionSnapshot.
          where(quiz_submission_id: quiz_submission_ids).
          includes(:quiz_submission).
          reject { |snapshot| snapshot.quiz_submission.nil? }

        puts "Generating #{snapshots.length} events..."
        parser.events_from_snapshots(snapshots).map(&:save!)
        puts "#{events.length} events were generated."
      end # model.transaction
    end # task :generate_events_from_snapshots

    desc "Generate a JSON dump of events in a single quiz submission."
    task :dump_events, [ :quiz_submission_id, :out ] => :environment do |t, args|
      require 'json'
      require 'benchmark'

      unless out_path = args[:out]
        raise "Missing path to output file."
      end

      events = nil

      puts '*' * 80
      puts '-' * 80
      puts "Extracting events from snapshots of quiz submission #{args[:quiz_submission_id]}..."

      elapsed = Benchmark.realtime do
        parser = Quizzes::LogAuditing::SnapshotScraper.new
        quiz_submission = Quizzes::QuizSubmission.find(args[:quiz_submission_id])
        snapshots = Quizzes::QuizSubmissionSnapshot.where({
          quiz_submission_id: quiz_submission.id,
          attempt: quiz_submission.attempt
        })

        events = parser.events_from_snapshots(snapshots)
      end

      puts "\tNumber of events extracted: #{events.length}"
      puts "\tExtraction finished in #{(elapsed * 1000).round} milliseconds."
      puts "Creating a JSON dump of the snapshot events to #{out_path}..."

      File.write(out_path, events.to_json(include_root: false))

      puts "\tBlob size: #{File.size(out_path)}b (#{(File.size(out_path) / 1000).round}K)"
      puts "\tBlob signature: #{Digest::MD5.hexdigest(File.read(out_path))}"
      puts "Done. Bye!"
      puts '*' * 80
    end

    desc 'Create partition tables for the current and upcoming months.'
    task :create_event_partitions => :environment do |t, args|
      Shard.with_each_shard do
        Quizzes::QuizSubmissionEventPartitioner.logger = Logger.new(STDOUT)
        Quizzes::QuizSubmissionEventPartitioner.process
      end
    end
  end
end
