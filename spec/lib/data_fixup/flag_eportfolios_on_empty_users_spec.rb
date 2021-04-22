# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe DataFixup::FlagEportfoliosOnEmptyUsers do
  it 'runs' do
    course_with_teacher
    account_admin_user
    @spammer = user_model

    te1 = @teacher.eportfolios.create!(name: 'Teaching is great')
    te2 = @teacher.eportfolios.create!(name: 'My Best Assignments')
    te3 = @teacher.eportfolios.create!(name: 'Grading Services', spam_status: 'marked_as_safe')

    aae1 = @admin.eportfolios.create!(name: 'Administering all the Things')

    se1 = @spammer.eportfolios.create!(name: 'MoViEz R cOoL')
    se2 = @spammer.eportfolios.create!(name: 'Free AmaSoftBook Licenses!!!')
    se3 = @spammer.eportfolios.create!(name: 'Pills to make you a smartypants', spam_status: 'marked_as_spam')

    DataFixup::FlagEportfoliosOnEmptyUsers.run

    # Don't touch normal user eportfolios
    expect([te1, te2, aae1].map{|e| e.reload.spam_status}).to eq [nil, nil, nil]

    # Don't touch already flagged eportfolios
    expect([te3, se3].map{|e| e.reload.spam_status}).to eq ['marked_as_safe', 'marked_as_spam']

    # Flag others
    expect([se1, se2].map{|e| e.reload.spam_status}).to eq ['flagged_as_possible_spam', 'flagged_as_possible_spam']
  end
end
