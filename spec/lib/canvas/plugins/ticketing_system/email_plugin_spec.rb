require 'spec_helper'

module Canvas::Plugins::TicketingSystem
  describe EmailPlugin do
    describe "#export_error" do
      let(:ticketing){ stub() }
      let(:plugin){ EmailPlugin.new(ticketing) }
      let(:email_address){ "to-address@example.com" }
      let(:config){ {email_address: email_address} }
      let(:report){ stub(email: "from-address@example.com", to_document: {}, raw_report: stub()) }

      it "sends an email to the address in the configuration" do
        Message.expects(:create!).with(has_entry(to: email_address))
        plugin.export_error(report, config)
      end

      it "uses the email from the error_report as the from address" do
        Message.expects(:create!).with(has_entry(from: report.email))
        plugin.export_error(report, config)
      end

      it "uses the un-wrapped error-report for the mail context" do
        raw_report = ErrorReport.new
        wrapped_report = CustomError.new(raw_report)
        Message.expects(:create!).with(has_entry(context: raw_report))
        plugin.export_error(wrapped_report, config)
      end
    end
  end
end

