require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "User data exports" do
  it "should export student submissions" do
    course_with_student(:active_all => true)
    @course.name = "some silly course"
    @course.save!
    assignment = @course.assignments.create!(:name => "assignmentname")
    assignment.submission_types = "online_text_entry,online_url,online_upload"
    assignment.save!

    file = Attachment.create!(:uploaded_data => StringIO.new('blah'),
                              :context => @course, :filename => 'blah.txt')
    sub1 = assignment.submit_homework(@student, :attachments => [file], :submission_type => "online_upload")
    sub2 = assignment.submit_homework(@student, :body => "blahblahblah text entry", :submission_type => "online_text_entry")
    sub3 = assignment.submit_homework(@student, :url => "http://reddit.com/r/mylittlepony", :submission_type => "online_url")

    exported_attachment = Exporters::UserDataExporter.create_user_data_export(@student)
    exported_attachment.context.should == @student
    exported_attachment.folder.name.should == "data exports"
    exported_attachment.display_name.end_with?("data export.zip").should be_true

    zipfile = Zip::File.open(exported_attachment.open)
    zipfile.entries.count.should == 3
    zipfile.entries.each do |entry|
      entry.to_s.start_with?("#{exported_attachment.display_name[0..-5]}/#{@course.name}/#{assignment.name}/").should be_true
    end

    urlfile = zipfile.entries.detect{|e| e.to_s.include?("submission_link")}
    zipfile.read(urlfile).include?("<a href=\"#{sub3.url}\">#{sub3.url}</a>").should be_true

    textfile = zipfile.entries.detect{|e| e.to_s.include?("submission_text")}
    zipfile.read(textfile).include?(sub2.body).should be_true

    zipfile.entries.any?{|e| e.to_s.end_with?(file.filename)}.should be_true
  end
end