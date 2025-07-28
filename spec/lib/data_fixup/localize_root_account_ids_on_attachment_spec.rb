# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe DataFixup::LocalizeRootAccountIdsOnAttachment do
  subject { DataFixup::LocalizeRootAccountIdsOnAttachment.run }

  specs_require_sharding

  before do
    @root_account_2 = @shard2.activate { account_model }
    @shard1.activate do
      @root_account_1 = account_model
      Attachment.current_root_account = @root_account_1
      course_model(account: @root_account_1)
      # Attachment 1 should be a global id that can be localized. Let's ensure that its a global id.
      @attachment1 = attachment_model
      Attachment.where(id: @attachment1.id).update_all("root_account_id=#{@root_account_1.global_id}")
      @attachment2 = attachment_model
      Attachment.current_root_account = @root_account_2
      @attachment3 = attachment_model
    end
  end

  it "should update root_account_id for attachments with global ids that can be localized" do
    @shard1.activate do
      expect { subject }.to change { @attachment1.reload.attributes["root_account_id"] }
        .from(@root_account_1.global_id).to(@root_account_1.id)
    end
  end

  it "should not update other values for attachments with global root account ids that can be localized" do
    @shard1.activate do
      expect { subject }.not_to change { @attachment1.reload.attributes.except("root_account_id") }
    end
  end

  it "should not update root_account_id for attachments with ids that are already localized" do
    @shard1.activate do
      expect { subject }.not_to change { @attachment2.reload.attributes }
    end
  end

  it "should not update root_account_id for attachments with global ids that cannot be localized" do
    @shard1.activate do
      expect { subject }.not_to change { @attachment3.reload.attributes }
    end
  end
end
