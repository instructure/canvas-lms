#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe RuboCop::Cop::Specs::NoSeleniumWebDriverWait do
  subject(:cop) { described_class.new }
  let(:msg_regex) { /Avoid using Selenium::WebDriver::Wait/ }

  it 'disallows Selenium::WebDriver::Wait' do
    inspect_source(%{
      describe "breaks all the things" do
        wait = Selenium::WebDriver::Wait.new(timeout: 5)
        wait.until do
          el = f('.self_enrollment_message')
          el.present? &&
          el.text != nil &&
          el.text != ""
        end
        expect(f('.self_enrollment_message')).not_to include_text('self_enrollment_code')
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(msg_regex)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
