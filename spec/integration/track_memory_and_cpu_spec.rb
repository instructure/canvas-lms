# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

describe "memory and cpu tracking" do
  it "passes cpu info to statsd" do
    account = Account.default

    allow(Process).to receive(:times).and_return(double(stime: 0, utime: 0))

    user_cpu = 0
    system_cpu = 0
    if account.shard.respond_to?(:database_server)
      expect(InstStatsd::Statsd).to receive(:timing).with("requests_user_cpu.cluster_#{account.shard.database_server.id}",
                                                          user_cpu,
                                                          short_stat: "requests_user_cpu",
                                                          tags: { cluster: account.shard.database_server.id })
      expect(InstStatsd::Statsd).to receive(:timing).with("requests_system_cpu.cluster_#{account.shard.database_server.id}",
                                                          system_cpu,
                                                          short_stat: "requests_system_cpu",
                                                          tags: { cluster: account.shard.database_server.id })
    end
    expect(InstStatsd::Statsd).to receive(:timing).with("request.users.user_dashboard.total",
                                                        kind_of(Numeric),
                                                        { tags: {}, short_stat: ".total" })
    # user_dashboard_view doesn't get populated here as there is no view_runtime to populate
    expect(InstStatsd::Statsd).to receive(:timing).with("request.users.user_dashboard.db",
                                                        kind_of(Numeric),
                                                        { tags: {}, short_stat: ".db" })
    expect(InstStatsd::Statsd).to receive(:timing).with("request.users.user_dashboard.active_record",
                                                        kind_of(Numeric),
                                                        { tags: {}, short_stat: ".active_record" })
    expect(InstStatsd::Statsd).to receive(:timing).with("request.users.user_dashboard.sql.read",
                                                        kind_of(Numeric),
                                                        { tags: {}, short_stat: ".sql.read" })
    expect(InstStatsd::Statsd).to receive(:timing).with("request.users.user_dashboard.sql.write",
                                                        kind_of(Numeric),
                                                        { tags: {}, short_stat: ".sql.write" })
    expect(InstStatsd::Statsd).to receive(:timing).with("request.users.user_dashboard.sql.cache",
                                                        kind_of(Numeric),
                                                        { tags: {}, short_stat: ".sql.cache" })
    expect(InstStatsd::Statsd).to receive(:timing).with("request.users.user_dashboard.cache.read",
                                                        kind_of(Numeric),
                                                        { tags: {}, short_stat: ".cache.read" })
    get "/"
  end
end
