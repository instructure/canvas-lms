#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe RuboCop::Cop::Specs::NoNoSuchElementError do
  subject(:cop) { described_class.new }
  let(:msg_regex) { /Avoid using Selenium::WebDriver::Error::NoSuchElementError/ }

  it 'disallows Selenium::WebDriver::Error::NoSuchElementError' do
    inspect_source(%{
      describe "breaks all the things" do
        it 'is a bad spec' do
          Selenium::WebDriver::Error::NoSuchElementError
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(msg_regex)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'disallows rescuing Selenium::WebDriver::Error::NoSuchElementError' do
    inspect_source(%{
      def not_found?
        find("#yar")
        false
      rescue Selenium::WebDriver::Error::NoSuchElementError
        true
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(msg_regex)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'disallows raising Selenium::WebDriver::Error::NoSuchElementError' do
    inspect_source(%{
      def not_found?
        a = find("#yar")
        return true if a
        raise Selenium::WebDriver::Error::NoSuchElementError
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(msg_regex)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
