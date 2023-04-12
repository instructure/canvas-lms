# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# A lot of these specs will seem like they are testing things that are handled by rails
# If release_note was an active record model, you would be right.  However, it is
# a dynamo model that handles its own persistence, and so it is much more important
# to ensure values are persisted correctly
describe ReleaseNote do
  around do |example|
    override_dynamic_settings(private: { canvas: { "release_notes.yml": {
      ddb_endpoint: ENV.fetch("DDB_ENDPOINT", "http://dynamodb:8000/"),
      ddb_table_name: "canvas_test_release_notes#{ENV.fetch("PARALLEL_INDEX", "")}"
    }.to_json } }) do
      ReleaseNotes::DevUtils.initialize_ddb_for_development!(recreate: true)
      example.run
    end
  end

  it "persists all attributes" do
    show_at = Time.now.utc - 1.hour
    # For validaton later, since subsecond timestamps are lost and that's fine
    show_at = show_at.change(usec: 0)
    note = ReleaseNote.new
    note.target_roles = ["student", "ta"]
    note.set_show_at("prod", show_at)
    note.published = true
    note.save
    id = note.id

    note = ReleaseNote.find(id)
    expect(note.id).not_to be_nil
    expect(note.id).to eq(id)
    expect(note.target_roles).to eq(["student", "ta"])
    expect(note.show_ats).to eq({ "prod" => show_at })
    expect(note.published).to be true
  end

  it "persists languages" do
    show_at = Time.now.utc - 1.hour
    note = ReleaseNote.new
    note.target_roles = ["student", "ta"]
    note.set_show_at("prod", show_at)
    note.published = true
    note["en"] = {
      title: "a title",
      description: "a description",
      url: "https://example.com"
    }
    note.save
    id = note.id

    note = ReleaseNote.find(id)
    expect(note["en"]).not_to be_nil
    expect(note["en"][:title]).to eq("a title")
    expect(note["en"][:description]).to eq("a description")
    expect(note["en"][:url]).to eq("https://example.com")
  end

  it "shows the notes in latest by category when published" do
    show_at = Time.now.utc - 1.hour
    note = ReleaseNote.new
    note.target_roles = ["student", "ta"]
    note.set_show_at("prod", show_at)
    note.published = true
    note.save
    id = note.id

    notes = ReleaseNote.latest(env: "prod", role: "student")
    expect(notes.length).to eq(1)
    expect(notes.first.id).to eq(id)

    notes = ReleaseNote.latest(env: "prod", role: "teacher")
    expect(notes.length).to eq(0)
  end

  it "does not show the notes in latest except when published" do
    show_at = Time.now.utc - 1.hour
    note = ReleaseNote.new
    note.target_roles = ["student", "ta"]
    note.set_show_at("prod", show_at)
    note.published = false
    note.save
    id = note.id

    notes = ReleaseNote.latest(env: "prod", role: "student")
    expect(notes.length).to eq(0)

    note.published = true
    note.save

    notes = ReleaseNote.latest(env: "prod", role: "student")
    expect(notes.length).to eq(1)
    expect(notes.first.id).to eq(id)

    note.published = false
    note.save

    notes = ReleaseNote.latest(env: "prod", role: "student")
    expect(notes.length).to eq(0)
  end

  it "remvoves published notes when deleted" do
    show_at = Time.now.utc - 1.hour
    note = ReleaseNote.new
    note.target_roles = ["student", "ta"]
    note.set_show_at("prod", show_at)
    note.published = true
    note.save
    id = note.id

    notes = ReleaseNote.latest(env: "prod", role: "student")
    expect(notes.length).to eq(1)
    expect(notes.first.id).to eq(id)

    note.delete

    notes = ReleaseNote.latest(env: "prod", role: "student")
    expect(notes.length).to eq(0)
  end

  it "does not show future notes" do
    show_at = Time.now.utc + 1.hour
    note = ReleaseNote.new
    note.target_roles = ["student", "ta"]
    note.set_show_at("prod", show_at)
    note.published = true
    note.save

    notes = ReleaseNote.latest(env: "prod", role: "student")
    expect(notes.length).to eq(0)
  end

  it "paginates correctly" do
    # Custom times to ensure that they are returned in the right order, since the serialized timestamps have second precision
    note = ReleaseNote.new
    note.instance_variable_set(:@created_at, Time.now.utc - 20.minutes)
    note.save
    id_1 = note.id

    note = ReleaseNote.new
    note.instance_variable_set(:@created_at, Time.now.utc - 10.minutes)
    note.save
    id_2 = note.id

    note = ReleaseNote.new
    note.instance_variable_set(:@created_at, Time.now.utc)
    note.save
    id_3 = note.id

    pager = ReleaseNote.paginated
    page1 = pager.paginate(per_page: 2)
    expect(page1.length).to eq(2)
    expect(page1.next_page).to be_truthy
    expect(page1[0].id).to eq(id_3)
    expect(page1[1].id).to eq(id_2)

    page2 = pager.paginate(per_page: 2, page: page1.next_page)
    expect(page2.length).to eq(1)
    expect(page2.next_page).to be_falsy
    expect(page2[0].id).to eq(id_1)
  end
end
