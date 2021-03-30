# frozen_string_literal: true

#
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
#
require_relative '../../../spec_helper'

describe Api::V1::Conferences do
  include Api::V1::Conferences

  def named_context_url(context, type, conf)
    raise unless type == :context_conference_url

    "/#{context.class.name.downcase}s/#{context.id}/conferences/#{conf.id}"
  end

  before :once do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.create!(name: 'wimba')
    @plugin.update_attribute(:settings, { :domain => 'wimba.test' })
  end

  describe '.ui_conferences_json' do
    before do
      course_with_teacher
      @conference = @course.web_conferences.create!(
        :conference_type => 'Wimba',
        :user => @teacher
      )
    end

    it "excludes user_ids" do
      json = ui_conferences_json(WebConference.where(id: @conference), @course, @teacher, nil)
      expect(json.first.keys).not_to include('user_ids')
    end
  end
end
