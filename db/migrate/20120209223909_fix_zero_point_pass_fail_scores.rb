#
# Copyright (C) 2012 - present Instructure, Inc.
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

class FixZeroPointPassFailScores < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # a bug allowed a few submissions to have their grade set to pass/fail,
    # rather than complete/incomplete. pass/fail is allowed in the api, but was
    # supposed to be translated to complete/incomplete in the db.
    Submission.where(:grade => 'pass').update_all(:grade => 'complete')
    Submission.where(:grade => 'fail').update_all(:grade => 'incomplete')
    Submission.where(:published_grade => 'pass').update_all(:published_grade => 'complete')
    Submission.where(:published_grade => 'fail').update_all(:published_grade => 'incomplete')
  end

  def self.down
  end
end
