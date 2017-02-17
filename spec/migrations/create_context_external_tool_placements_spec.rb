require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20140806161233_create_context_external_tool_placements.rb'
require 'db/migrate/20140806162559_drop_has_columns_from_context_external_tools.rb'

describe 'CreateContextExternalToolPlacements' do
  describe "up" do
    it "should populate the context external tool placements table" do
      skip("PostgreSQL specific") unless ContentExport.connection.adapter_name == 'PostgreSQL'
      course_factory

      migration1 = CreateContextExternalToolPlacements.new
      migration2 = DropHasColumnsFromContextExternalTools.new

      tool1 = @course.context_external_tools.new(:name => 'blah', :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      tool1.settings = {:course_navigation => {:url => "http://www.example.com"}}
      tool1.save!
      expect(tool1.has_placement?(:course_navigation)).to eq true

      migration2.down
      migration1.down

      # make sure that the down undoes all the things
      ContextExternalTool.reset_column_information
      tool1_old = ContextExternalTool.find(tool1.id)
      expect(tool1_old.has_course_navigation).to eq true

      migration1.up
      migration2.up
      ContextExternalTool.reset_column_information
      tool1.reload
      expect(tool1.has_placement?(:course_navigation)).to eq true
      expect(tool1.has_placement?(:account_navigation)).to eq false
    end
  end
end
