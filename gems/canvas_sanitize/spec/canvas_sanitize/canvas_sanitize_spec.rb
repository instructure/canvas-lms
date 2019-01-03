#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'spec_helper'

describe CanvasSanitize do
  it "shouldnt strip lang attributes by default" do
    cleaned = Sanitize.clean("<p lang='es'>Hola</p>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<p lang=\"es\">Hola</p>")
  end

  it "doesnt strip dir attributes by default" do
    cleaned = Sanitize.clean("<p dir='rtl'>RightToLeft</p>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<p dir=\"rtl\">RightToLeft</p>")
  end

  it "doesnt strip data-* attributes by default" do
    cleaned = Sanitize.clean("<p data-item-id='1234'>Item1234</p>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<p data-item-id=\"1234\">Item1234</p>")
  end

  it "does not strip track elements" do
    cleaned = Sanitize.clean("<track src=\"http://google.com\"></track>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<track src=\"http://google.com\"></track>")
  end

  it "sanitizes javascript protocol in mathml" do
    cleaned = Sanitize.clean("<math href=\"javascript:alert(1)\">CLICKME</math>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<math>CLICKME</math>")
  end

  it "allows abbr elements" do
    cleaned = Sanitize.clean("<abbr title=\"Internationalization\">I18N</abbr>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<abbr title=\"Internationalization\">I18N</abbr>")
  end

  it "sanitizes javascript protocol in data-url" do
    cleaned = Sanitize.clean("<a data-url=\"javascript:alert('bad')\">Link</a>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<a>Link</a>")
  end
end
