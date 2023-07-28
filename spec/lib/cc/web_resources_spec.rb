# frozen_string_literal: true

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

require_relative "cc_spec_helper"

describe CC::WebResources do
  include CC::WebResources

  describe "#add_media_objects" do
    context "with a media_object lacking an attachment" do
      it "creates an attachment with the mo data" do
        user = user_model
        mo = MediaObject.create!(user_id: user, context: user, media_id: "test", media_type: "video", title: "Mo")

        allow(CanvasKaltura::ClientV3).to receive(:new).and_return(double("Kaltura", startSession: true))
        allow(self).to receive_messages(for_course_copy: false, export_media_objects?: true, add_error: true)

        add_media_objects(double("Html_Exporter", used_media_objects: [mo], media_object_infos: {}))
        expect(mo.attachment).to be_truthy
      end
    end
  end
end
