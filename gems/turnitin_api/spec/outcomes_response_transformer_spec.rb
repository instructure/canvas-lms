require 'spec_helper'

describe TurnitinApi::OutcomesResponseTransformer do
  let(:oauth_key) { 'key' }
  let(:oauth_secret) { 'secret' }
  let(:lti_params) { {lti_verions: '1p0'} }
  let(:outcomes_response_json) do
    {
        'lis_result_sourcedid' => "6",
        'paperid' => "7",
        'outcomes_tool_placement_url' => "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321"
    }
  end
  subject { described_class.new(oauth_key, oauth_secret, lti_params, outcomes_response_json) }

  describe 'initialize' do

    it 'initializes properly' do
      expect(subject.key).to eq oauth_key
      expect(subject.lti_params). to eq lti_params
      expect(subject.outcomes_response_json).to eq outcomes_response_json
    end
  end

  describe 'response' do
    before(:each) do
      stub_request(:post, "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321").
          to_return(:status => 200, :body => fixture('outcome_detailed_response.json'), :headers => {'Content-Type' => 'application/json'})
    end

    it 'returns expected json response' do
      expect(subject.response.body["outcome_originalfile"]["launch_url"]).to eq "https://turnitin.com/api/lti/1p0/dow...72874634?lang="
    end

  end

  describe 'original_submission' do
    before(:each) do
      stub_request(:post, "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321").
          to_return(:status => 200, :body => fixture('outcome_detailed_response.json'), :headers => {'Content-Type' => 'application/json'})

      stub_request(:post, "https://turnitin.com/api/lti/1p0/dow...72874634?lang=").
          to_return(:status => 200, :body => "I am an awesome text file", :headers => {'Content-Type' => 'text/plain', 'Content-Disposition' => 'attachment; filename="myfile.txt"'})

    end

    it 'returns a File' do
      subject.original_submission do |response|
        expect(response.body).to eq "I am an awesome text file"
      end
    end

  end

  describe 'originality report' do
    before(:each) do
      stub_request(:post, "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321").
          to_return(:status => 200, :body => fixture('outcome_detailed_response.json'), :headers => {'Content-Type' => 'application/json'})

    end

    it 'returns a url' do
      expect(subject.originality_report_url).to eq "https://turnitin.com/api/lti/1p0/dv/...72874634?lang="
    end

  end


  describe 'originality data' do
    before(:each) do
      stub_request(:post, "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321").
          to_return(:status => 200, :body => fixture('outcome_detailed_response.json'), :headers => {'Content-Type' => 'application/json'})

    end

    it 'returns proper keys' do
      expect(subject.originality_data['breakdown']).to_not be_nil
      expect(subject.originality_data['numeric']).to_not be_nil
    end

    it 'breakdown is set correctly' do
      expect(subject.originality_data['breakdown']['submitted_works_score']).to eq 100
      expect(subject.originality_data['breakdown']['publications_score']).to eq 0
      expect(subject.originality_data['breakdown']['internet_score']).to eq 0
    end

    it 'numeric is set correctly' do
      expect(subject.originality_data['numeric']['max']).to eq 100
      expect(subject.originality_data['numeric']['score']).to eq 100
    end
  end
end
