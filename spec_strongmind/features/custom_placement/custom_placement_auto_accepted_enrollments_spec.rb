
require_relative '../../rails_helper'

RSpec.describe 'As a Teacher using custom placement', type: :feature, js: true do

  include_context 'stubbed_network'

  before(:each) do
    Permissions.register(
      {
        :custom_placement => {
          :label => lambda { "Apply Custom Placement to Courses" },
          :available_to => [
            'TaEnrollment',
            'TeacherEnrollment',
            'AccountAdmin',
          ],
          :true_for => [
            'AccountAdmin',
            'TeacherEnrollment'
          ]
        }
      }
    )

    course_with_teacher_logged_in
    @student = user_with_pseudonym
    @course.enroll_user(@student, 'StudentEnrollment') #invited

    @student = @student.reload

    expect(@student.enrollments.first).to be_invited

    # Module 1 -------

      @module1 = @course.context_modules.create!(:name => "Module 1")

    # External Url
      @external_url_tag = @module1.add_item(type: 'external_url', url: 'http://example.com/lolcats', title: 'External Url: requires viewing')
      @external_url_tag.publish

    # Context Module Sub Header
      @header_tag = @module1.add_item(:type => "sub_header", :title => "Context Module Sub Header")

    # Wiki Page or Page
      wiki     = @course.wiki_pages.create! :title => "Wiki Page"
      wiki_tag = @module1.add_item(:id => wiki.id, :type => 'wiki_page', :title => 'Wiki Page: requires viewing')

    @module1.completion_requirements = {
      @external_url_tag.id      => { type: 'must_view' },
      wiki_tag.id               => { type: 'must_view' }
    }

    @module1.save!

    Delayed::Testing.drain
  end

  it "pending enrollment students get auto accepted" do
    visit "/courses/#{@course.id}"

    expect(page).to have_selector('a.home.active')

    click_link 'People'

    within find("#user_#{@student.id}") do
      find('.al-trigger').click()
      sleep 1
      click_link 'Custom Placement'
    end

    expect(page).to have_selector('.ui-dialog', visible: true)

    select "Wiki Page: requires viewing", from: 'Unit to start'

    within '.ui-dialog' do
      click_button 'Update'
    end

    accept_confirm

    sleep 2

    expect(page).to have_selector('.ic-flash-success', text: 'Custom placement process started. You can check progress by viewing the course as the student.')

    @student = @student.reload
    expect(@student.enrollments.first).to be_active
  end
end
