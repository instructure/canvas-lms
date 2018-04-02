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
#

require_relative '../../spec_helper'

describe DataFixup::PopulateSubmissionAnonymousIds do
  before do
    @submission_without_anonymous_id = submission_model
    @submission_without_anonymous_id.update_attribute(:anonymous_id, nil)
    @submission_with_anonymous_id = submission_model
  end

  it 'populates anonymous ids' do
    start_at = Course.order(:id).first.id
    end_at = Course.order(:id).last.id
    expect { DataFixup::PopulateSubmissionAnonymousIds.run(start_at, end_at) }.
      to change { @submission_without_anonymous_id.reload.anonymous_id }.from(nil).to(String)
  end

  it 'does not change existing anonymous ids' do
    start_at = Course.order(:id).first.id
    end_at = Course.order(:id).last.id
    expect { DataFixup::PopulateSubmissionAnonymousIds.run(start_at, end_at) }.
      not_to change { @submission_with_anonymous_id.reload.anonymous_id }
  end
end
