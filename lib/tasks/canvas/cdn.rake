# frozen_string_literal: true

namespace :canvas do
  namespace :cdn do
    desc "Push static assets to s3"
    task :upload_to_s3 do
      begin
        require_relative "../../../config/environment"
      rescue
        # we may be running in a reduced environment with just basic code in order to
        # build a release tarball; just ignore
      end
      Canvas::Cdn.push_to_s3!(verbose: ENV["VERBOSE"] == "1")
    end
  end
end
