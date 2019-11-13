namespace :strongmind do
  desc "Build process for canvas:compile_assets etc\n\n"
  task :run do |t, args|
    puts "TESLA, MASTER OF LIGHTING WILL INVOKE ASSET COMPILATION/GENERATE FOR PROJECT AND RUN IT."
    ::Rake::Task['canvas:compile_assets'].invoke
    puts "[Finished] canvas:compile_assets\n\n"
    sleep(10)
    puts "[Starting] brand_configs:generate_and_upload_all"
    ::Rake::Task['brand_configs:generate_and_upload_all'].invoke
    sleep(10)
    puts "[Finished] brand_configs:generate_and_upload_all"

    puts "canvas:compile_assets and brand_configs:generate_and_upload_all ran successfully."

    puts "running the rails server"
    exec("rails server")
  end

  desc "Upload courseware assets to S3"
  task :upload_assets => :environment do
    CanvasShimAssetUploader.new.upload!
  end

  desc "Reset Session Secret"
  task :reset_session_secret =>  :environment do
    puts Setting.set("session_secret_key", SecureRandom.hex(64))
  end

  desc "Re-enqueue orphaned jobs after deploy"
  task :enqueue_jobs, [:worker_id] => :environment do |task, args|
    worker_id = args[:worker_id]
    puts "RE-ENQUEUE JOBS !!!!!! #{worker_id}"
    Delayed::Job.where("locked_by ilike ?", "#{worker_id}%").update(run_at: Time.now, locked_by: nil, locked_at: nil)
  end

  desc "Re-enqueue orphaned jobs after deploy on ECS"
  task :enqueue_jobs_ecs => :environment do |task, args|
    Delayed::Job.where.not(locked_by: nil, locked_at: nil).update(run_at: Time.now, locked_by: nil, locked_at: nil)
  end

  desc "Reset EULA accepted"
  task :reset_eula_accepted => :environment do
    User.find_each do |user|
      if user.preferences[:accepted_terms]
        accepted_at = user.preferences[:accepted_terms]
        puts "#{user.id}, #{accepted_at}"
        csv = CSV.open('/tmp/reset_eula.log', 'a+')
        csv << [user.id, accepted_at]
        csv.close
        user.preferences[:accepted_terms] = nil;
        user.save
      end
    end

    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'], access_key_id: ENV['S3_ACCESS_KEY_ID'], secret_access_key: ENV['S3_ACCESS_KEY'])
    obj = s3.bucket(ENV['S3_BUCKET_NAME']).object('reset_eula/reset_eula.log')
    obj.upload_file('/tmp/reset_eula.log')
  end

  desc "Activate Canvas Analytics"
  task :activate_analytics => :environment do
    Setting.set('enable_page_views', 'db')
  end

  desc "Deactivate Canvas Analytics"
  task :deactivate_analytics => :environment do
    Setting.find_by_name("enable_page_views").delete
  end

  desc "Truncate Canvas Analytics"
  task :truncate_analytics => :environment do
    PageView.connection.truncate(PageView.table_name)
  end

  desc "Enable Course Snapshot"
  task :enable_course_snapshot => :environment do
    SettingsService.update_settings(
      id: '1',
      setting: 'enable_course_snapshot',
      value: true,
      object: "school"
    )
  end

  desc "Enable Date Distribution Buttons"
  task :enable_due_date_buttons => :environment do
    SettingsService.update_settings(
      id: '1',
      setting: 'due_date_buttons',
      value: true,
      object: "school"
    )
  end

  desc "redistribute due dates on courses after X start date"
  task :redistribute_date_dates_after => :environment do
    abort("No date specified in ENV") unless ENV['REDISTRIBUTE_AFTER']
    start_after = Date::strptime(ENV['REDISTRIBUTE_AFTER'], "%m-%d-%Y")
    courses = Course.where('start_at > ?', start_after)
    CSV_FILE_NAME = "#{ENV['SCHOOL_NAME']}_due_date_redistribute_due_dates_#{Time.now.utc.iso8601}"
    CSV.open(CSV_FILE_NAME, "wb") do |csv|
      courses.each do |course|
        next unless course.conclude_at?
        puts "working on course #{course.id}"
          course.assignments.each do |assignment|
            csv << [course.id, assignment.id, assignment.due_at || "none"]
          end
          if ENV['COMMIT'] == "1"
            AssignmentsService.distribute_due_dates(course: course)
          end
      end
      csv.close
      s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'], access_key_id: ENV['S3_ACCESS_KEY_ID'], secret_access_key: ENV['S3_ACCESS_KEY'])
      obj = s3.bucket(ENV['S3_BUCKET_NAME']).object("due_date_redistribute/#{CSV_FILE_NAME}")
      obj.upload_file(CSV_FILE_NAME)
    end
  end

end
