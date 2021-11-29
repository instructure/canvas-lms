# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe "LoggingFilter" do
  describe "filter_uri" do
    it "filters sensitive information from the url query string" do
      url = "https://www.instructure.example.com?access_token=abcdef"
      filtered_url = LoggingFilter.filter_uri(url)
      expect(filtered_url).to eq "https://www.instructure.example.com?access_token=[FILTERED]"
    end

    it "filters all query params" do
      url = "https://www.instructure.example.com?access_token=abcdef&api_key=123"
      filtered_url = LoggingFilter.filter_uri(url)
      expect(filtered_url).to eq "https://www.instructure.example.com?access_token=[FILTERED]&api_key=[FILTERED]"
    end

    it "does not filter close matches" do
      url = "https://www.instructure.example.com?x_access_token=abcdef&api_key_x=123"
      filtered_url = LoggingFilter.filter_uri(url)
      expect(filtered_url).to eq url
    end
  end

  describe "filter_params" do
    it "filters sensitive keys" do
      params = {
        access_token: "abcdef",
        api_key: 123
      }
      filtered_params = LoggingFilter.filter_params(params)
      expect(filtered_params).to eq({
                                      access_token: "[FILTERED]",
                                      api_key: "[FILTERED]"
                                    })
    end

    it "filters string or symbol keys" do
      params = {
        :access_token => "abcdef",
        "api_key" => 123
      }
      filtered_params = LoggingFilter.filter_params(params)
      expect(filtered_params).to eq({
                                      :access_token => "[FILTERED]",
                                      "api_key" => "[FILTERED]"
                                    })
    end

    it "filters keys of any case" do
      params = {
        "ApI_KeY" => 123
      }
      filtered_params = LoggingFilter.filter_params(params)
      expect(filtered_params).to eq({
                                      "ApI_KeY" => "[FILTERED]"
                                    })
    end

    it "filters nested keys in string format" do
      params = {
        "pseudonym_session[password]" => 123
      }
      filtered_params = LoggingFilter.filter_params(params)
      expect(filtered_params).to eq({
                                      "pseudonym_session[password]" => "[FILTERED]"
                                    })
    end

    it "filters ested keys in hash format" do
      params = {
        pseudonym_session: {
          password: 123
        }
      }
      filtered_params = LoggingFilter.filter_params(params)
      expect(filtered_params).to eq({
                                      pseudonym_session: {
                                        password: "[FILTERED]"
                                      }
                                    })
    end
  end
end
