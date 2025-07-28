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

require_relative "cc_spec_helper"

require "nokogiri"

describe CC::LtiResourceLinks do
  include CC::LtiResourceLinks

  let(:resource_link) do
    Lti::ResourceLink.create!(
      context: tool.context,
      lookup_uuid:,
      context_external_tool: tool,
      custom:,
      url: resource_link_url
    )
  end

  let(:tool) do
    external_tool_model(
      opts: {
        use_1_3: true,
        description: "test tool",
        url: tool_url
      }
    )
  end

  let(:lookup_uuid) { "90cfe684-0f4f-11ed-861d-0242ac120002" }
  let(:tool_url) { "https://www.test-tool.com/launch" }
  let(:resource_link_url) { "https://www.test-tool.com/launch?foo=bar" }
  let(:custom) { { foo: "bar", fiz: "buzz" } }
  let(:document) { Builder::XmlMarkup.new(target: xml, indent: 2) }
  let(:xml) { +"" }

  describe "#add_lti_resource_link" do
    subject do
      add_lti_resource_link(
        resource_link,
        tool,
        document
      )
      Nokogiri::XML(xml) { |c| c.nonet.strict }
    end

    it "sets the correct namespace" do
      expect(subject.namespaces).to eq({
                                         "xmlns" => "http://www.imsglobal.org/xsd/imslticc_v1p3",
                                         "xmlns:blti" => "http://www.imsglobal.org/xsd/imsbasiclti_v1p0",
                                         "xmlns:lticm" => "http://www.imsglobal.org/xsd/imslticm_v1p0",
                                         "xmlns:lticp" => "http://www.imsglobal.org/xsd/imslticp_v1p0",
                                         "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
                                       })
    end

    it "sets the title" do
      expect(subject.at_xpath("//blti:title").text).to eq tool.name
    end

    it "sets the description" do
      expect(subject.at_xpath("//blti:description").text).to eq tool.description
    end

    it "sets the secure launch url" do
      expect(subject.at_xpath("//blti:secure_launch_url").text).to eq tool_url
    end

    it "does not set the launch url" do
      expect(subject.at_xpath("//blti:launch_url")).to be_blank
    end

    it "sets the custom params" do
      expect(
        subject.xpath("//blti:custom/lticm:property").each_with_object({}) do |el, h|
          h[el.attribute("name").text] = el.text
        end
      ).to eq(custom.stringify_keys)
    end

    context "when the tool URL uses HTTP" do
      let(:tool_url) { "http://www.test-tool.com/launch?foo=bar" }

      it "does set the launch url" do
        expect(subject.at_xpath("//blti:launch_url").text).to eq tool_url
      end

      it "does not set the secure launch url" do
        expect(subject.at_xpath("//blti:secure_launch_url")).to be_blank
      end
    end

    def find_extension(document, extension_name)
      (document.xpath("//blti:extensions/lticm:property").map do |el|
        if el.attribute("name").text == extension_name
          el.text
        end
      end).compact.first
    end

    context "when the resource link URL is nil" do
      let(:resource_link_url) { nil }

      it "does not include the resource_link_url property" do
        expect(find_extension(subject, "resource_link_url")).to be_nil
      end
    end

    context "when the resource link URL is populated" do
      it "includes the resource_link_url extension property" do
        expect(find_extension(subject, "resource_link_url")).to eq resource_link_url
      end
    end

    context "when the lookup uuid is populated" do
      it "includes the lookup_uuid extension property" do
        expect(find_extension(subject, "lookup_uuid")).to eq lookup_uuid
      end
    end
  end
end
