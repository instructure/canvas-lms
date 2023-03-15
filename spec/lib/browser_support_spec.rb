# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe BrowserSupport do
  let(:chrome_macos_110) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_2_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36" }
  let(:chrome_macos_102) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.167 Safari/537.36" }
  let(:chrome_os_102)    { "Mozilla/5.0 (X11; CrOS aarch64 14695.115.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36" }
  let(:chrome_os_101)    { "Mozilla/5.0 (X11; CrOS aarch64 14588.98.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.0.0 Safari/537.36" }

  before do
    allow(BrowserSupport).to receive(:configuration).and_return({ "minimums" => { "chrome" => 107 },
                                                                  "chrome_os_lts" => { "chrome" => 102, "platform" => 14_695 } })
  end

  it "supports latest Chrome" do
    expect(BrowserSupport.supported?(chrome_macos_110)).to be true
  end

  it "supports latest LTS for Chrome OS" do
    expect(BrowserSupport.supported?(chrome_os_102)).to be true
  end

  it "does not support outdated Chrome" do
    expect(BrowserSupport.supported?(chrome_macos_102)).to be false
  end

  it "does not support outdated Chrome for Chrome OS" do
    expect(BrowserSupport.supported?(chrome_os_101)).to be false
  end
end
