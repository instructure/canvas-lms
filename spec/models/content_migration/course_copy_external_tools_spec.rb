require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy external tools" do
    include_examples "course copy"

    before :once do
      @tool_from = @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :custom_fields => {'a' => '1', 'b' => '2'}, :url => "http://www.example.com")
      @tool_from.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      @tool_from.save!
    end

    it "should copy external tools" do
      @copy_from.tab_configuration = [
        {"id" =>0 }, {"id" => "context_external_tool_#{@tool_from.id}"}, {"id" => 14}
      ]
      @copy_from.save!

      run_course_copy

      @copy_to.context_external_tools.count.should == 1
      tool_to = @copy_to.context_external_tools.first

      @copy_to.tab_configuration.should == [
          {"id" =>0 }, {"id" => "context_external_tool_#{tool_to.id}"}, {"id" => 14}
      ]

      tool_to.name.should == @tool_from.name
      tool_to.custom_fields.should == @tool_from.custom_fields
      tool_to.has_course_navigation.should == true
      tool_to.consumer_key.should == @tool_from.consumer_key
      tool_to.shared_secret.should == @tool_from.shared_secret
    end

    it "should not duplicate external tools used in modules" do
      mod1 = @copy_from.context_modules.create!(:name => "some module")
      tag = mod1.add_item({:type => 'context_external_tool',
                           :title => 'Example URL',
                           :url => "http://www.example.com",
                           :new_tab => true})
      tag.save

      run_course_copy

      @copy_to.context_external_tools.count.should == 1

      tool_to = @copy_to.context_external_tools.first
      tool_to.name.should == @tool_from.name
      tool_to.consumer_key.should == @tool_from.consumer_key
      tool_to.has_course_navigation.should == true
    end

    it "should copy external tool assignments" do
      assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'external_tool', :grading_type => 'points')
      tag_from = @assignment.build_external_tool_tag(:url => "http://example.com/one", :new_tab => true)
      tag_from.content_type = 'ContextExternalTool'
      tag_from.save!

      run_course_copy

      asmnt_2 = @copy_to.assignments.first
      asmnt_2.submission_types.should == "external_tool"
      asmnt_2.external_tool_tag.should_not be_nil
      tag_to = asmnt_2.external_tool_tag
      tag_to.content_type.should == tag_from.content_type
      tag_to.url.should == tag_from.url
      tag_to.new_tab.should == tag_from.new_tab
    end

    it "should copy vendor extensions" do
      @tool_from.settings[:vendor_extensions] = [{:platform=>"my.lms.com", :custom_fields=>{"key"=>"value"}}]
      @tool_from.save!

      run_course_copy

      tool = @copy_to.context_external_tools.find_by_migration_id(CC::CCHelper.create_key(@tool_from))
      tool.settings[:vendor_extensions].should == [{'platform'=>"my.lms.com", 'custom_fields'=>{"key"=>"value"}}]
    end

    it "should copy canvas extensions" do
      @tool_from.user_navigation = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :extra => 'extra', :custom_fields=>{"key"=>"value"}}
      @tool_from.course_navigation = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :default => 'disabled', :visibility => 'members', :extra => 'extra', :custom_fields=>{"key"=>"value"}}
      @tool_from.account_navigation = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :extra => 'extra', :custom_fields=>{"key"=>"value"}}
      @tool_from.resource_selection = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :selection_width => 100, :selection_height => 50, :extra => 'extra', :custom_fields=>{"key"=>"value"}}
      @tool_from.editor_button = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :selection_width => 100, :selection_height => 50, :icon_url => "http://www.example.com", :extra => 'extra', :custom_fields=>{"key"=>"value"}}
      @tool_from.save!

      run_course_copy

      tool = @copy_to.context_external_tools.find_by_migration_id(CC::CCHelper.create_key(@tool_from))
      tool.course_navigation.should_not be_nil
      tool.course_navigation.should == @tool_from.course_navigation
      tool.editor_button.should_not be_nil
      tool.editor_button.should == @tool_from.editor_button
      tool.resource_selection.should_not be_nil
      tool.resource_selection.should == @tool_from.resource_selection
      tool.account_navigation.should_not be_nil
      tool.account_navigation.should == @tool_from.account_navigation
      tool.user_navigation.should_not be_nil
      tool.user_navigation.should == @tool_from.user_navigation
    end

    it "should keep reference to ContextExternalTool by id for courses" do
      mod1 = @copy_from.context_modules.create!(:name => "some module")
      tag = mod1.add_item :type => 'context_external_tool', :id => @tool_from.id,
                    :url => "https://www.example.com/launch"
      run_course_copy

      tool_copy = @copy_to.context_external_tools.find_by_migration_id(CC::CCHelper.create_key(@tool_from))
      tag = @copy_to.context_modules.first.content_tags.first
      tag.content_type.should == 'ContextExternalTool'
      tag.content_id.should == tool_copy.id
    end

    it "should keep reference to ContextExternalTool by id for accounts" do
      account = @copy_from.root_account
      @tool_from.context = account
      @tool_from.save!
      mod1 = @copy_from.context_modules.create!(:name => "some module")
      mod1.add_item :type => 'context_external_tool', :id => @tool_from.id, :url => "https://www.example.com/launch"

      run_course_copy

      tag = @copy_to.context_modules.first.content_tags.first
      tag.content_type.should == 'ContextExternalTool'
      tag.content_id.should == @tool_from.id
    end

    it "should keep tab configuration for account-level external tools" do
      account = @copy_from.root_account
      @tool_from.context = account
      @tool_from.save!

      @copy_from.tab_configuration = [
          {"id" =>0 }, {"id" => "context_external_tool_#{@tool_from.id}"}, {"id" => 14}
      ]
      @copy_from.save!

      run_course_copy

      @copy_to.tab_configuration.should == [
          {"id" =>0 }, {"id" => "context_external_tool_#{@tool_from.id}"}, {"id" => 14}
      ]
    end
  end
end
