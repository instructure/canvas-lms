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
      expect(json['id']).to eq tool.id
      expect(json['name']).to eq tool.name
      expect(json['description']).to eq tool.description
      expect(json['url']).to eq tool.url
      expect(json['domain']).to eq tool.domain
      expect(json['consumer_key']).to eq tool.consumer_key
      expect(json['created_at']).to eq tool.created_at
      expect(json['updated_at']).to eq tool.updated_at
      expect(json['privacy_level']).to eq tool.privacy_level
      expect(json['custom_fields']).to eq tool.custom_fields
    end

    it "gets default extension settings" do
      json = controller.external_tool_json(tool, @course, @student, nil)
      expect(json['selection_width']).to eq tool.settings[:selection_width]
      expect(json['selection_height']).to eq tool.settings[:selection_height]
      expect(json['icon_url']).to eq tool.settings[:icon_url]
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
