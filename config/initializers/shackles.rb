if ENV['RAILS_DATABASE_ENVIRONMENT']
  Shackles.activate!(ENV['RAILS_DATABASE_ENVIRONMENT'].to_sym)
end
if ENV['RAILS_DATABASE_USER']
  Shackles.apply_config!(:username => ENV['RAILS_DATABASE_USER'], :password => nil)
end
