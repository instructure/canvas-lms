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
    CanvasStatsd::Statsd.expects(:timing).with('request.users.user_dashboard.total', kind_of(Numeric))
    # user_dashboard_view doesn't get populated here as there is no view_runtime to populate
    CanvasStatsd::Statsd.expects(:timing).with('request.users.user_dashboard.db', kind_of(Numeric))
    CanvasStatsd::Statsd.expects(:timing).with('request.users.user_dashboard.active_record', kind_of(Numeric))
    CanvasStatsd::Statsd.expects(:timing).with('request.users.user_dashboard.sql.read', kind_of(Numeric))
    CanvasStatsd::Statsd.expects(:timing).with('request.users.user_dashboard.sql.write', kind_of(Numeric))
    CanvasStatsd::Statsd.expects(:timing).with('request.users.user_dashboard.sql.cache', kind_of(Numeric))
    get "/"
  end
end
