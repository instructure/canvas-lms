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

end
