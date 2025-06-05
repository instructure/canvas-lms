# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe DataFixup::AddAttachmentAssociationsToAssets do
  before(:once) do
    @account = account_model
    @user = user_model
    @course = course_model(account: @account)
    @image = attachment_model(context: @course)
    @video = attachment_model(context: @course)
    @course.syllabus_body = <<~HTML
      <p><iframe style="width: 400px; height: 225px; display: inline-block;"
           title="yayyy.mp4" data-media-type="video"
           src="/media_attachments_iframe/#{@video.id}?type=video&amp;embedded=true"
           loading="lazy" allowfullscreen="allowfullscreen" allow="fullscreen"
           data-media-id="m-63VEVgW2jJ7gEgvpa9KHyW9vDjrrh3oX"></iframe>
         <img id="3" src="/courses/#{@course.id}/files/#{@image.id}/preview?location={course_syllabus_#{@course.id}}"
            alt="rick_other.png">
      </p>
    HTML
    @course.save!
  end

  it "creates attachment associations for any attachment on syllabus body" do
    expect(AttachmentAssociation.all).to be_empty

    DataFixup::AddAttachmentAssociationsToAssets.run

    expect(AttachmentAssociation.count).to eq 2
    expect(AttachmentAssociation.pluck(:user_id)).to eq [nil, nil]
    expect(AttachmentAssociation.pluck(:attachment_id)).to match_array [@image.id, @video.id]
    expect(AttachmentAssociation.pluck(:context_id)).to match_array [@course.id, @course.id]
    expect(AttachmentAssociation.pluck(:root_account_id)).to eq [@course.root_account_id, @course.root_account_id]
  end

  it "would not re-create attachment associations if they already exist on syllabus attachments" do
    @image.attachment_associations.create!(
      context: @course,
      context_concern: "syllabus_body",
      user: @user
    )

    expect(AttachmentAssociation.count).to eq 1
    aa_id = AttachmentAssociation.first.id

    expect { DataFixup::AddAttachmentAssociationsToAssets.run }.to change {
      AttachmentAssociation.count
    }.from(1).to(2)

    expect(AttachmentAssociation.pluck(:user_id)).to match_array [@user.id, nil]
    expect(AttachmentAssociation.pluck(:id)).to include aa_id
  end
end
