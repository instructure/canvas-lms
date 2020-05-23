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
#

require_relative "../spec_helper"
require 'db/migrate/20200511171508_make_existing_pronoun_fields_sticky.rb'

describe 'MakeExistingPronounFieldsSticky' do
  describe "up" do
    it "sets already set pronoun field as a sticky field" do
        u = User.create!(pronouns: 'she/her')
        User.where(id: u).update_all(stuck_sis_fields: nil)
        MakeExistingPronounFieldsSticky.up
        expect(u.stuck_sis_fields.to_a.join(',')).to eq 'name,sortable_name,pronouns'
    end

    it "doesn't change a non-set pronoun field as a sticky field" do
        u = User.create!
        expect(u.stuck_sis_fields.to_a.join(',')).to eq 'name,sortable_name'
        MakeExistingPronounFieldsSticky.up
        expect(u.stuck_sis_fields.to_a.join(',')).to eq 'name,sortable_name'
    end

    it "doesn't affect other set sticky fields" do
        u = User.create!(name: 'John Doe')
        expect(u.stuck_sis_fields.to_a.join(',')).to eq 'name,sortable_name'
        u.update(pronouns: 'she/her')
        MakeExistingPronounFieldsSticky.up
        expect(u.stuck_sis_fields.to_a.join(',')).to eq 'name,sortable_name,pronouns'
    end
  end
end
