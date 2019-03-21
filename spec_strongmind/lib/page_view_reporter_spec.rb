require_relative '../rails_helper'

RSpec.describe 'PageViewReporter', type: :model do
  describe 'stuff' do
    before do
      Setting.set('enable_page_views', 'db')
      @request_id = SecureRandom.uuid
      allow(RequestContextGenerator).to receive_messages( :request_id => @request_id )

      @viewing_user = site_admin_user(user: user_with_pseudonym(account: Account.site_admin))
      @account = Account.default
      @custom_role = custom_account_role('CustomAdmin', :account => @account)
      @custom_sa_role = custom_account_role('CustomAdmin', :account => Account.site_admin)
      user_with_pseudonym(active_all: true)

      @page_view = PageView.new
      @page_view.user = @viewing_user
      @page_view.request_id = @request_id
      @page_view.remote_ip = '10.10.10.10'
      @page_view.created_at = Time.now
      @page_view.updated_at = Time.now
      @page_view.save!

      student_in_course(:active_all => 1)
      course_with_teacher_logged_in
    end

    it "can run some spec-age" do
      skip 'Id like to be tested at some point'
    end
  end
end