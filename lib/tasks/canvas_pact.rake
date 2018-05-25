require 'pact_broker/client/tasks'

# see https://github.com/pact-foundation/pact_broker-client/blob/master/README.md
namespace :broker do
  PactBroker::Client::PublicationTask.new(:local) do |task|
    format_rake_task(
        task,
        'http://pact-broker.docker',
        'pact',
        'broker',
        'local'
    )
  end

  PactBroker::Client::PublicationTask.new(:jenkins_post_merge) do |task|
    format_rake_task(
        task,
        ENV.fetch('PACT_BROKER_BASE_URL'),
        ENV.fetch('PACT_BROKER_BASIC_AUTH_USERNAME'),
        ENV.fetch('PACT_BROKER_BASIC_AUTH_PASSWORD'),
        'master'
    )
  end

  def format_rake_task(task, url, username, password, task_tag)
    require 'quiz_api_client'

    task.consumer_version = CanvasApiClient::VERSION
    task.pattern = 'pacts/*.json'

    task.pact_broker_base_url = url
    task.pact_broker_basic_auth = { username: username, password: password }

    task.tag = task_tag
    puts "Pact file tagged with: #{task.tag}"
  end
end
