#
# Copyright (C) 2017 - present Instructure, Inc.
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
#

require 'spec_helper'

describe 'UpdateCustomParams' do
  def generic_lti_config(launch_url)
    <<-HEREDOC
    <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
      <blti:title>Tool</blti:title>
      <blti:description>A very handy tool.</blti:description>
      <blti:launch_url>#{launch_url}</blti:launch_url>
      <blti:extensions platform="canvas.instructure.com">
        <lticm:property name="privacy_level">public</lticm:property>
        <lticm:property name="tool_id">tool</lticm:property>
        <lticm:options name="course_navigation">
          <lticm:property name="url">#{launch_url}</lticm:property>
          <lticm:property name="text">Tool Name</lticm:property>
          <lticm:property name="visibility">members</lticm:property>
        </lticm:options>
      </blti:extensions>
    </cartridge_basiclti_link>
    HEREDOC
  end

  def create_tools(*urls)
    tools = {}
    urls.each do |url|
      launch_url = "https://#{url}/lti/launch"
      tools[url] = @course.context_external_tools.create!(:name => url,
                                                          :domain => url,
                                                          :url => launch_url,
                                                          :context => @course,
                                                          :config_type => 'by_xml',
                                                          :config_xml => generic_lti_config(launch_url),
                                                          :consumer_key => '12345',
                                                          :shared_secret => 'secret')
    end
    tools
  end

  def additional_custom_fields
    {
      "testing" => "success"
    }
  end

  before(:once) do
    course_model
    @root_account = @course.root_account
    @account = account_model(:root_account => @root_account, :parent_account => @root_account)
    @course.update!(account: @account)
    @to_process_url = 'tool.instructure.com'
    @unprocessed_url = 'some_other_tool.instructure.com'
    @subdomain_url = 'subdomain.tool.instructure.com'
    @tools = create_tools(@to_process_url, @unprocessed_url, @subdomain_url)
  end

  it 'should update specified LTI tools, and subdomains, to include new config variables' do
    tool = @tools[@to_process_url]
    expect(tool.url).to include(@to_process_url)
    expect(tool.custom_fields.keys).not_to include(*additional_custom_fields.keys)

    DataFixup::Lti::UpdateCustomParams.run!([@to_process_url], additional_custom_fields)

    expect(tool.reload.url).to include(@to_process_url)
    expect(tool.custom_fields.slice(*additional_custom_fields.keys)).to eq additional_custom_fields

    subdomain_tool = @tools[@subdomain_url]
    expect(subdomain_tool.reload.url).to include(@subdomain_url)
    expect(subdomain_tool.custom_fields.slice(*additional_custom_fields.keys)).to eq additional_custom_fields
  end

  it 'should not update subdomains w/o that option' do
    DataFixup::Lti::UpdateCustomParams.run!([@to_process_url], additional_custom_fields, subdomain_matching: false)

    subdomain_tool = @tools[@subdomain_url]
    expect(subdomain_tool.reload.url).to include(@subdomain_url)
    expect(subdomain_tool.custom_fields.slice(*additional_custom_fields.keys)).not_to eq additional_custom_fields
  end

  it 'should not update unrelated LTI tools' do
    tool = @tools[@unprocessed_url]
    expect(tool.url).to include(@unprocessed_url)
    expect(tool.reload.custom_fields.keys).not_to include(*additional_custom_fields.keys)

    DataFixup::Lti::UpdateCustomParams.run!([@to_process_url], additional_custom_fields)

    expect(tool.reload.url).to include(@unprocessed_url)
    expect(tool.reload.custom_fields.keys).not_to include(*additional_custom_fields.keys)
  end

  it 'should validate that valid domains are passed in' do
    strings = %w|api.quiz.docker/lti/launch jdoe.quiz-api-dev-pdx.inseng.net t.t2.quiz-lti-prod-iad.instructure.com|
    results = DataFixup::Lti::UpdateCustomParams.validate_domains!(strings)
    expect(results.size).to eq(2) # no /lti/launch
  end
end
