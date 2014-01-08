# once off RAILS2, inline the action_dispatch version and remove this file
require 'action_controller'

if CANVAS_RAILS2
  require 'action_controller/test_process'
  module Rack
    module Test
      class UploadedFile < ActionController::TestUploadedFile; end
    end
  end
else
  require 'rack/test/uploaded_file'
end
