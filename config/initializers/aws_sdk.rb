# aws-sdk doesn't have any fine-grained logging options, just disable its
# logging to close the floodgates
require 'aws-sdk' # should already be auto-required by Gemfile, but safeguard
AWS.config(:logger => nil)
