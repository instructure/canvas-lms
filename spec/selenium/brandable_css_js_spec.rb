#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "brandableCss JS integration specs" do
  include_context "in-process server selenium tests"

  EXAMPLE_CDN_HOST = 'https://somecdn.example.com'

  it "sets ENV.asset_host correctly" do
    expect(Canvas::Cdn.config).to receive(:host).at_least(:once).and_return(EXAMPLE_CDN_HOST)
    get "/login/canvas"
    expect(driver.execute_script("return ENV.ASSET_HOST")).to eq(EXAMPLE_CDN_HOST)
  end

  it "loads css from handlebars with variables correctly" do
    course_with_teacher_logged_in
    get '/calendar'
    data = BrandableCSS.cache_for('jst/calendar/calendarApp', 'new_styles_normal_contrast')
    expect(data[:includesNoVariables]).to be_falsy
    expect(data[:combinedChecksum]).to match(/\A[a-f0-9]{10}\z/), '10 chars of an MD5'
    url = "#{app_url}/dist/brandable_css/new_styles_normal_contrast/jst/calendar/calendarApp-#{data[:combinedChecksum]}.css"
    expect(f("head link[rel='stylesheet'][data-loaded-by-brandableCss][href*='calendarApp']")['href']).to eq(url)
  end
end
