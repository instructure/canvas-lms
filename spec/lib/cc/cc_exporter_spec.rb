require File.dirname(__FILE__) + '/cc_spec_helper'

describe "Common Cartridge exporting" do
  it "should collect errors and finish running" do
    course = course_model
    user = user_model
    message = "fail"
    course.stubs(:wiki).raises(message)
    content_export = ContentExport.new
    content_export.course = course
    content_export.user = user
    content_export.save!
    
    content_export.export_course_without_send_later
    
    content_export.error_messages.length.should == 1
    error = content_export.error_messages.first
    error.first.should == "Failed to export wiki pages"
    error.last.should =~ /ErrorReport id: \d*/
    ErrorReport.count.should == 1
    ErrorReport.last.message.should == message 
  end
end
