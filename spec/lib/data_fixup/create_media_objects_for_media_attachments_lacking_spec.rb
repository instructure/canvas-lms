# frozen_string_literal: true

#
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

require "spec_helper"

describe DataFixup::CreateMediaObjectsForMediaAttachmentsLacking do
  let(:course) { course_model }

  def mig_id(obj)
    CC::CCHelper.create_key(obj, global: true)
  end

  context "Media attachment has direct migration linkage to valid ancestor" do
    before do
      @media_attachment = Attachment.create! context: course, media_entry_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", filename: "whatever.flv", display_name: "whatever.flv", content_type: "unknown/unknown"
      @media_object = MediaObject.create! media_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", user_entered_title: "whatever.flv", title: "whatever.flv", attachment_id: @media_attachment.id
      @fake_child_course = course_model
      ContentMigration.create!(migration_settings: { "source_course_id" => course.id }, context: @fake_child_course, source_course_id: course.id)
      @fake_child_attachment = Attachment.create! context: @fake_child_course, filename: "whatever.flv", content_type: "unknown/unknown", migration_id: mig_id(@media_attachment)
      @fake_child_course.assignments.create!(submission_types: "online_text_entry", points_possible: 2, description: "<iframe width=0 height=0 src=\"/media_attachments_iframe/#{@fake_child_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
    end

    it "creates a media object based on the parent's" do
      allow(Attachment).to receive(:where).and_call_original
      allow(MediaObject).to receive(:where).and_call_original
      expect(@fake_child_attachment.media_entry_id).to be_nil
      DataFixup::CreateMediaObjectsForMediaAttachmentsLacking.run
      expect(Attachment).to have_received(:where).with({
                                                         filename: "whatever.flv",
                                                         context_id: [course.id]
                                                       })
      expect(MediaObject).not_to have_received(:where).with({ title: "whatever.flv" })
      @fake_child_attachment.reload
      expect(@fake_child_attachment.media_entry_id).to eq("m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW")
    end
  end

  context "Media attachment can have it's parentage confirmed but lacked direct context migration link - media object query" do
    before do
      @media_attachment = Attachment.create! context: course, media_entry_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", filename: "whatever.flv", display_name: "whatever.flv", content_type: "unknown/unknown"
      @media_object = MediaObject.create! media_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", user_entered_title: "whatever.flv", title: "whatever.flv", attachment_id: @media_attachment.id
      @fake_child_course = course_model
      @fake_child_attachment = Attachment.create! context: @fake_child_course, filename: "whatever.flv", content_type: "unknown/unknown", migration_id: mig_id(@media_attachment)
      @fake_child_course.assignments.create!(submission_types: "online_text_entry", points_possible: 2, description: "<iframe width=0 height=0 src=\"/media_attachments_iframe/#{@fake_child_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
    end

    it "creates a media object based on the parent's" do
      allow(Attachment).to receive(:where).and_call_original
      allow(MediaObject).to receive(:where).and_call_original
      expect(@fake_child_attachment.media_entry_id).to be_nil
      DataFixup::CreateMediaObjectsForMediaAttachmentsLacking.run
      expect(MediaObject).to have_received(:where).with({ title: "whatever.flv" }) # Looked (and found) directly in media objects
      expect(Attachment).not_to have_received(:where).with({ filename: "whatever.flv" }) # Didn't need to look at *all* the attachments
      @fake_child_attachment.reload
      expect(@fake_child_attachment.media_entry_id).to eq("m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW")
    end
  end

  context "Media attachment can have it's parentage confirmed but lacked direct context migration link - attachment query" do
    before do
      @media_attachment = Attachment.create! context: course, media_entry_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", filename: "whatever.flv", display_name: "whatever.flv", content_type: "unknown/unknown"
      @media_object = MediaObject.create! media_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", user_entered_title: "whatever-else-sadly.flv", title: "whatever-else-sadly.flv", attachment_id: @media_attachment.id
      @fake_child_course = course_model
      @fake_child_attachment = Attachment.create! context: @fake_child_course, filename: "whatever.flv", content_type: "unknown/unknown", migration_id: mig_id(@media_attachment)
      @fake_child_course.assignments.create!(submission_types: "online_text_entry", points_possible: 2, description: "<iframe width=0 height=0 src=\"/media_attachments_iframe/#{@fake_child_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
    end

    it "creates a media object based on the parent's" do
      allow(Attachment).to receive(:where).and_call_original
      allow(MediaObject).to receive(:where).and_call_original
      expect(@fake_child_attachment.media_entry_id).to be_nil
      DataFixup::CreateMediaObjectsForMediaAttachmentsLacking.run
      expect(MediaObject).to have_received(:where).with({ title: "whatever.flv" }) # Tried media object searching
      expect(Attachment).to have_received(:where).with({ filename: "whatever.flv" }) # Didn't take... so we tried aaaall attachments
      @fake_child_attachment.reload
      expect(@fake_child_attachment.media_entry_id).to eq("m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW")
    end
  end

  context "for when the media id info stems from the markup" do
    before do
      @media_attachment = Attachment.create! context: course, media_entry_id: "m-2dGZAmbnEHAUkGCSe2Kx5eEc5DCESB73", filename: "whatever_else.flv", display_name: "whatever_else.flv", content_type: "unknown/unknown"
      @media_object = MediaObject.create! media_id: "m-2dGZAmbnEHAUkGCSe2Kx5eEc5DCESB73", user_entered_title: "whatever_else.flv", title: "whatever_else.flv", attachment_id: @media_attachment.id

      @second_media_attachment = Attachment.create! context: course, media_entry_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", filename: "whatever_else.flv", display_name: "whatever_else.flv", content_type: "unknown/unknown"
      @second_media_object = MediaObject.create! media_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", user_entered_title: "whatever_else.flv", title: "whatever_else.flv", attachment_id: @second_media_attachment.id

      @fake_child_course = course_model

      @fake_child_attachment = Attachment.create! context: @fake_child_course, filename: "whatever_1.flv", content_type: "unknown/unknown", migration_id: mig_id(@media_attachment)
      @second_fake_child_attachment = Attachment.create! context: @fake_child_course, filename: "whatever_2.flv", content_type: "unknown/unknown", migration_id: mig_id(@second_media_attachment)
      @third_fake_child_attachment = Attachment.create! context: @fake_child_course, filename: "whatever_3.flv", content_type: "unknown/unknown", migration_id: "doesntmatter"

      @fake_child_course.assignments.create!(submission_types: "online_text_entry", points_possible: 2, description: "<iframe width=0 height=0 id=\"media_comment_m-2dGZAmbnEHAUkGCSe2Kx5eEc5DCESB73\" src=\"/media_attachments_iframe/#{@fake_child_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
      @fake_child_course.assignments.create!(submission_types: "online_text_entry", points_possible: 2, description: "<iframe width=0 height=0 id=\"media_comment_m-2dGZAmbnEHAUkGCSe2Kx5eEc5DCESB73\" data-media-id=\"m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW\" src=\"/media_attachments_iframe/#{@second_fake_child_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
      @fake_child_course.assignments.create!(submission_types: "online_text_entry", points_possible: 2, description: "<iframe width=0 height=0 id=\"media_comment_m-Ec5DCESB732dGZAmbnEHAUkGCSe2Kx5e\" data-media-id=\"m-Ec5DCESB732dGZAmbnEHAUkGCSe2Kx5e\" src=\"/media_attachments_iframe/#{@third_fake_child_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
    end

    it "sets the media entry id on the children attachments if a media object by that identifier exists" do
      allow(Attachment).to receive(:where).and_call_original
      allow(MediaObject).to receive(:where).and_call_original
      expect(@fake_child_attachment.media_entry_id).to be_nil
      expect(@second_fake_child_attachment.media_entry_id).to be_nil
      expect(@third_fake_child_attachment.media_entry_id).to be_nil
      DataFixup::CreateMediaObjectsForMediaAttachmentsLacking.run
      # Checks the media exists for each possible shortcut
      expect(MediaObject).to have_received(:where).with({ media_id: "m-2dGZAmbnEHAUkGCSe2Kx5eEc5DCESB73" })
      expect(MediaObject).to have_received(:where).with({ media_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW" })
      expect(MediaObject).to have_received(:where).with({ media_id: "m-Ec5DCESB732dGZAmbnEHAUkGCSe2Kx5e" })
      # Didn't have to run the worst queries
      expect(MediaObject).not_to have_received(:where).with({ title: "whatever.flv" })
      expect(Attachment).not_to have_received(:where).with({ title: "whatever.flv" })
      @fake_child_attachment.reload
      expect(@fake_child_attachment.reload.media_entry_id).to eq("m-2dGZAmbnEHAUkGCSe2Kx5eEc5DCESB73") # Got the data from the id markup
      expect(@second_fake_child_attachment.reload.media_entry_id).to eq("m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW") # Got the data from the data-media-id markup preferably
      expect(@third_fake_child_attachment.reload.media_entry_id).to be_nil # Couldn't confirm the media object for the id found in the markup exists, so it wasn't used
    end
  end
end
