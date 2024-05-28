# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe "Translation" do
  it "does not translate controls if locale is english" do
    user = user_factory(active_all: true)
    user.locale = "en"
    allow(Translation).to receive(:create)
    Translation.translated_languages(user)
    expect(Translation).not_to have_received(:create)
  end

  it "does not translate if no locale" do
    user = user_factory(active_all: true)
    allow(Translation).to receive(:create)
    Translation.translated_languages(user)
    expect(Translation).not_to have_received(:create)
  end

  it "translates if non-english locale is set" do
    user = user_factory(active_all: true)
    user.locale = "es"
    allow(Translation).to receive(:create)
    Translation.translated_languages(user)
    expect(Translation).to have_received(:create).exactly(Translation.languages.length).times
  end
end
