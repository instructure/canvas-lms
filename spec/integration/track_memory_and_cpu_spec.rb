require File.expand_path(File.dirname(__FILE__) + '/../../spec/spec_helper')

describe "memory and cpu tracking", :type => :integration do

  it "should pass cpu info to statsd" do
    account = Account.default

    Process.stubs(:times).returns(stub(stime: 0, utime: 0))

    user_cpu = 0
    system_cpu = 0
    Canvas::Statsd.expects(:timing).with("requests_user_cpu.account_#{account.id}", user_cpu)
    Canvas::Statsd.expects(:timing).with("requests_system_cpu.account_#{account.id}", system_cpu)
    Canvas::Statsd.expects(:timing).with("requests_user_cpu.shard_#{account.shard.id}", user_cpu)
    Canvas::Statsd.expects(:timing).with("requests_system_cpu.shard_#{account.shard.id}", system_cpu)
    Canvas::Statsd.expects(:timing).with("requests_user_cpu.cluster_#{account.shard.database_server.id}", user_cpu)
    Canvas::Statsd.expects(:timing).with("requests_system_cpu.cluster_#{account.shard.database_server.id}", system_cpu)
    Canvas::Statsd.expects(:timing).with('request.users.user_dashboard', kind_of(Numeric))
    get "/"
  end
end
