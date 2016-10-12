# aws-sdk doesn't have any fine-grained logging options, just disable its
# logging to close the floodgates
require 'aws-sdk-v1'
AWS.config(:logger => nil)
