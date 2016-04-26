=begin
VeriCiteV1
=end

# Common files
require 'vericite_client/api_client'
require 'vericite_client/api_error'
require 'vericite_client/version'
require 'vericite_client/configuration'

# Models
require 'vericite_client/models/external_content_data'
require 'vericite_client/models/consumer_data'
require 'vericite_client/models/error'
require 'vericite_client/models/consumer_response'
require 'vericite_client/models/external_content_upload_info'
require 'vericite_client/models/report_meta_data'
require 'vericite_client/models/report_url_link_reponse'
require 'vericite_client/models/report_score_reponse'
require 'vericite_client/models/assignment_data'

# APIs
require 'vericite_client/api/default_api'

module VeriCiteClient
  class << self
    # Customize default settings for the SDK using block.
    #   VeriCiteClient.configure do |config|
    #     config.username = "xxx"
    #     config.password = "xxx"
    #   end
    # If no block given, return the default Configuration object.
    def configure
      if block_given?
        yield(Configuration.default)
      else
        Configuration.default
      end
    end
  end
end
