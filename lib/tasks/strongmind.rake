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

end
