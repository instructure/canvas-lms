require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20140806161233_create_context_external_tool_placements.rb'
require 'db/migrate/20140806162559_drop_has_columns_from_context_external_tools.rb'

describe 'CreateContextExternalToolPlacements' do
  describe "up" do
    it "should populate the context external tool placements table" do
      pending("PostgreSQL specific") unless ContentExport.connection.adapter_name == 'PostgreSQL'
      course

      migration1 = CreateContextExternalToolPlacements.new
      migration2 = DropHasColumnsFromContextExternalTools.new

      tool1 = @course.context_external_tools.new(:name => 'blah', :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      tool1.settings = {:course_navigation => {:url => "http://www.example.com"}}
      tool1.save!
      tool1.has_placement?(:course_navigation).should == true

      migration2.down
      migration1.down

      # make sure that the down undoes all the things
      ContextExternalTool.reset_column_information
      tool1_old = ContextExternalTool.find(tool1.id)
      tool1_old.has_course_navigation.should == true

      migration1.up

      # make sure the triggers work while they need to
      # on update to false
      ContextExternalTool.connection.execute("UPDATE context_external_tools SET has_course_navigation = 'f' WHERE id = #{tool1.id}")

      # on update to true
      ContextExternalTool.connection.execute("UPDATE context_external_tools SET has_account_navigation = 't' WHERE id = #{tool1.id}")
      # and on re-update to true
      ContextExternalTool.connection.execute("UPDATE context_external_tools SET has_account_navigation = 't' WHERE id = #{tool1.id}")

      # on insert
      ContextExternalTool.connection.execute("INSERT INTO context_external_tools(
        context_id, context_type, workflow_state, name, shared_secret, consumer_key, created_at, updated_at, has_user_navigation)
        VALUES(#{@course.id}, 'Course', 'active', '', '', '', '2014-07-07', '2014-07-07', 't')")

      migration2.up
      ContextExternalTool.reset_column_information
      tool1.reload
      tool1.has_placement?(:course_navigation).should == false
      tool1.has_placement?(:account_navigation).should == true

      tool2 = @course.context_external_tools.detect{|t| t.id != tool1.id}
      tool2.has_placement?(:user_navigation).should == true
    end
  end
end
