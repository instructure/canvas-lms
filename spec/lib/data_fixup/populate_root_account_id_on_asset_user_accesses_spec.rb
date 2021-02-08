# frozen_string_literal: true

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

describe DataFixup::PopulateRootAccountIdOnAssetUserAccesses do
  it 'ignores AssetUserAccesses with Course context' do
    aua = AssetUserAccess.create!(context: course_model)
    aua.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(aua.id, aua.id)
    expect(aua.reload.root_account_id).to be_nil
  end

  it 'ignores AssetUserAccesses with Group context' do
    aua = AssetUserAccess.create!(context: group_model)
    aua.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(aua.id, aua.id)
    expect(aua.reload.root_account_id).to be_nil
  end

  it 'ignores AssetUserAccesses with Account context' do
    aua = AssetUserAccess.create!(context: account_model)
    aua.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(aua.id, aua.id)
    expect(aua.reload.root_account_id).to be_nil
  end

  context 'with User context' do
    before :each do
      @aua = AssetUserAccess.create!(context: user_model)
      @aua.update_column(:root_account_id, nil)
      @course = course_model
    end

    it 'sets root_account_id from Course asset' do
      @aua.update!(asset_code: @course.asset_string)
      DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(@aua.id, @aua.id)
      expect(@aua.reload.root_account_id).to eq @course.root_account_id
    end

    it 'sets root_account_id from Course asset with subpage' do
      @aua.update!(asset_code: "files:#{@course.asset_string}")
      DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(@aua.id, @aua.id)
      expect(@aua.reload.root_account_id).to eq @course.root_account_id
    end

    it 'sets root_account_id from CalendarEvent asset' do
      event = CalendarEvent.create!(context: @course)
      @aua.update!(asset_code: event.asset_string)
      DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(@aua.id, @aua.id)
      expect(@aua.reload.root_account_id).to eq event.root_account_id
    end

    it 'sets root_account_id from Attachment asset' do
      @aua.update!(asset_code: attachment_model(context: @course).asset_string)
      DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(@aua.id, @aua.id)
      expect(@aua.reload.root_account_id).to eq @course.root_account_id
    end

    it 'sets root_account_id from Group asset' do
      @aua.update!(asset_code: group_model(context: @course).asset_string)
      DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(@aua.id, @aua.id)
      expect(@aua.reload.root_account_id).to eq @course.root_account_id
    end

    it 'sets record from User asset to root_account_id=0' do
      @aua.update!(asset_code: user_model.asset_string)
      DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(@aua.id, @aua.id)
      expect(@aua.reload.root_account_id).to eq(0)
    end

    it 'sets root_account_id for multiple records' do
      @aua.update!(asset_code: @course.asset_string)
      aua2 = AssetUserAccess.create!(context: user_model, asset_code: "files:#{@course.asset_string}")
      aua2.update_column(:root_account_id, nil)
      DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(@aua.id, aua2.id)
      expect(@aua.reload.root_account_id).to eq @course.root_account_id
      expect(aua2.reload.root_account_id).to eq @course.root_account_id
    end

    it 'logs unknown asset type to Sentry as ErrorReport' do
      @aua.update!(asset_code: account_model.asset_string)
      expect(Canvas::Errors).to receive(:capture).once
      DataFixup::PopulateRootAccountIdOnAssetUserAccesses.populate(@aua.id, @aua.id)
    end
  end
end
