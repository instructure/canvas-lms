require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "LoggingFilter" do
  describe "filter_uri" do
    it "should filter sensitive information from the url query string" do
      url = "https://www.instructure.example.com?access_token=abcdef"
      filtered_url = LoggingFilter.filter_uri(url)
      filtered_url.should == "https://www.instructure.example.com?access_token=[FILTERED]"
    end

    it "should filter all query params" do
      url = "https://www.instructure.example.com?access_token=abcdef&api_key=123"
      filtered_url = LoggingFilter.filter_uri(url)
      filtered_url.should == "https://www.instructure.example.com?access_token=[FILTERED]&api_key=[FILTERED]"
    end

    it "should not filter close matches" do
      url = "https://www.instructure.example.com?x_access_token=abcdef&api_key_x=123"
      filtered_url = LoggingFilter.filter_uri(url)
      filtered_url.should == url
    end
  end

  describe "filter_params" do
    it "should filter sensitive keys" do
      params = {
        :access_token => "abcdef",
        :api_key => 123
      }
      filtered_params = LoggingFilter.filter_params(params)
      filtered_params.should == {
        :access_token => "[FILTERED]",
        :api_key => "[FILTERED]"
      }
    end

    it "should filter string or symbol keys" do
      params = {
        :access_token => "abcdef",
        "api_key" => 123
      }
      filtered_params = LoggingFilter.filter_params(params)
      filtered_params.should == {
        :access_token => "[FILTERED]",
        "api_key" => "[FILTERED]"
      }
    end

    it "should filter keys of any case" do
      params = {
        "ApI_KeY" => 123
      }
      filtered_params = LoggingFilter.filter_params(params)
      filtered_params.should == {
        "ApI_KeY" => "[FILTERED]"
      }
    end
  end
end
