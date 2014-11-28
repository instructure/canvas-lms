require File.expand_path(File.dirname(__FILE__) + '/../../spec/spec_helper')

describe "memory and cpu tracking", type: :request do

  it "should pass cpu info to statsd" do
    account = Account.default

    Process.stubs(:times).returns(stub(stime: 0, utime: 0))

    user_cpu = 0
    system_cpu = 0
    if account.shard.respond_to?(:database_server)
      CanvasStatsd::Statsd.expects(:timing).with("requests_user_cpu.cluster_#{account.shard.database_server.id}", user_cpu)
      CanvasStatsd::Statsd.expects(:timing).with("requests_system_cpu.cluster_#{account.shard.database_server.id}", system_cpu)
    end
    CanvasStatsd::Statsd.expects(:timing).with('request.users.user_dashboard', kind_of(Numeric))
    get "/"
  end
end
