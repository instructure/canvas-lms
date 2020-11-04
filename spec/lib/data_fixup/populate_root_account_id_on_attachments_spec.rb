#
# Copyright (C) 2020 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::PopulateRootAccountIdOnAttachments do
  let(:account) { account_model }

  describe('.populate') do
    it 'updates the root_account_id' do
      attachment1 = attachment_model(context: account)
      attachment1.update!(root_account_id: nil)
      attachment2 = attachment_model(context: account)
      attachment2.update!(root_account_id: nil)

      expect(attachment1.reload.root_account_id).to be_nil
      expect(attachment2.reload.root_account_id).to be_nil

      DataFixup::PopulateRootAccountIdOnAttachments.populate(attachment1.id, attachment2.id)

      expect(attachment1.reload.root_account_id).to eq account.id
      expect(attachment2.reload.root_account_id).to eq account.id
    end

  end

  describe('.from_model') do
    it 'updates the root_account_id using the fixup model' do
      attachment1 = attachment_model(context: account)
      attachment1.update!(root_account_id: nil)
      attachment2 = attachment_model(context: account)
      attachment2.update!(root_account_id: nil)

      expect(attachment1.reload.root_account_id).to be_nil
      expect(attachment2.reload.root_account_id).to be_nil

      DataFixup::PopulateRootAccountIdOnAttachments.from_model(attachment1.id, attachment2.id,)

      expect(attachment1.reload.root_account_id).to eq account.id
      expect(attachment2.reload.root_account_id).to eq account.id
    end
  end

  describe('.from_namespace') do
    it 'updates the root_account_id using the namespace' do
      attachment1 = attachment_model(context: account)
      attachment1.update!(root_account_id: nil)
      attachment2 = attachment_model(context: account)
      attachment2.update!(root_account_id: nil)

      expect(attachment1.reload.root_account_id).to be_nil
      expect(attachment2.reload.root_account_id).to be_nil

      DataFixup::PopulateRootAccountIdOnAttachments.from_namespace(attachment1.id, attachment2.id)

      expect(attachment1.reload.root_account_id).to eq account.id
      expect(attachment2.reload.root_account_id).to eq account.id
    end

    it 'leaves nil root_account_id if there is no namespace' do
      attachment1 = attachment_model(context: account)
      attachment1.update!(root_account_id: nil, namespace: nil)
      attachment2 = attachment_model(context: account)
      attachment2.update!(root_account_id: nil, namespace: nil)

      expect(attachment1.reload.root_account_id).to be_nil
      expect(attachment2.reload.root_account_id).to be_nil

      DataFixup::PopulateRootAccountIdOnAttachments.from_namespace(attachment1.id, attachment2.id)

      expect(attachment1.reload.root_account_id).to be_nil
      expect(attachment2.reload.root_account_id).to be_nil
    end
  end

  describe('.default_to_zero') do
    it 'updates the root_account_id to zero when nil' do
      attachment1 = attachment_model(context: account)
      attachment1.update!(root_account_id: nil)
      attachment2 = attachment_model(context: account)
      attachment2.update!(root_account_id: nil)

      expect(attachment1.reload.root_account_id).to be_nil
      expect(attachment2.reload.root_account_id).to be_nil

      DataFixup::PopulateRootAccountIdOnAttachments.default_to_zero(attachment1.id, attachment2.id)

      expect(attachment1.reload.root_account_id).to be_zero
      expect(attachment2.reload.root_account_id).to be_zero
    end
  end
end
