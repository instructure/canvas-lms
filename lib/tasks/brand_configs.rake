namespace :brand_configs do
  desc "Writes the .css (css variables), .js & .json files that are used to load the theme editor variables for each brand " +
       "Set BRAND_CONFIG_MD5=<whatever> to save just that one, otherwise writes a file for each BrandConfig in db."
  task :write => :environment do
    if md5 = ENV['BRAND_CONFIG_MD5']
      BrandConfig.find(md5).save_all_files!
    else
      BrandConfig.clean_unused_from_db!
      BrandConfig.find_each(&:save_all_files!)
    end
  end
  Switchman::Rake.shardify_task('brand_configs:write')

  # This is the rake task we call from a job server that has new code,
  # before restarting all the app servers.  It will make sure that our s3
  # bucket has the .css (css variables), .js & .json files that are used to 
  # load the theme editor variables  for custom themes people
  # have created in the Theme Editor.
  desc "generate all brands and upload everything to s3"
  task :generate_and_upload_all => :environment do
    BrandableCSS.save_default_files!
    Rake::Task['brand_configs:write'].invoke
  end
end
