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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe EnrollmentTerm do
  it "should handle the translated Default Term names correctly" do
    begin
      account_model
      term = @account.default_enrollment_term
      
      translations = {
        :test_locale => {
          :account => {
            :default_term_name => "mreT tluafeD"
          }
        }
      }
      I18n.backend.stub(translations) do
        I18n.locale = :test_locale

        term.name.should == "mreT tluafeD"
        term.read_attribute(:name).should == EnrollmentTerm::DEFAULT_TERM_NAME
        term.name = "my term name"
        term.save!
        term.read_attribute(:name).should == "my term name"
        term.name.should == "my term name"
        term.name = "mreT tluafeD"
        term.save!
        term.read_attribute(:name).should == EnrollmentTerm::DEFAULT_TERM_NAME
        term.name.should == "mreT tluafeD"
      end
    end
  end
end
