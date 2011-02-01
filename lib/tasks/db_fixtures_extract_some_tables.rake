# TODO: are these used anywhere?
namespace :db do
  namespace :fixtures do
    desc 'Create YAML test fixtures from data in an existing database for given tables 
    edit tables array below).  Defaults to development database.  Set RAILS_ENV to override.'
    task :extract_some_tables => :environment do
      sql = "SELECT * FROM %s"
      tables = ["notifications"]
      ActiveRecord::Base.establish_connection
      tables.each do |table_name|
        i = "000"
        File.open("#{RAILS_ROOT}/test/fixtures/#{table_name}.yml", "w") do |file|
          data = ActiveRecord::Base.connection.select_all(sql % table_name)
          file.write data.inject({}) { |hash, record|
            hash["#{table_name}_#{i.succ!}"] = record
            hash
          }.to_yaml
        end
      end
    end
  end
end
