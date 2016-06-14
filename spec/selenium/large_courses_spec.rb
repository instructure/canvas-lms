require File.expand_path(File.dirname(__FILE__) + '/common')

describe "large courses", priority: "2" do
  include_context "in-process server selenium tests"

  def assignments_creation
    @course.require_assignment_group
    create_assignments([@course.id], 20, assignment_group_id: @course.assignment_groups.first.id)
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
      expect(@new_course.assignments.count).to eq 20
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
