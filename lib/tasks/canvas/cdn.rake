namespace :canvas do
  namespace :cdn do
    desc 'Push static assets to s3'
    task :upload_to_s3 => :environment do
      Canvas::Cdn.push_to_s3!
    end
  end
end
