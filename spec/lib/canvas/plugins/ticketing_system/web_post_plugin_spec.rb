require 'spec_helper'

module Canvas::Plugins::TicketingSystem
  describe WebPostPlugin do
    describe "#export_error" do
      it "posts the error_report document to the configured endpoint" do
        ticketing = stub()
        document = {key: "value", info: "data"}
        report = stub(to_document: document)
        endpoint = "http://someserver.com/some/endpoint"
        config = {endpoint_uri: endpoint}
        plugin = WebPostPlugin.new(ticketing)
        HTTParty.expects(:post).with(endpoint, has_entry(body: document.to_json))
        plugin.export_error(report, config)
      end
    end
  end
end
