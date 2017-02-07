require 'spec_helper'

describe Twitter::Messenger do
  let(:message) { double() }
  let(:twitter_service) { double({
                                 token: "twitter_token",
                                 secret: "twitter_secret",
                                 service_user_name: "twitter_name",
                                 service_user_id: "twitter_id"
                               }) }
  let(:id) { "ABC123" }
  let(:messenger) { Twitter::Messenger.new(message, twitter_service, 'host', id) }

  describe '#deliver' do

    let(:user) { double(:user_services) }
    let(:message) { double(:body => 'body', :url => 'url', :user => user, :asset_context => nil, :id => 0, :main_link => '') }
    let(:connection_mock) { double() }


    context "with a twitter service" do
      before(:each) do
        expect(Twitter::Connection).to receive(:from_service_token).with("twitter_token", "twitter_secret").and_return(connection_mock)
      end

      it 'delegates to the twitter module if a service is available' do
        expect(connection_mock).to receive(:send_direct_message).with("twitter_name", "twitter_id", "body ").and_return(true)
        expect(messenger.deliver).to be_truthy
      end
    end

    context "with no twitter service" do
      let(:messenger) { Twitter::Messenger.new(message, nil, 'host', id) }
      it 'sends nothing if there is no service' do
        expect(connection_mock).to receive(:send_direct_message).never
        expect(messenger.deliver).to be_nil
      end
    end
  end

  describe '#url' do
    let(:message) { double(:id => 42, :asset_context => nil, :main_link => nil, :url => nil) }
    subject { messenger.url }

    it { is_expected.to match(/host/) }
    it { is_expected.to match(/#{id}$/) }
    it { is_expected.to match(/^http:\/\//) }
  end

  describe '#body' do
    let(:message) { double(:body => @body, :asset_context => nil, :id => 0, :main_link => @link) }

    it 'leaves the body intact when it does not overrun the twitter length limit' do
      @body = "no need to alter"
      @link = 'http://learn.canvas.net/example'
      expect(messenger.body).to eq("#{@body} #{@link}")
    end

    it 'trims down the body to fit into a twitter message with the url' do
      @body = "An extremely long body that might need to be cut down a bit if we have any hope of letting twitter have it due to the length limits that service imposes"
      @link = 'http://learn.canvas.net/super/long/url/which/will/be/minified/by/twitter'
      expect(messenger.body).to eq("An extremely long body that might need to be cut down a bit if w... http://learn.canvas.net/super/long/url/which/will/be/minified/by/twitter")
    end
  end
end
