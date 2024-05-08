# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

describe TranslationController do
  before :once do
    @user = user_factory(active_all: true)
  end

  it "POST #translate_paragraph" do
    user_session(@user)
    allow(Translation).to receive_messages(available?: true, create: "translated.")
    post :translate_paragraph, params: { course_id: 1, inputs: { text: "test text.\nthis is test text.", src_lang: "en", tgt_lang: "es" } }

    # Should have been two sentences.
    expect(response).to be_successful
    expect(Translation).to have_received(:create).exactly(2)
    expect(response.parsed_body["translated_text"]).to eq("translated.\ntranslated.")
  end
end
