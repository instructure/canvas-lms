# monkey patch to always allow other ip addresses in development mode
if Rails.env.development? && !ENV['DISABLE_BETTER_ERRORS']
  module BetterErrors
    class Middleware
      def allow_ip?(_)
        true
      end
    end
  end

  # BETTER_ERRORS_EDITOR
  # Specify which app to open files in by setting BETTER_ERRORS_EDITOR to
  # any app that responds to `open` url schemes like `txmt://open?url=/Users...`
  # Some possible options are: 'emacs', 'mvim', or 'txmt'. Defaults to txmt.
  # If you want to use Sublime, see https://github.com/dhoulb/subl
  # 
  # BETTER_ERRORS_LOCAL_PATH
  # If you are using Docker, you will also need to set BETTER_ERRORS_LOCAL_PATH
  # to point to the absolute path to canvas on your local machine,
  # like '/Users/<username>/Documents/canvas-lms', since it only knows the docker path.
  BetterErrors.editor = proc { |file, line|
    file = file.sub('/usr/src/app', ENV['BETTER_ERRORS_LOCAL_PATH']) if ENV['BETTER_ERRORS_LOCAL_PATH']
    "#{ENV['BETTER_ERRORS_EDITOR' || 'txmt']}://open?url=#{URI.encode_www_form_component file}&line=#{line}"
  }
end
