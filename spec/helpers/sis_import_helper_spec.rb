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

describe SisImportHelper do
  include SisImportHelper
  let_once(:account) { Account.create! }
  let(:user) { user_model }

  before do
    @batch = account.sis_batches.create!
    @batch.sis_batch_errors.create(root_account: account, file: "users.csv", message: "some error", row: 1)
    @batch.finish(false)
  end

  it "generates tokens for error attachments that expire in an hour" do
    token = sis_import_error_attachment_token(@batch, user:)
    expiration = Time.at(CanvasSecurity.decode_jwt(token)[:exp])
    expect(expiration).to be_within(1.minute).of(1.hour.from_now)
  end
end
