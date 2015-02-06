#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "locale_selection" do
  before do
    I18n.stubs(:available_locales).returns([:en, :es, :fr])
  end

  after do
    I18n.locale = I18n.default_locale
  end

  it "should set the locale when authenticated" do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    user_session(@user, @pseudonym)
    @user.update_attribute :locale, 'es'
    @pseudonym.reload
    get dashboard_url
    expect(response).to be_success
    expect(I18n.locale).to eql(:es)
  end

  it "should set the locale when not authenticated" do
    account = Account.default
    account.update_attribute :default_locale, 'fr'
    get login_url
    expect(response).to be_success
    expect(I18n.locale).to eql(:fr)
  end

end
