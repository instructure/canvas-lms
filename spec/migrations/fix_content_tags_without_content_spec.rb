#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20140815192313_fix_content_tags_without_content.rb'

describe 'FixContentTagsWithoutContents' do
  describe "up" do
    it "should delete corrupt content tags from migrations" do
      course_factory
      mod = @course.context_modules.create!
      tag = mod.content_tags.new(:context => @course)
      tag.save(:validate => false)
      FixContentTagsWithoutContent.new.up

      expect(ContentTag.find_by_id(tag.id)).to be_nil
    end
  end
end
