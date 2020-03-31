#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../../common'

describe 'Community login disambiguate' do
  include_context 'in-process server selenium tests'

  context 'delegated auth with multiple hosts' do
    before :each do
      get '/force_disambiguate_page?nhosts=3&provider=Zendesk'
      @host_options = f("input[placeholder='Choose Canvas Account…']")
    end

    it 'should redirect to the chosen host' do
      check_image(f("img[alt='Confused Panda questioning what to do next']"))
      expect(f("button[type='button']")).to have_attribute('disabled')
      @host_options.click
      @host_options.send_keys(:arrow_down)
      @host_options.send_keys(:return)
      expect(f("button[type='button']")).not_to have_attribute('disabled')
    end

    it 'does not redirect to host if other is selected' do
      @host_options.click
      4.times { @host_options.send_keys(:arrow_down) }
      @host_options.send_keys(:return)
      find_button('Go').click
      expect(fj("span:contains('Canvas Community'):visible")).to be_truthy
    end
  end

  context 'last known canvas host cookie is empty' do
    it 'should bring up FFT login or create a canvas account' do
      get '/force_disambiguate_page'
      check_image(f("img[alt='Confused Panda questioning what to do next']"))
      expect(fj("h2:contains('have a Canvas Account'):visible")).to be_truthy
      expect(fj("button:contains('Log In'):visible")).to be_truthy
      expect(fj("h2:contains('Try out Canvas'):visible")).to be_truthy
      expect(fj("button:contains('Sign Up'):visible")).to be_truthy
      ff("button[type='button']").each do |button|
        expect(button).not_to have_attribute('disabled')
      end
    end
  end
end
