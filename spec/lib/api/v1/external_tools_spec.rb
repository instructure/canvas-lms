require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

class ExternalToolTestController
  include Api::V1::ExternalTools
end

describe Api::V1::ExternalTools do
  let(:controller) {ExternalToolTestController.new}

  describe "#external_tool_json" do
    before(:each) do
      course_with_student_logged_in
    end

    let(:tool) do
      params = {:name => "a", :url => 'www.google.com/tool_launch', :domain => "google.com", :consumer_key => '12345',
                :shared_secret => 'secret', :privacy_level => 'public'}
      tool = @course.context_external_tools.new(params)
      tool.settings = {:selection_width => 1234, :selection_height => 99, :icon_url => 'www.google.com/icon'}
      tool.save
      tool
    end

    it "generates json" do
      json = controller.external_tool_json(tool, @course, @student, nil)
      json['id'].should == tool.id
      json['name'].should == tool.name
      json['description'].should == tool.description
      json['url'].should == tool.url
      json['domain'].should == tool.domain
      json['consumer_key'].should == tool.consumer_key
      json['created_at'].should == tool.created_at
      json['updated_at'].should == tool.updated_at
      json['privacy_level'].should == tool.privacy_level
      json['custom_fields'].should == tool.custom_fields
    end

    it "gets default extension settings" do
      json = controller.external_tool_json(tool, @course, @student, nil)
      json['selection_width'].should == tool.settings[:selection_width]
      json['selection_height'].should == tool.settings[:selection_height]
      json['icon_url'].should == tool.settings[:icon_url]
    end

    it "gets extension labels" do
      tool.homework_submission = {:label => {'en' => 'Hi'}}
      tool.save
      @student.locale = 'en'
      @student.save
      json = controller.external_tool_json(tool, @course, @student, nil)
      json['homework_submission']['label'] = 'Hi'
    end
  end
end
