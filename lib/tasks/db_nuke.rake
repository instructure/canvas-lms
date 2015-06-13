namespace :db do
  task :nuke => :environment do
    # dont kill db:nuke if it dies with destoying all the attachments.  
    # it probably is just because it tries to delete an attachment who's 
    # file on disk or s3 is no longer there.
    Attachment.destroy_all rescue nil
    abcs = ActiveRecord::Base.configurations
    ["development"].each do |db|
      case abcs[db]["adapter"]
        when 'mysql', 'mysql2'
          ActiveRecord::Base.establish_connection(db.to_sym)
          conn = ActiveRecord::Base.connection
          conn.execute("DROP DATABASE #{abcs[db]["database"]}")
          conn.execute("CREATE DATABASE #{abcs[db]["database"]}")
          ActiveRecord::Base.establish_connection(db.to_sym)
        when "sqlite", "sqlite3"
          dbfile = abcs[db]["database"] || abcs[db]["dbfile"]
          begin
            File.delete(dbfile) if File.exist?(dbfile)
          rescue
            f = File.open(dbfile, "w")
            f.write("")
            f.close
          end
          ActiveRecord::Base.establish_connection(db.to_sym)
        else
          raise "Task not supported by '#{abcs[db]["adapter"]}'"
      end
      Rails.env = db
      Rake::Task["db:migrate"].dup.invoke
      Rake::Task["db:load_initial_data"].dup.invoke
      # Rake::Task["db:fixtures:load"].dup.invoke
      Rake::Task["db:test:prepare"].dup.invoke
      # Rake::Task["annotate_models"].dup.invoke
    end
  end
end
