# frozen_string_literal: true

namespace :canvas do
  namespace :cdn do
    desc "Push static assets to s3"
    task :upload_to_s3 do
      require_relative "../../../config/environment" rescue nil
      Canvas::Cdn.push_to_s3!(verbose: ENV["VERBOSE"] == "1")
    end
  end
end
