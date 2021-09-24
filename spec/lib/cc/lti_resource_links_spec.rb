# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/cc_spec_helper')

require 'nokogiri'

describe CC::LtiResourceLinks do
  include CC::LtiResourceLinks

  let(:resource_link) do
    Lti::ResourceLink.create!(
      context: tool.context,
      context_external_tool: tool,
      custom: custom
    )
  end

  let(:tool) do
    external_tool_model(
      opts: {
        use_1_3: true,
        description: 'test tool',
        url: url
      }
    )
  end

  let(:url) { 'https://www.test-tool.com/launch' }
  let(:custom) { { foo: 'bar', fiz: 'buzz' } }
  let(:document) { Builder::XmlMarkup.new(target: xml, indent: 2) }
  let(:xml) { +'' }

  describe '#add_lti_resource_link' do
    subject do
      add_lti_resource_link(
        resource_link,
        tool,
        document
      )
      Nokogiri::XML(xml) { |c| c.nonet.strict }
    end

    it 'sets the correct namespace' do
      expect(subject.namespaces).to eq({
        'xmlns' => 'http://www.imsglobal.org/xsd/imslticc_v1p3',
        'xmlns:blti' => 'http://www.imsglobal.org/xsd/imsbasiclti_v1p0',
        'xmlns:lticm' => 'http://www.imsglobal.org/xsd/imslticm_v1p0',
        'xmlns:lticp' => 'http://www.imsglobal.org/xsd/imslticp_v1p0',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
      })
    end

    it 'sets the title' do
      expect(subject.at_xpath("//blti:title").text).to eq tool.name
    end

    it 'sets the description' do
      expect(subject.at_xpath("//blti:description").text).to eq tool.description
    end

    it 'sets the secure launch url' do
      expect(subject.at_xpath("//blti:secure_launch_url").text).to eq tool.url
    end

    it 'does not set the launch url' do
      expect(subject.at_xpath("//blti:launch_url")).to be_blank
    end

    it 'sets the custom params' do
      expect(
        subject.xpath("//blti:custom/lticm:property").each_with_object({}) do |el, h|
          h[el.attribute('name').text] = el.text
        end
      ).to eq(custom.stringify_keys)
    end

    context 'when the tool URL uses HTTP' do
      let(:url) { 'http://www.test-tool.com/launch' }

      it 'does set the launch url' do
        expect(subject.at_xpath("//blti:launch_url").text).to eq tool.url
      end

      it 'does not set the secure launch url' do
        expect(subject.at_xpath("//blti:secure_launch_url")).to be_blank
      end
    end
  end
end