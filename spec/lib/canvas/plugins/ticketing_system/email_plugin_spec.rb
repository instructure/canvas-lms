require 'spec_helper'

module Canvas::Plugins::TicketingSystem
  describe EmailPlugin do
    describe "#export_error" do
      let(:ticketing){ stub() }
      let(:plugin){ EmailPlugin.new(ticketing) }
      let(:email_address){ "to-address@example.com" }
      let(:config){ {email_address: email_address} }
      let(:report){ stub(
        email: "from-address@example.com",
        to_document: {},
        raw_report: stub(),
        account_id: nil )
      }

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

      it "carries through the account if the error report has one" do
        raw_report = ErrorReport.new
        account = Account.create!
        raw_report.account = account
        wrapped_report = CustomError.new(raw_report)
        message = plugin.export_error(wrapped_report, config)
        expect(message.root_account).to eq(account)
      end

      it "sends valid json as the body, with http_env" do
        raw_report = ErrorReport.new
        raw_report.http_env = {
          "HTTP_ACCEPT"=>"application/json, text/javascript, application/json+canvas-string-ids, */*; q=0.01",
          "HTTP_ACCEPT_ENCODING"=>"gzip, deflate",
          "HTTP_HOST"=>"localhost:3000",
          "HTTP_REFERER"=>"http://localhost:3000/",
          "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36",
          "PATH_INFO"=>"/error_reports",
          "QUERY_STRING"=>"?",
          "REQUEST_METHOD"=>"POST",
          "REQUEST_PATH"=>"/error_reports",
          "REQUEST_URI"=>"http://localhost:3000/error_reports",
          "SERVER_NAME"=>"localhost",
          "SERVER_PORT"=>"3000",
          "SERVER_PROTOCOL"=>"HTTP/1.1",
          "REMOTE_ADDR"=>"127.0.0.1",
          "path_parameters"=>"{:action=>\"create\", :controller=>\"errors\"}",
          "query_parameters"=>"{}",
          "request_parameters"=>"{\"error\"=>{\"url\"=>\"http://localhost:3000/\", \"comments\"=>\"It just went to the dashboard\"}}"
        }
        wrapped_report = CustomError.new(raw_report)
        message = plugin.export_error(wrapped_report, config)
        expect { JSON.parse(message.body) }.not_to raise_error
      end
    end
  end
end
