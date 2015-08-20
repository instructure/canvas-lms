require 'lib/brandable_css'

namespace :brand_configs do
  desc "Write _brand_variable.scss to disk so canvas_css can render stylesheets for that branding. " +
       "Set BRAND_CONFIG_MD5=<whatever> to save just that one, otherwise writes a file for each BrandConfig in db."
  task :write => :environment do
    if md5 = ENV['BRAND_CONFIG_MD5']
      BrandConfig.find(md5).save_scss_file!
    else
      BrandConfig.clean_unused_from_db!
      BrandConfig.find_each(&:save_scss_file!)
    end
  end
  Switchman::Rake.shardify_task('brand_configs:write')

  desc "Remove all Brand Variable scss files"
  task :clean do
    rm_rf BrandableCSS.branded_scss_folder
  end

  # This is the rake task we call from a job server that has new code,
  # before restarting all the app servers.  It will make sure that our s3
  # bucket has all static assets including the css for custom themes people
  # have created in the Theme Editor.
  desc "generate all brands and upload everything to s3"
  task :generate_and_upload_all do
    Rake::Task['brand_configs:clean'].invoke
    Rake::Task['brand_configs:write'].invoke

    # This'll pick up on all those written brand_configs and compile their css.
    BrandableCSS.compile_all!
  end

end
