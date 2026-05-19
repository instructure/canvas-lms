# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe "config/initializers/outgoing_mail.rb" do
  let(:initializer_path) { Rails.root.join("config/initializers/outgoing_mail.rb").to_s }
  let(:expected_keys) { %w[smtp.yml reply_to delivery_method reply_to_disabled] }

  before do
    @saved_smtp = ActionMailer::Base.smtp_settings.dup
    @saved_delivery_method = ActionMailer::Base.delivery_method
  end

  after do
    ActionMailer::Base.smtp_settings.replace(@saved_smtp)
    ActionMailer::Base.delivery_method = @saved_delivery_method
  end

  it "uses the local config/outgoing_mail.yml when present and skips Consul" do
    expect(ConfigFile).to receive(:load).with("outgoing_mail")
                                        .and_return({ "delivery_method" => "test" })
    expect(Canvas).not_to receive(:load_consul_subtree)

    load initializer_path

    expect(ActionMailer::Base.delivery_method).to eq :test
  end

  context "when no local YAML is present" do
    before do
      allow(ConfigFile).to receive(:load).with("outgoing_mail").and_return(nil)
    end

    it "loads settings from the outgoing_mail Consul subtree" do
      expect(Canvas).to receive(:load_consul_subtree)
        .with("outgoing_mail", keys: expected_keys)
        .and_return(smtp: { "address" => "smtp.test", "port" => 25, "domain" => "example.com" },
                    reply_to: "reply@example.com",
                    delivery_method: "smtp",
                    reply_to_disabled: nil)

      load initializer_path

      expect(ActionMailer::Base.smtp_settings[:address]).to eq "smtp.test"
      expect(ActionMailer::Base.smtp_settings[:domain]).to eq "example.com"
      expect(ActionMailer::Base.delivery_method).to eq :smtp
    end

    it "maps a 'test' delivery_method to :test and disables deliveries" do
      allow(Canvas).to receive(:load_consul_subtree).and_return(
        smtp: { "address" => "localhost", "port" => 25 },
        reply_to: nil,
        delivery_method: "test",
        reply_to_disabled: nil
      )

      load initializer_path

      expect(ActionMailer::Base.delivery_method).to eq :test
      expect(ActionMailer::Base.perform_deliveries).to be false
    end

    it "uses hardcoded defaults when the subtree is empty" do
      allow(Canvas).to receive(:load_consul_subtree).and_return(
        smtp: nil, reply_to: nil, delivery_method: nil, reply_to_disabled: nil
      )

      load initializer_path

      expect(ActionMailer::Base.smtp_settings[:domain]).to eq "unknowndomain.example.com"
      expect(ActionMailer::Base.delivery_method).to eq :smtp
    end
  end
end
