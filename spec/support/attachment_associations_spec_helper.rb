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

class AttachmentAssociationsSpecHelper
  attr_reader :attachment1, :attachment2, :base_html, :added_html, :replaced_html, :removed_html

  def initialize(account, course_or_user)
    account.root_account.enable_feature!(:file_association_access)
    @attachment1 = course_or_user.attachments.create!(uploaded_data: Rack::Test::UploadedFile.new("spec/fixtures/files/docs/doc.doc", "application/msword", true))
    @attachment2 = course_or_user.attachments.create!(uploaded_data: Rack::Test::UploadedFile.new("spec/fixtures/files/292.mp3", "audio/mpeg", true))
    link_prefix = if course_or_user.is_a?(Course)
                    "/courses/#{course_or_user.id}/files"
                  else
                    "/users/#{course_or_user.id}/files"
                  end
    @base_html = "<p>Here is a link to a file: <a href=\"#{link_prefix}/#{@attachment1.id}/download\">doc.doc</a></p>"
    @added_html = "<p>Here is a link to a file: <a href=\"#{link_prefix}/#{@attachment1.id}/download\">doc.doc</a>, and to the audio: <a href=\"#{link_prefix}/#{@attachment2.id}/download\">292.mp3</a></p>"
    @replaced_html = "<p>Here is a link to the audio: <a href=\"#{link_prefix}/#{@attachment2.id}/download\">292.mp3</a></p>"
    @removed_html = "<p>Here is some text without attachments.</p>"
  end

  def count_aa_records(context_type, context_id, context_concern = nil)
    aa_records = AttachmentAssociation.where(context_type:, context_id:, context_concern:).pluck(:context_id, :attachment_id)
    id_occurences = {}
    att_occurences = {}

    aa_records.each do |item|
      id_occurences[item[0]] ||= 0
      id_occurences[item[0]] += 1
      att_occurences[item[1]] ||= 0
      att_occurences[item[1]] += 1
    end

    [id_occurences, att_occurences]
  end
end
