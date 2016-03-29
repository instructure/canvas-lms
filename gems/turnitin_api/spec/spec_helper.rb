$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'turnitin_api'
require 'webmock/rspec'


WebMock.disable_net_connect!(allow_localhost: true)


def fixture(*file)
  File.new(File.join(File.expand_path("../fixtures", __FILE__), *file))
end

def json_fixture(*file)
  JSON.parse(fixture(*file).read)
end