#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

shared_examples_for 'a locked api item' do
  def verify_unlocked
    json = api_get_json
    json.should_not be_nil

    json['locked_for_user'].should be_false
  end

  def verify_locked(*lock_info_extra)
    json = api_get_json
    json.should_not be_nil

    json['locked_for_user'].should be_true, "expected 'locked_for_user' to be true"
    json['lock_explanation'].should_not be_nil, "expected 'lock_explanation' to be present"

    lock_info = json['lock_info']
    lock_info.should_not be_nil, 'expected lock_info to be present'
    lock_info['asset_string'].should_not be_nil, "expected lock_info to contain 'asset_string'"
    lock_info_extra.each { |attribute| lock_info[attribute.to_s].should_not be_nil, "expected lock_info to contain '#{attribute.to_s}'" }
  end

  before(:once) do
    course_with_student(:active_all => true)
  end

  it 'should have the correct helpers' do
    respond_to?(:locked_item).should be_true
    respond_to?(:api_get_json).should be_true

    locked_item.should_not be_nil
  end

  it 'should unlock using unlock_at' do
    if locked_item.respond_to?(:unlock_at)
      verify_unlocked

      locked_item.unlock_at = 1.day.from_now if locked_item.respond_to?(:unlock_at)
      locked_item.save!

      verify_locked :unlock_at
    end
  end

  it 'should lock using lock_at' do
    if locked_item.respond_to?(:lock_at)
      verify_unlocked

      locked_item.lock_at = 1.day.ago
      locked_item.save!

      verify_locked :lock_at
    end
  end

  it 'should be locked by a context module that is not yet complete' do
    if respond_to?(:item_type)
      verify_unlocked

      pre_module = @course.context_modules.create!(:name => 'pre_module')
      external_url_tag = pre_module.add_item(:type => 'external_url', :url => 'http://example.com', :title => 'example')
      external_url_tag.publish! if external_url_tag.unpublished?
      pre_module.completion_requirements = { external_url_tag.id => { :type => 'must_view' } }
      pre_module.save!

      locked_module = @course.context_modules.create!(:name => 'locked_module', :require_sequential_progress => true)
      item_tag = locked_module.add_item(:id => locked_item.id, :type => item_type)
      item_tag.publish! if item_tag.unpublished?
      locked_module.prerequisites = "module_#{pre_module.id}"
      locked_module.save!

      verify_locked :context_module
    end
  end

  it 'should be locked by a context module that is not yet unlocked' do
    if respond_to?(:item_type)
      verify_unlocked

      locked_module = @course.context_modules.create!(:name => 'locked_module', :unlock_at => 1.day.from_now)
      locked_module.add_item(:id => locked_item.id, :type => item_type)

      verify_locked :context_module
    end
  end
end
