=begin
VeriCiteV1
=end

require 'spec_helper'
require 'json'

describe 'DefaultApi' do
  before do
    # run before each test
    @instance = VeriCiteClient::DefaultApi.new
  end

  after do
    # run after each test
  end

  describe 'test an instance of DefaultApi' do
    it 'should create an instact of DefaultApi' do
      @instance.should be_a(VeriCiteClient::DefaultApi)
    end
  end

  
  # unit tests for assignments_context_id_assignment_id_post
  # 
  # Create/update assignment
  # @param context_id Context ID
  # @param assignment_id ID of assignment
  # @param consumer the consumer
  # @param consumer_secret the consumer secret
  # @param assignment_data 
  # @param [Hash] opts the optional parameters
  # @return [Array<ExternalContentUploadInfo>]
  describe 'assignments_context_id_assignment_id_post test' do
    it "should work" do
      # assertion here
      # should be_a()
      # should be_nil
      # should ==
      # should_not ==
    end
  end

  # unit tests for reports_scores_context_id_get
  # 
  # Retrieves scores for the reports
  # @param context_id Context ID
  # @param consumer the consumer
  # @param consumer_secret the consumer secret
  # @param [Hash] opts the optional parameters
  # @option opts [String] :assignment_id ID of assignment
  # @option opts [String] :user_id ID of user
  # @option opts [String] :external_content_id external content id
  # @return [Array<ReportScoreReponse>]
  describe 'reports_scores_context_id_get test' do
    it "should work" do
      # assertion here
      # should be_a()
      # should be_nil
      # should ==
      # should_not ==
    end
  end

  # unit tests for reports_submit_request_context_id_assignment_id_user_id_post
  # 
  # Request a file submission
  # @param context_id Context ID
  # @param assignment_id ID of assignment
  # @param user_id ID of user
  # @param consumer the consumer
  # @param consumer_secret the consumer secret
  # @param report_meta_data 
  # @param [Hash] opts the optional parameters
  # @return [Array<ExternalContentUploadInfo>]
  describe 'reports_submit_request_context_id_assignment_id_user_id_post test' do
    it "should work" do
      # assertion here
      # should be_a()
      # should be_nil
      # should ==
      # should_not ==
    end
  end

  # unit tests for reports_urls_context_id_get
  # 
  # Retrieves URLS for the reports
  # @param context_id Context ID
  # @param assignment_id_filter ID of assignment to filter results on
  # @param consumer the consumer
  # @param consumer_secret the consumer secret
  # @param token_user ID of user who will view the report
  # @param token_user_role role of user who will view the report
  # @param [Hash] opts the optional parameters
  # @option opts [String] :user_id_filter ID of user to filter results on
  # @option opts [String] :external_content_id_filter external content id to filter results on
  # @return [Array<ReportURLLinkReponse>]
  describe 'reports_urls_context_id_get test' do
    it "should work" do
      # assertion here
      # should be_a()
      # should be_nil
      # should ==
      # should_not ==
    end
  end

end
