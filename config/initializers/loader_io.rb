# If you want to load test an arbitrary app using the Heroku loader.io addon
# this lets you verify that you own the app by setting the ENV['LOADER_IO_TOKEN']
# to the verifcation token described here:
# https://devcenter.heroku.com/articles/loaderio#app-verification

if ENV['LOADER_IO_TOKEN']
  verification_token_filename = "#{ENV['LOADER_IO_TOKEN']}.txt"
  verification_token_path = Rails.public_path + verification_token_filename
  puts "Detected a LOADER_IO_TOKEN environment variable. Configuring http://#{ENV['DOMAIN']}/#{verification_token_filename} to return it for verification purposes."
  unless File.exist?(verification_token_path)
    File.open(verification_token_path, "w+") do |f|
      f.write(ENV['LOADER_IO_TOKEN'])
    end
  end
end

