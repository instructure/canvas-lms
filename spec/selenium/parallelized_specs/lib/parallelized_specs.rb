require 'parallel'
raise "please ' gem install parallel '" if Gem::Version.new(Parallel::VERSION) < Gem::Version.new('0.4.2')
require 'parallelized_specs/grouper'
require 'parallelized_specs/railtie'
require 'parallelized_specs/spec_error_logger'
require 'parallelized_specs/spec_error_count_logger'
require 'parallelized_specs/spec_start_finish_logger'
require 'parallelized_specs/outcome_builder'
require 'parallelized_specs/example_failures_logger'
require 'parallelized_specs/trending_example_failures_logger'
require 'parallelized_specs/failures_rerun_logger'
require 'parallelized_specs/slow_spec_logger'
require 'fileutils'

class ParallelizedSpecs
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).strip

  def self.run_tests(test_files, process_number, options)
    exe = executable # expensive, so we cache
    version = (exe =~ /\brspec\b/ ? 2 : 1)
    cmd = "#{rspec_1_color if version == 1}#{exe} #{options[:test_options]} #{rspec_2_color if version == 2}#{spec_opts(version)} #{test_files*' '}"
    execute_command(cmd, process_number, options)
  end

  def self.executable
    cmd = if File.file?("script/spec")
            "script/spec"
          elsif bundler_enabled?
            cmd = (run("bundle show rspec") =~ %r{/rspec-1[^/]+$} ? "spec" : "rspec")
            "bundle exec #{cmd}"
          else
            %w[spec rspec].detect { |cmd| system "#{cmd} --version > /dev/null 2>&1" }
          end
    cmd or raise("Can't find executables rspec or spec")
  end

  protected
  #so it can be stubbed....
  def self.run(cmd)
    `#{cmd}`
  end

  def self.rspec_1_color
    'RSPEC_COLOR=1 ; export RSPEC_COLOR ;' if $stdout.tty?
  end

  def self.rspec_2_color
    '--color --tty ' if $stdout.tty?
  end

  def self.spec_opts(rspec_version)
    options_file = %w(spec/parallelized_spec.opts spec/spec.opts).detect { |f| File.file?(f) }
    return unless options_file
    "-O #{options_file}"
  end

  def self.test_suffix
    "_spec.rb"
  end

  def self.execute_parallel_db(cmd, options={})
    count = options[:count].to_i || Parallel.processor_count
    count = Parallel.processor_count if count == 0
    runs = (0...count).to_a
    results = if options[:non_parallel]
                runs.map do |i|
                  execute_command(cmd, i, options)
                end
              else
                Parallel.map(runs, :in_processes => count) do |i|
                  execute_command(cmd, i, options)
                end
              end.flatten
    abort if results.any? { |r| r[:exit_status] != 0 }
  end

  def self.execute_parallel_specs(options)
    if options[:files].to_s.empty?
      tests = find_tests(Rails.root, options)
      run_specs(tests, options)
    else
      run_specs(options[:files], options)
    end
  end

  def self.run_specs(tests, options)
    formatters = formatters_setup
    @outcome_builder_enabled = formatters.any? { |formatter| formatter.match(/OutcomeBuilder/) }
    @reruns_enabled = formatters.any? { |formatter| formatter.match(/FailuresFormatter/) }
    @slow_specs_enabled = formatters.any? { |formatter| formatter.match(/SlowestSpecLogger/) }
    num_processes = options[:count] || Parallel.processor_count
    name = 'spec'

    start = Time.now

    tests_folder = 'spec'
    tests_folder = File.join(options[:root], tests_folder) unless options[:root].to_s.empty?
    if !tests.is_a?(Array)
      files_array = tests.split(/ /)
    end
    groups = tests_in_groups(files_array || tests || tests_folder, num_processes, options)

    num_processes = groups.size

    #adjust processes to groups
    abort "SEVERE: no #{name}s found!" if groups.size == 0

    num_tests = groups.inject(0) { |sum, item| sum + item.size }
    puts "INFO: #{num_processes} processes for #{num_tests} #{name}s, ~ #{num_tests / groups.size} #{name}s per process"

    test_results = Parallel.map(groups, :in_processes => num_processes) do |group|
      run_tests(group, groups.index(group), options)
    end
    failed = test_results.any? { |result| result[:exit_status] != 0 } #ruby 1.8.7 works breaks on 1.9.3
    slowest_spec_determination("#{Rails.root}/tmp/parallel_log/slowest_specs.log") if @slow_specs_enabled

    results = find_results(test_results.map { |result| result[:stdout] }*"")

    if @outcome_builder_enabled
      puts "INFO: OutcomeBuilder is enabled now checking for false positives"
      @total_specs, @total_failures, @total_pending = calculate_total_spec_details
      puts "INFO: Total specs run #{@total_specs} failed specs  #{@total_failures} pending specs #{@total_pending}\n INFO: Took #{Time.now - start} seconds"
      #determines if any tricky conditions happened that can cause false positives and offers logging into what was the last spec to start or finishing running
      false_positive_sniffer(num_processes)
      if @reruns_enabled && @total_failures != 0
        puts "INFO: RERUNS are enabled"
        rerun_initializer
      else
        abort("SEVERE: #{name.capitalize}s Failed") if @total_failures != 0
      end
    else
      puts "WARNING: OutcomeBuilder is disabled not checking for false positives its likely things like thread failures and rspec non 0 exit codes will cause false positives"
      puts "INFO: #{summarize_results(results)} Took #{Time.now - start} seconds"
      abort("SEVERE: #{name.capitalize}s Failed") if failed
    end
    puts "INFO: marking build as PASSED"
  end

  def self.calculate_total_spec_details
    spec_total_details = [0, 0, 0]
    File.open("#{Rails.root}/tmp/parallel_log/total_specs.txt").each_line do |count|
      thread_spec_details = count.split("*")
      spec_total_details[0] += thread_spec_details[0].to_i
      spec_total_details[1] += thread_spec_details[1].to_i
      spec_total_details[2] += thread_spec_details[2].to_i
    end
    [spec_total_details[0], spec_total_details[1], spec_total_details[2]]
  end

  def self.formatters_setup
    formatters = []
    File.open("#{Rails.root}/spec/spec.opts").each_line do |line|
      formatters << line
    end
    formatter_directory_management(formatters)
    formatters
  end

  def self.formatter_directory_management(formatters)
    FileUtils.mkdir_p('parallel_log') if !File.directory?('tmp/parallel_log')
    begin
      ['tmp/parallel_log/spec_count', 'tmp/parallel_log/failed_specs', 'tmp/parallel_log/thread_started'].each do |dir|
        directory_cleanup_and_create(dir)
        ['rspec.failures', 'total_count.txt', 'error.log', 'error_count.log', 'outcome_builder.log', 'trends.log', 'example_rerun_failures.log'].each do |file|
          file_cleanup_and_create(file)
        end
      end
    rescue SystemCallError
      $stderr.print "directory management error " + $!
      raise
    end
  end

  def self.file_cleanup_and_create(file)
    if File.exists?(file)
      `rm tmp/parallel_log/#{file} && touch tmp/parallel_log/#{file}`
    else
      `touch tmp/parallel_log/#{file}`
    end
  end

  def self.directory_cleanup_and_create(dir)
    if File.directory?(dir)
      `rm -rf #{dir} && mkdir #{dir}`
    else
      `mkdir #{dir}`
    end
  end

  def self.rerun_initializer()
    if @total_failures != 0 && !File.zero?("#{Rails.root}/tmp/parallel_log/rspec.failures") # works on both 1.8.7\1.9.3
      puts "INFO: some specs failed, about to start the rerun process\n...\n..\n."
      ParallelizedSpecs.rerun(@total_failures)
    else
      #works on both 1.8.7\1.9.3
      puts "ERROR: the build had failures but the rspec.failures file is null"
      abort "SEVERE: SPECS Failed"
    end
  end

  def self.false_positive_sniffer(num_processes)
    if Dir.glob("#{Rails.root}/tmp/parallel_log/spec_count/{*,.*}").count == 2 && Dir.glob("#{Rails.root}/tmp/parallel_log/thread_started/{*,.*}").count == num_processes + 2
      (puts "INFO: All threads completed")
    elsif Dir.glob("#{Rails.root}/tmp/parallel_log/thread_started/{*,.*}").count != num_processes + 2
      File.open("#{Rails.root}/tmp/parallel_log/error.log", 'a+') { |f| f.write "\n\n\n syntax errors" }
      File.open("#{Rails.root}/tmp/failure_cause.log", 'a+') { |f| f.write "syntax errors" }
      abort "SEVERE: one or more threads didn't get started by rspec, this may be caused by a syntax issue in specs, check logs right before specs start running"
    else
      threads = Dir["#{Rails.root}/tmp/parallel_log/spec_count/*"]
      threads.each do |t|
        failed_thread = t.match(/\d/).to_s
        if failed_thread == "1"
          last_spec = IO.readlines("#{Rails.root}/tmp/parallel_log/thread_.log")[-1]
          puts "INFO: Thread 1 last spec to start running \n #{last_spec}"
          File.open("#{Rails.root}/tmp/parallel_log/error.log", 'a+') { |f| f.write "\n\n\n\nrspec thread #{failed_thread} failed to complete\n the last spec to try to run was #{last_spec}" }
        else
          last_spec = IO.readlines("#{Rails.root}/tmp/parallel_log/thread_#{failed_thread}.log")[-1]
          puts "INFO: Thread #{failed_thread} last spec to start running \n #{last_spec}"
          File.open("#{Rails.root}/tmp/parallel_log/error.log", 'a+') { |f| f.write "\n\n\n\nrspec thread #{failed_thread} failed to complete\n the last spec to try to run was #{last_spec}" }
        end
      end
      File.open("#{Rails.root}/tmp/failure_cause.log", 'a+') { |f| f.write "rspec thread failed to complete" }
      abort "SEVERE: One or more threads have failed to complete, this may be caused by a rspec runtime crashing prematurely" #works on both 1.8.7\1.9.3
    end
  end

# parallel:spec[:count, :pattern, :options]
  def self.parse_rake_args(args)
    # order as given by user
    args = [args[:count], args[:pattern]]

    # count given or empty ?
    count = args.shift if args.first.to_s =~ /^\d*$/
    num_processes = count.to_i unless count.to_s.empty?
    num_processes ||= ENV['PARALLEL_TEST_PROCESSORS'].to_i if ENV['PARALLEL_TEST_PROCESSORS']
    num_processes ||= Parallel.processor_count

    pattern = args.shift

    [num_processes.to_i, pattern.to_s]
  end

# finds all tests and partitions them into groups
  def self.tests_in_groups(tests, num_groups, options)
    if options[:no_sort]
      Grouper.in_groups(tests, num_groups)
    else
      tests = with_runtime_info(tests)
      Grouper.in_even_groups_by_size(tests, num_groups, options)
    end
  end

  def self.execute_command(cmd, process_number, options)
    cmd = "TEST_ENV_NUMBER=#{test_env_number(process_number)} ; export TEST_ENV_NUMBER; #{cmd}"
    f = open("|#{cmd}", 'r')
    output = fetch_output(f, options)
    f.close
    puts "Exit status for process #{process_number} #{$?.exitstatus}"
    {:stdout => output, :exit_status => $?.exitstatus}
  end

  def self.find_results(test_output)
    test_output.split("\n").map { |line|
      line = line.gsub(/\.|F|\*/, '')
      next unless line_is_result?(line)
      line
    }.compact
  end

  def self.test_env_number(process_number)
    process_number == 0 ? '' : process_number + 1
  end

  def self.runtime_log
    'tmp/parallelized_runtime_test.log'
  end

  def self.summarize_results(results)
    results = results.join(' ').gsub(/s\b/, '') # combine and singularize results
    counts = results.scan(/(\d+) (\w+)/)
    sums = counts.inject(Hash.new(0)) do |sum, (number, word)|
      sum[word] += number.to_i
      sum
    end
    sums.sort.map { |word, number| "#{number} #{word}#{'s' if number != 1}" }.join(', ')
  end

  protected

# read output of the process and print in in chucks
  def self.fetch_output(process, options)
    all = ''
    buffer = ''
    timeout = options[:chunk_timeout] || 0.2
    flushed = Time.now.to_f

    while (char = process.getc)
      char = (char.is_a?(Fixnum) ? char.chr : char) # 1.8 <-> 1.9
      all << char

      # print in chunks so large blocks stay together
      now = Time.now.to_f
      buffer << char
      if flushed + timeout < now
        print buffer
        STDOUT.flush
        buffer = ''
        flushed = now
      end
    end

    # print the remainder
    print buffer
    STDOUT.flush

    all
  end

# copied from http://github.com/carlhuda/bundler Bundler::SharedHelpers#find_gemfile
  def self.bundler_enabled?
    return true if Object.const_defined?(:Bundler)

    previous = nil
    current = File.expand_path(Dir.pwd)

    until !File.directory?(current) || current == previous
      filename = File.join(current, "Gemfile")
      return true if File.exists?(filename)
      current, previous = File.expand_path("..", current), current
    end

    false
  end

  def self.line_is_result?(line)
    line =~ /\d+ failure/
  end

  def self.with_runtime_info(tests)
    lines = File.read(runtime_log).split("\n") rescue []

    # use recorded test runtime if we got enough data
    if lines.size * 1.5 > tests.size
      puts "Using recorded test runtime"
      times = Hash.new(1)
      lines.each do |line|
        test, time = line.split(":")
        next unless test and time
        times[File.expand_path(test)] = time.to_f
      end
      tests.sort.map { |test| [test, times[test]] }
    else # use file sizes
      tests.sort.map { |test| [test, File.stat(test).size] }
    end
  end

  def self.find_tests(root, options={})
    if root.is_a?(Array)
      root
    else
      # follow one symlink and direct children
      # http://stackoverflow.com/questions/357754/can-i-traverse-symlinked-directories-in-ruby-with-a-glob
      files = Dir["#{root}/**{,/*/**}/*#{test_suffix}"].uniq
      files = files.map { |f| f.sub(root+'/', '') }
      files = files.grep(/#{options[:pattern]}/)
      files.map { |f| "/#{f}" }
    end
  end

  def self.update_rerun_summary(l, outcome, stack = "")
    File.open(@failure_summary, 'a+') { |f| f.puts("Outcome #{outcome} for #{l}\n #{stack}") }
    File.open("#{Rails.root}/tmp/parallel_log/error.log", 'a+') { |f| f.puts("Outcome #{outcome} for #{l}\n #{stack}") } if outcome == "FAILED"
  end

  def self.parse_result(result)
    puts "INFO: this is the result\n#{result}"
    #can't just use exit code, if specs fail to start it will pass or if a spec isn't found, and sometimes rspec 1 exit codes aren't right
    examples = result.match(/(\d) example/).to_a
    failures = result.match(/(\d) failure/).to_a
    @examples = examples.last.to_i
    @failures = failures.last.to_i
  end

  def self.rerun_spec(spec)
    puts "INFO: #{spec} will be ran and marked as a success if it passes"
    @examples = 0
    @failures = 0
    `rm config/selenium.yml || :`
    result = %x[export DISPLAY=:20.0 firefox && bundle exec rake spec #{spec}]
    parse_result(result)
    result
  end

  def self.print_failures(failure_summary, state = "")
    puts "*****************INFO: #{state} SUMMARY*****************\n"
    state == "RERUN" ? puts("INFO: outcomes of the specs that were rerun") : puts("INFO: summary of build failures")
    file = File.open(failure_summary, "r")
    content = file.read
    puts content
  end

  def self.abort_reruns(code, result = "", l = "")
    case
      when code == 1
        print_failures("#{Rails.root}/tmp/parallel_log/error.log")
        abort "SEVERE: shared specs currently are not eligiable for reruns, marking build as a failure"
      when code == 2 # <--- won't ever happen, 2 and 3 are duplicate clean up on refactor
        update_rerun_summary(l, "FAILED", result)
        print_failures(@failure_summary, "RERUN")
        abort "SEVERE: spec didn't actually run, ending rerun process early"
      when code == 3
        update_rerun_summary(l, "FAILED", result)
        print_failures(@failure_summary, "RERUN")
        abort "SEVERE: the spec failed to run on the rerun try, marking build as failed"
      when code == 4
        update_rerun_summary(l, "FAILED", result)
        print_failures(@failure_summary, "RERUN")
        abort "SEVERE: unexpected outcome on the rerun, marking build as a failure"
      when code == 5
        abort "SEVERE: #{@error_count} errors, but the build failed, errors were not written to the file or there is something else wrong, marking build as a failure"
      when code == 6
        print_failures("#{Rails.root}/tmp/parallel_log/error.log")
        abort "SEVERE: #{@error_count} errors are to many to rerun, marking the build as a failure. Max errors defined for this build is #{@max_reruns}"
      when code == 7
        puts "#Total errors #{@error_count}"
        abort "SEVERE: unexpected error information, please check errors are being written to file correctly"
      when code == 8
        print_failures(@failure_summary, "RERUN")
        File.open("#{Rails.root}/tmp/failure_cause.log", 'a+') { |f| f.write "#{@rerun_failures.count} failures" }
        abort "SEVERE: some specs failed on rerun, the build will be marked as failed"
      when code == 9
        abort "SEVERE: unexpected situation on rerun, marking build as failure"
      when code == 10
        `cat tmp/parallel_log/rspec.failures`
        abort "SEVERE: reruns isn't running because there is a mismatch in the number of expected errors"
      else
        abort "SEVERE: unhandled abort_reruns code"
    end
  end

  def self.update_failed(l, result)
    puts "WARNING: the example failed again"
    update_rerun_summary(l, "FAILED", result)
    @rerun_failures << l
  end

  def self.update_passed(l)
    update_rerun_summary(l, "PASSED")
    puts "INFO: the example passed and is being marked as a success"
    @rerun_passes << l
  end

  def self.pass_reruns()
    print_failures(@failure_summary, "RERUN")
    puts "INFO: rerun summary all rerun examples passed, rspec will mark this build as passed"
  end

  def self.calculate_error_count()
    @error_count = %x{wc -l "#{@filename}"}.match(/\d*[^\D]/).to_s #counts the number of lines in the file
    @error_count = @error_count.to_i
    puts "INFO: error count = #@error_count"
    ENV["RERUNS"] != nil ? @max_reruns = ENV["RERUNS"].to_i : @max_reruns = 9

    if !@error_count.between?(1, @max_reruns) || @rspec_total_error_count > @error_count
      puts "INFO: total errors are not in rerun eligibility range"
      case
        when @error_count == 0
          puts "INFO: 0 errors build being aborted"
          abort_reruns(5)
        when @error_count > @max_reruns
          puts "INFO: error count has exceeded maximum errors of #{@max_reruns}"
          abort_reruns(6)
        when @rspec_total_error_count > @error_count
          puts "rspec reported more errors than rspec.failures contains, not safe to pass build using reruns"
          abort_reruns(10)
        else
          abort_reruns(7)
      end
    else
      @error_count
    end
  end

  def self.determine_rerun_eligibility
    @error_count = calculate_error_count
    puts "INFO: total errors #{@error_count}"

    File.open(@filename).each_line do |line|
      if line =~ /spec\/selenium\/helpers/
        abort_reruns(1)
      else
        puts "INFO: the following spec is eligible for reruns #{line}"
        @rerun_specs.push line
      end
    end
    puts "INFO: failures meet rerun criteria \n INFO: rerunning #{@error_count} examples"
    File.open("#{Rails.root}/tmp/parallel_log/error.log", 'a+') { |f| f.puts("\n\n\n\n\n *****RERUN FAILURES*****\n") }
  end

  def self.start_reruns
    determine_rerun_eligibility

    @rerun_failures ||= []
    @rerun_passes ||= []

    @rerun_specs.each do |l|
      puts "INFO: starting next spec"
      result = rerun_spec(l)

      puts "INFO: determining if the spec passed or failed"
      puts "INFO: examples run = #@examples examples failed = #@failures"


      if @examples == 0 && @failures == 0 #when specs fail to run it exits with 0 examples, 0 failures and won't be matched by the previous regex
        abort_reruns(3, result, l)
      elsif @failures > 0
        update_failed(l, result)
      elsif @examples > 0 && @failures == 0
        update_passed(l)
      else
        abort_reruns(4, result, l)
      end

      puts "INFO: spec finished and has updated rerun state"
    end
    puts "INFO: reruns have completed calculating if build has passed or failed"
    puts "INFO: total failed specs #{@rerun_failures.count}"
    puts "INFO: total passed specs #{@rerun_passes.count}"
    determine_rerun_outcome
  end


  def self.determine_rerun_outcome
    if @rerun_failures.count > 0
      abort_reruns(8)
    elsif @rerun_passes.count >= @error_count
      pass_reruns
    else
      abort_reruns(9)
    end
  end

  def self.runtime_setup
    @rerun_specs = []
    @filename = "#{Rails.root}/tmp/parallel_log/rspec.failures"
    @failure_summary = "#{Rails.root}/tmp/parallel_log/rerun_failure_summary.log"
  end

  def self.rerun(rspec_total_error_count)
    @rspec_total_error_count = rspec_total_error_count
    puts "INFO: beginning the failed specs rerun process"
    runtime_setup
    start_reruns
  end

  def self.slowest_spec_determination(file)
    if File.exists?(file)
      spec_durations = []
      File.open(file).each_line do |line|
        spec_durations << line
      end

      File.open(file, 'w') { |f| f.truncate(0) }
      populate_slowest_specs(spec_durations, file)
    else
      puts "slow spec profiling was not enabled"
    end
  end

  def self.populate_slowest_specs(spec_durations, file)
    slowest_specs = []
    ENV["MAX_TIME"] != nil ? max_time = ENV["MAX_TIME"].to_i : max_time = 30
    spec_durations.each do |spec|
      time = spec.match(/.*\d/).to_s
      if time.to_f >= max_time
        slowest_specs << spec
      end
    end
    slowest_specs.each do |slow_spec|
      File.open(file, 'a+') { |f| f.puts slow_spec }
    end
  end
end