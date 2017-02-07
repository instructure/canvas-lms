# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/cc_spec_helper')

require 'nokogiri'

describe CC::BasicLTILinks do
  subject { (Class.new { include CC::BasicLTILinks }).new }

  let (:tool) do
    ContextExternalTool.new
  end

  before do
    subject.stubs(:for_course_copy).returns false
  end

  describe "#create_blti_link" do

    let(:lti_doc) { Builder::XmlMarkup.new(target: xml, indent: 2) }
    #this is the target for Builder::XmlMarkup. this is how you access the generated XML
    let(:xml) { '' }

    it "sets the encoding to 'UTF-8'" do
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.encoding).to eq 'UTF-8'
    end

    it "sets the version to '1.0'" do
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.version).to eq '1.0'
    end

    it "sets the namespaces correctly" do
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.namespaces).to eq({
                                         "xmlns" => "http://www.imsglobal.org/xsd/imslticc_v1p0",
                                         "xmlns:blti" => "http://www.imsglobal.org/xsd/imsbasiclti_v1p0",
                                         "xmlns:lticm" => "http://www.imsglobal.org/xsd/imslticm_v1p0",
                                         "xmlns:lticp" => "http://www.imsglobal.org/xsd/imslticp_v1p0",
                                         "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                                       })
    end

    it "sets the title from the tool name" do
      tool.name = "My Test Tool"
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.at_xpath("//blti:title").text).to eq tool.name
    end

    it "sets the description from the tool description" do
      tool.description = "This is a test tool, that doesn't work"
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.at_xpath("//blti:description").text).to eq tool.description
    end

    it "sets a launch_url if the url uses the http scheme" do
      tool.url = "http://example.com/launch"
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.at_xpath("//blti:launch_url").text).to eq tool.url
    end

    it "sets a secure_launch_url if the url uses the https scheme" do
      tool.url = "https://example.com/launch"
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.at_xpath("//blti:secure_launch_url").text).to eq tool.url
    end

    it "add an icon element if found in the tool settings" do
      tool.settings[:icon_url] = "http://example.com/icon"
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.at_xpath("//blti:icon").text).to eq tool.settings[:icon_url]
    end

    it "sets the vendor code to 'unknown'" do
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.at_xpath("//blti:vendor/lticp:code").text).to eq 'unknown'
    end

    it "sets the vendor name to 'unknown'" do
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      expect(xml_doc.at_xpath("//blti:vendor/lticp:name").text).to eq 'unknown'
    end

    it "adds custom fields" do
      tool.settings[:custom_fields] = {
        "custom_key_name_1" => "custom_key_1",
        "custom_key_name_2" => "custom_key_2"
      }
      subject.create_blti_link(tool, lti_doc)
      xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
      parsed_custom_fields = xml_doc.xpath("//blti:custom/lticm:property").each_with_object({}) do |x, h|
        h[x.attribute("name").text] = x.text
      end
      expect(parsed_custom_fields).to eq tool.settings[:custom_fields]
    end

    context "extensions" do

      it "creates an extensions node" do
        subject.create_blti_link(tool, lti_doc)
        xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
        expect(xml_doc.at_xpath("//blti:extensions/@platform").text).to eq CC::CCHelper::CANVAS_PLATFORM
      end

      it "adds the tool_id if one is present" do
        tool.tool_id = "42"
        subject.create_blti_link(tool, lti_doc)
        xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
        expect(xml_doc.at_xpath('//blti:extensions/lticm:property[@name="tool_id"]').text).to eq tool.tool_id
      end

      it "adds the privacy level if there is a workflow_state on the tool" do
        tool.workflow_state = "email_only"
        subject.create_blti_link(tool, lti_doc)
        xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
        expect(xml_doc.at_xpath('//blti:extensions/lticm:property[@name="privacy_level"]').text).to eq tool.workflow_state
      end

      it "adds the domain if set" do
        tool.domain = "instructure.com"
        subject.create_blti_link(tool, lti_doc)
        xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
        expect(xml_doc.at_xpath('//blti:extensions/lticm:property[@name="domain"]').text).to eq tool.domain
      end

      it "adds the selection_width if set" do
        tool.settings[:selection_width] = "100"
        subject.create_blti_link(tool, lti_doc)
        xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
        expect(xml_doc.at_xpath('//blti:extensions/lticm:property[@name="selection_width"]').text).to eq tool.settings[:selection_width]
      end

      it "adds the selection_height if set" do
        tool.settings[:selection_height] = "150"
        subject.create_blti_link(tool, lti_doc)
        xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
        expect(xml_doc.at_xpath('//blti:extensions/lticm:property[@name="selection_height"]').text).to eq tool.settings[:selection_height]
      end

      it "adds non placment extensions" do
        tool.settings[:post_only] = "true"
        subject.create_blti_link(tool, lti_doc)
        xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
        expect(xml_doc.at_xpath('//blti:extensions/lticm:property[@name="post_only"]').text).to eq 'true'
      end

      it "doesn't add non placement extensions if their value is a collection" do
        tool.settings[:my_list] = [1,2,3]
        subject.create_blti_link(tool, lti_doc)
        xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
        expect(xml_doc.at_xpath('//blti:extensions/lticm:property[@name="my_list"]')).to be_nil
      end

      context "course_copy" do
        before do
          subject.stubs(:for_course_copy).returns true
        end

        it "sets the consumer_key if it's a course copy" do
          tool.consumer_key = "consumer_key"
          subject.create_blti_link(tool, lti_doc)
          xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
          expect(xml_doc.at_xpath('//blti:extensions/lticm:property[@name="consumer_key"]').text).to eq tool.consumer_key
        end

        it "sets the shared_secret if it's a course copy" do
          tool.shared_secret = "shared_secret"
          subject.create_blti_link(tool, lti_doc)
          xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
          expect(xml_doc.at_xpath('//blti:extensions/lticm:property[@name="shared_secret"]').text).to eq tool.shared_secret
        end
      end

      context "Placements" do
        it "adds the placement node if it exists" do
          tool.settings[:course_navigation] = {}
          subject.create_blti_link(tool, lti_doc)
          xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
          xpath = '//blti:extensions/lticm:options[@name="course_navigation"]/@name'
          expect(xml_doc.at_xpath(xpath).text).to eq "course_navigation"
        end

        it "adds settings for placements" do
          tool.settings[:course_navigation] = {custom_setting: "foo"}
          subject.create_blti_link(tool, lti_doc)
          xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
          xpath = '//blti:extensions/lticm:options[@name="course_navigation"]/lticm:property[@name="custom_setting"]'
          expect(xml_doc.at_xpath(xpath).text).to eq "foo"
        end

        it "adds labels correctly" do
          labels = {en_US: "My Label"}
          tool.settings[:course_navigation] = {labels: labels}
          subject.create_blti_link(tool, lti_doc)
          xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
          xpath = '//blti:extensions/lticm:options[@name="course_navigation"]/lticm:options[@name="labels"]/lticm:property[@name="en_US"]'
          expect(xml_doc.at_xpath(xpath).text).to eq labels[:en_US]
        end

        it "adds custom_fields" do
          custom_fields = {
            "custom_key_name_1" => "custom_key_1",
            "custom_key_name_2" => "custom_key_2"
          }
          tool.settings[:course_navigation] = {custom_fields: custom_fields}
          subject.create_blti_link(tool, lti_doc)
          xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
          xpath = '//blti:extensions/lticm:options[@name="course_navigation"]/blti:custom/lticm:property'
          parsed_custom_fields = xml_doc.xpath(xpath).each_with_object({}) { |x, h| h[x.attribute("name").text] = x.text }
          expect(parsed_custom_fields).to eq custom_fields
        end
      end

      context "vendor extensions" do
        it "adds vendor extensions" do
          tool.settings[:vendor_extensions] = [{platform: "my vendor platform", custom_fields:{}}]
          subject.create_blti_link(tool, lti_doc)
          xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
          expect(xml_doc.at_xpath('//blti:extensions[@platform="my vendor platform"]/@platform').text).to eq "my vendor platform"
        end

        it "adds custom fields" do
          custom_fields = {
            "custom_key_name_1" => "custom_key_1",
            "custom_key_name_2" => "custom_key_2"
          }
          tool.settings[:vendor_extensions] = [{platform: "my vendor platform", custom_fields:custom_fields}]
          subject.create_blti_link(tool, lti_doc)
          xml_doc = Nokogiri::XML(xml) { |c| c.nonet.strict }
          xpath = '//blti:extensions[@platform="my vendor platform"]/lticm:property'
          parsed_custom_fields = xml_doc.xpath(xpath).each_with_object({}) { |x, h| h[x.attribute("name").text] = x.text }
          expect(parsed_custom_fields).to eq custom_fields
        end

      end

    end
  end
end
