require File.expand_path(File.dirname(__FILE__) + '/../../spec/spec_helper')

describe "memory and cpu tracking", type: :request do

  it "should pass cpu info to statsd" do
    account = Account.default

    allow(Process).to receive(:times).and_return(double(stime: 0, utime: 0))

    user_cpu = 0
    system_cpu = 0
    if account.shard.respond_to?(:database_server)
      expect(CanvasStatsd::Statsd).to receive(:timing).with("requests_user_cpu.cluster_#{account.shard.database_server.id}", user_cpu)
      expect(CanvasStatsd::Statsd).to receive(:timing).with("requests_system_cpu.cluster_#{account.shard.database_server.id}", system_cpu)
    end
    expect(CanvasStatsd::Statsd).to receive(:timing).with('request.users.user_dashboard.total', kind_of(Numeric))
    # user_dashboard_view doesn't get populated here as there is no view_runtime to populate
    expect(CanvasStatsd::Statsd).to receive(:timing).with('request.users.user_dashboard.db', kind_of(Numeric))
    expect(CanvasStatsd::Statsd).to receive(:timing).with('request.users.user_dashboard.active_record', kind_of(Numeric))
    expect(CanvasStatsd::Statsd).to receive(:timing).with('request.users.user_dashboard.sql.read', kind_of(Numeric))
    expect(CanvasStatsd::Statsd).to receive(:timing).with('request.users.user_dashboard.sql.write', kind_of(Numeric))
    expect(CanvasStatsd::Statsd).to receive(:timing).with('request.users.user_dashboard.sql.cache', kind_of(Numeric))
    expect(CanvasStatsd::Statsd).to receive(:timing).with('request.users.user_dashboard.cache.read', kind_of(Numeric))
    get "/"
  end
end
