# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

shared_examples_for "a locked api item" do
  def verify_unlocked
    json = api_get_json
    expect(json).not_to be_nil

    expect(json["locked_for_user"]).to be_falsey
  end

  def verify_locked(*lock_info_extra)
    prohibited_fields = %w[
      canvadoc_session_url
      crocodoc_session_url
    ]

    json = api_get_json

    expect(json).not_to be_nil

    expect(json["locked_for_user"]).to be_truthy, "expected 'locked_for_user' to be true"
    expect(json["lock_explanation"]).not_to be_nil, "expected 'lock_explanation' to be present"

    lock_info = json["lock_info"]
    expect(lock_info).not_to be_nil, "expected lock_info to be present"
    expect(lock_info["asset_string"]).not_to be_nil, "expected lock_info to contain 'asset_string'"
    lock_info_extra.each { |attribute| expect(lock_info[attribute.to_s]).not_to be_nil, "expected lock_info to contain '#{attribute}'" }

    expect(json.keys & prohibited_fields).to be_empty
  end

  before(:once) do
    course_with_student(active_all: true)
  end

  it "has the correct helpers" do
    expect(respond_to?(:locked_item)).to be_truthy
    expect(respond_to?(:api_get_json)).to be_truthy

    expect(locked_item).not_to be_nil
  end

  it "unlocks using unlock_at" do
    should_skip = locked_item.is_a?(WikiPage) && !Account.site_admin.feature_enabled?(:differentiated_modules)
    if locked_item.respond_to?(:unlock_at) && !should_skip
      verify_unlocked

      locked_item.unlock_at = 1.day.from_now if locked_item.respond_to?(:unlock_at)
      locked_item.save!

      verify_locked :unlock_at
    end
  end

  it "locks using lock_at" do
    should_skip = locked_item.is_a?(WikiPage) && !Account.site_admin.feature_enabled?(:differentiated_modules)
    if locked_item.respond_to?(:lock_at) && !should_skip
      verify_unlocked

      locked_item.lock_at = 1.day.ago
      locked_item.save!

      verify_locked :lock_at
    end
  end

  it "is locked by a context module that is not yet complete" do
    if respond_to?(:item_type)
      verify_unlocked

      pre_module = @course.context_modules.create!(name: "pre_module")
      external_url_tag = pre_module.add_item(type: "external_url", url: "http://example.com", title: "example")
      external_url_tag.publish! if external_url_tag.unpublished?
      pre_module.completion_requirements = { external_url_tag.id => { type: "must_view" } }
      pre_module.save!

      locked_module = @course.context_modules.create!(name: "locked_module", require_sequential_progress: true)
      item_tag = locked_module.add_item(id: locked_item.id, type: item_type)
      item_tag.publish! if item_tag.unpublished?
      locked_module.prerequisites = "module_#{pre_module.id}"
      locked_module.save!

      verify_locked :context_module
    end
  end

  it "is locked by a context module that is not yet unlocked" do
    if respond_to?(:item_type)
      verify_unlocked

      locked_module = @course.context_modules.create!(name: "locked_module", unlock_at: 1.day.from_now)
      locked_module.add_item(id: locked_item.id, type: item_type)

      verify_locked :context_module
    end
  end
end
