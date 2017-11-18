#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

if Rails.env.development? && ENV['BETTER_ERRORS_DISABLE'] != 'true'
  # TRUSTED_IP
  # Better errors will only display to requests from localhost by default.
  # If you're using Docker, you will need to enter your web container's ip
  # address in the TRUSTED_IP environment variable to allow better errors
  # to work. You can find your web container's IP address on the default
  # rails error page by clicking "Toggle env dump" and then at the
  # REMOTE_ADDR key value.
  #
  # * Security Note *
  # Never use this feature in conjunction with BETTER_ERRORS_ENABLE_CONSOLE
  # to expose the better errors REPL to the public internet via tunneling
  # tools like ngrok or localtunnel as this would be a remote code execution
  # vulnerability.
  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']

  # BETTER_ERRORS_EDITOR
  # Specify which app to open files in by setting BETTER_ERRORS_EDITOR to
  # any app that responds to `open` url schemes like `txmt://open?url=/Users...`
  # Some possible options are: 'emacs', 'mvim', or 'txmt'. Disabled by default.
  # If you want to use Sublime, see https://github.com/dhoulb/subl
  #
  # BETTER_ERRORS_LOCAL_PATH
  # If you are using Docker, you will also need to set BETTER_ERRORS_LOCAL_PATH
  # to point to the absolute path to canvas on your local machine,
  # like '/Users/<username>/Documents/canvas-lms', since it only knows the Docker path.
  # Is not used unless set.
  if ENV['BETTER_ERRORS_EDITOR']
    BetterErrors.editor = proc { |file, line|
      file = file.sub('/usr/src/app', ENV['BETTER_ERRORS_LOCAL_PATH']) if ENV['BETTER_ERRORS_LOCAL_PATH']
      "#{ENV['BETTER_ERRORS_EDITOR']}://open?url=#{URI.encode_www_form_component file}&line=#{line}"
    }
  end
end
