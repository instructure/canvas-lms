require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Importers::ContextExternalToolImporter do
  it "should work for course-level tools" do
    course_model
    tool = Importers::ContextExternalToolImporter.import_from_migration({:title => 'tool', :url => 'http://example.com'}, @course)
    tool.should_not be_nil
    tool.context.should == @course
  end

  it "should work for account-level tools" do
    course_model
    tool = Importers::ContextExternalToolImporter.import_from_migration({:title => 'tool', :url => 'http://example.com'}, @course.account)
    tool.should_not be_nil
    tool.context.should == @course.account
  end
end