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
    expect(exported_attachment.context).to eq @student
    expect(exported_attachment.folder.name).to eq "data exports"
    expect(exported_attachment.display_name.end_with?("data export.zip")).to be_truthy

    zipfile = Zip::File.open(exported_attachment.open)
    expect(zipfile.entries.count).to eq 3
    zipfile.entries.each do |entry|
      expect(entry.to_s.start_with?("#{exported_attachment.display_name[0..-5]}/#{@course.name}/#{assignment.name}/")).to be_truthy
    end

    urlfile = zipfile.entries.detect{|e| e.to_s.include?("submission_link")}
    expect(zipfile.read(urlfile).include?("<a href=\"#{sub3.url}\">#{sub3.url}</a>")).to be_truthy

    textfile = zipfile.entries.detect{|e| e.to_s.include?("submission_text")}
    expect(zipfile.read(textfile).include?(sub2.body)).to be_truthy

    expect(zipfile.entries.any?{|e| e.to_s.end_with?(file.filename)}).to be_truthy
  end
end
