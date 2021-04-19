# frozen_string_literal: true

# coding: utf-8
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
#

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe AttachmentAssociation do
  context 'create' do
    it 'sets the root_account_id using course context' do
      attachment_model filename: 'test.txt', context: account_model(root_account_id: nil)
      course_model
      association = @attachment.attachment_associations.create!(context: @course)
      expect(association.root_account_id).to eq @course.root_account_id
    end

    context 'when context is a converation message' do
      it 'sets the root_account_id using attachment' do
        attachment_model filename: 'test.txt', context: account_model(root_account_id: nil)
        cm = conversation(user_model).messages.first
        association = @attachment.attachment_associations.create!(context: cm)
        expect(association.root_account_id).to eq @attachment.root_account_id
      end
    end
  end
end
