# once off RAILS2, inline the action_dispatch version and remove this file
require 'action_controller'
if CANVAS_RAILS2
  require 'action_controller/test_process'
else
  # XXX: Rails3 doesn't have ActionController::TestUploadedFile, which is
  # usually why this is required. time to fix this
  require 'action_dispatch/testing/test_process'
end
