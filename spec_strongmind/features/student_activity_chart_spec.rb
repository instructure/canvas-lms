
require_relative '../rails_helper'

RSpec.describe 'Student Access Report', type: :feature, js: true do
  describe 'activity chart' do
    before do
      Chronic.time_class = Time.zone
      Setting.set('enable_page_views', 'db')

      student_in_course(:active_all => 1)
      teacher_in_course(course: @course)

      @viewing_user   = site_admin_user(user: user_with_pseudonym(account: Account.site_admin))
      @account        = Account.default
      @custom_role    = custom_account_role('CustomAdmin', :account => @account)
      @custom_sa_role = custom_account_role('CustomAdmin', :account => Account.site_admin)

      Timecop.travel(Chronic.parse('today at 5pm'))

      10.times do |index|
        hrs = (index + 1)

        (10 - index).times do
          @request_id = SecureRandom.uuid

          @page_view = PageView.new
          @page_view.user       = @student
          @page_view.request_id = @request_id
          @page_view.remote_ip  = '10.10.10.10'
          @page_view.created_at = hrs.hour.ago
          @page_view.updated_at = hrs.hour.ago
          @page_view.context    = @course
          @page_view.save!
        end
      end

      allow(RequestContextGenerator).to receive_messages( :request_id => @request_id )
    end

    after do
      Timecop.return
    end

    it "renders with some data" do
      user_session(@teacher)

      visit course_user_path(@course, @student)

      click_link 'Access Report'

      expect(page).to have_selector('.student-activity-chart')

      within '.student-activity-chart' do
        expect(all('.band-8').size).to be >= 1
        expect(all('.band-7').size).to be >= 1
        expect(all('.band-6').size).to be >= 1
        expect(all('.band-5').size).to be >= 1
        expect(all('.band-4').size).to be >= 1
        expect(all('.band-3').size).to be >= 1
        expect(all('.band-2').size).to be >= 1
        expect(all('.band-1').size).to be >= 1
        expect(all('.band-0').size).to be >= 1
      end
    end
  end
end
