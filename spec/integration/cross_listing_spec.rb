#
# Copyright (C) 2011 Instructure, Inc.
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

describe "cross listing" do
  describe "user course associations" do

    it "should not be kept when a user is not enrolled in that course anymore" do
      process_csv_data_cleanly(
        "user_id,login_id,password,first_name,last_name,email,status",
        "U1,User1,,U,1,u1@example.com,active"
        )
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A1,,A1,active")
      process_csv_data_cleanly(
        "term_id,name,status,start_date,end_date",
        "T1,T1,active,2011-01-01 00:00:00,2012-12-31 00:00:00")
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C1,C1,C1,A1,T1,active",
        "C2,C2,C2,A1,T1,active",
        "C3,C3,C3,A1,T1,active",
        "C4,C4,C4,A1,T1,active",
        "C5,C5,C5,A1,T1,active")
      process_csv_data_cleanly(
        "section_id,course_id,name,status,start_date,end_date",
        "S1,C1,S1,active,,",
        "S2,C1,S1,active,,",
        "S3,C1,S1,active,,")
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status",
        ",U1,teacher,S1,active",
        ",U1,teacher,S2,active",
        ",U1,teacher,S3,active")
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X1,S2,active",
        "C4,S3,active")

      expect(CommunicationChannel.by_path('u1@example.com').first.user.cached_current_enrollments.map(&:course).map(&:sis_source_id).sort).to eq ["C1", "X1", "C4"].sort
    end
    
  end
end
