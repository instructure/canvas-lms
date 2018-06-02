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

require_relative '../spec_helper'

describe ObserverAlertThreshold do
  it 'can link to an user_observation_link' do
    observer = user_factory()
    student = user_factory()
    link = UserObservationLink.new(:student => student, :observer => observer, 
                            :root_account => @account)
    link.save!
    threshold = ObserverAlertThreshold.new(:user_observation_link => link, :alert_type => 'missing')
    threshold.save!

    saved_threshold = ObserverAlertThreshold.find(threshold.id)
    expect(saved_threshold).not_to be_nil
    expect(saved_threshold.user_observation_link).not_to be_nil
  end
end
