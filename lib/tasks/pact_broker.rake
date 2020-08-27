require 'pact_broker/client/tasks'
require_relative '../../spec/contracts/service_consumers/pact_config'

# see https://github.com/pact-foundation/pact_broker-client/blob/master/README.md
namespace :broker do
  PactBroker::Client::PublicationTask.new(:local) do |task|
    prepare_pact_files_for_publishing(task)
  end

  PactBroker::Client::PublicationTask.new(:jenkins_post_merge) do |task|
    prepare_pact_files_for_publishing(task)
  end

  def prepare_pact_files_for_publishing(task)
    task.pattern = 'pacts/**/*.json'
    task.pact_broker_base_url = PactConfig.broker_host
    task.pact_broker_basic_auth = {
      username: PactConfig.broker_username,
      password: PactConfig.broker_password
    }
    task.consumer_version = PactConfig.consumer_version
    puts "Consumer version: #{task.consumer_version}"
    task.tag = PactConfig.consumer_tag
    puts "Pact file tagged with: #{task.tag}"
  end
end
