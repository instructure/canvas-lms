class ParallelizedSpecs::RuntimeLogger
  @@has_started = false

  def self.log(test, start_time, end_time)

    if !@@has_started # make empty log file 
      File.open(ParallelizedSpecs.runtime_log, 'w') do end
      @@has_started = true
    end

    File.open(ParallelizedSpecs.runtime_log, 'a') do |output|
      begin
        output.flock File::LOCK_EX
        output.puts(self.message(test, start_time, end_time))
      ensure
        output.flock File::LOCK_UN
      end
    end
  end

  def self.message(test, start_time, end_time)
    delta="%.2f" % (end_time.to_f-start_time.to_f)
    filename=class_directory(test.class) + class_to_filename(test.class) + ".rb"
    message="#{filename}:#{delta}"
  end
end
