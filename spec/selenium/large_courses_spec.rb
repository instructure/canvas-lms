require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/content_migrations_spec')

describe "large courses", :priority => "2" do
  it_should_behave_like "in-process server selenium tests"

  def assignments_creation
      500.times do |i|
        @course.assignments.create!(:name => "assignment_#{i}")
      end
  end

  before (:each) do
    course_with_admin_logged_in
    assignments_creation
  end

  context "migrations" do
    it "should copy the course" do
      get "/courses/#{@course.id}/copy"
      expect_new_page_load { f('button[type="submit"]').click }
      run_jobs
      keep_trying_until { f('div.progressStatus span').text == 'Completed' }

      @new_course = Course.last
      expect(@new_course.assignments.count).to eq 500
    end

    it "should export large course content" do
      get "/courses/#{@course.id}/content_exports"
      yield if block_given?
      submit_form('#exporter_form')
      @export = keep_trying_until { ContentExport.last }
      @export.export_without_send_later
      new_download_link = keep_trying_until { f("#export_files a") }
      url = new_download_link.attribute 'href'
      expect(url).to match(%r{/files/\d+/download\?verifier=})
    end
  end

end
