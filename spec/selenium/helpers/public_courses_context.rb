require File.expand_path(File.dirname(__FILE__) + '/../common')

shared_context "public course as a logged out user" do
  def ensure_logged_out
    destroy_session
  end

  def validate_selector_displayed(selector)
    expect(f(selector)).to be_truthy
  end

  let!(:public_course) do
    course_factory(active_course: true)
    @course.is_public = true
    @course.save!
    @course
  end

  before :each do
    ensure_logged_out
  end
end
