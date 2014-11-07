# Don't load rspec if running "rake gems:*"
unless ARGV.any? { |a| a =~ /\Agems/ }

  namespace :parallel do

    task :nonselenium, :count do |t, args|
      Rake::Task['spec:plugin_non_parallel'].execute
      Rake::Task['parallel:plugin_parallel'].invoke(args[:count])
    end

    task :plugin_parallel, :count do |t, args|
      require "parallelized_specs"
      count = args[:count]
      test_files = FileList['{gems,vendor}/plugins/*/spec_canvas/**/*_spec.rb'].exclude(%r'spec_canvas/selenium') + FileList['spec/**/*_spec.rb'].exclude(%r'spec/selenium')
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      Rake::Task['parallel:spec'].invoke(count, '', '', test_files.join(' '))
    end

    task :selenium, :count, :build_section do |t, args|
      require "parallelized_specs"
      #used to split selenium builds when :build_section is set split it in two.
      Rake::Task['spec:selenium_non_parallel'].execute

      test_files = FileList['spec/selenium/**/*_spec.rb'] + FileList['{gems,vendor}/plugins/*/spec_canvas/selenium/*_spec.rb']

      test_files = test_files.to_a.sort_by! { |file| File.size(file) }
      args[:build_section].to_i == 0 ? section = nil : section = args[:build_section].to_i

      unless section.nil?
        test_files_a_sum = 0
        test_files_b_sum = 0
        test_files_a = []
        test_files_b = []
        test_files.each do |file|
          if test_files_a_sum < test_files_b_sum
            test_files_a << file
            test_files_a_sum += File.size(file)
          else
            test_files_b << file
            test_files_b_sum += File.size(file)
          end
        end

        case section
          when 1
            puts "INFO: running section 1"
            #runs upper half of selenium tests
            test_files = test_files_a
          when 2
            puts "INFO: running section 2"
            #runs lower half of selenium tests
            test_files = test_files_b
          else
            test_files = test_files_a + test_files_b
        end
      end
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      test_files.each { |f| puts f }

      puts 'starting paralellized selenium spec runtime'
      Rake::Task['parallel:spec'].invoke(args[:count], '', '', test_files.join(' '))
    end

    task :pattern, :count, :file_pattern do |t, args|
      require "parallelized_specs"
      count = args[:count]
      file_pattern = args[:file_pattern]
      if count.nil? || file_pattern.nil?
        raise "Must specify a thread count and file pattern"
      end
      test_files = FileList[file_pattern]
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      Rake::Task['parallel:spec'].invoke(count, '', '', test_files.join(' '))
    end
  end
end
