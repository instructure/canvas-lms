namespace :brand_configs do
  desc "Write _brand_variable.scss to disk so canvas_css can render stylesheets for that branding. " +
       "Set BRAND_CONFIG_MD5=<whatever> to save just that one, otherwise writes a file for each BrandConfig in db."
  task :write => :environment do
    if md5 = ENV['BRAND_CONFIG_MD5']
      BrandConfig.find(md5).save_file!
    else
      Rake::Task['brand_configs:clean'].invoke
      BrandConfig.find_each(&:save_file!)
    end
  end

  desc "Remove all Brand Variable scss files"
  task :clean do
    rm_rf BrandConfig::CONFIG['paths']['branded_scss_folder']
  end
end
