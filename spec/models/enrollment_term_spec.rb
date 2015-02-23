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
        begin
          old_locale = I18n.locale
          I18n.locale = :test_locale

          expect(term.name).to eq "mreT tluafeD"
          expect(term.read_attribute(:name)).to eq EnrollmentTerm::DEFAULT_TERM_NAME
          term.name = "my term name"
          term.save!
          expect(term.read_attribute(:name)).to eq "my term name"
          expect(term.name).to eq "my term name"
          term.name = "mreT tluafeD"
          term.save!
          expect(term.read_attribute(:name)).to eq EnrollmentTerm::DEFAULT_TERM_NAME
          expect(term.name).to eq "mreT tluafeD"
        ensure
          I18n.locale = old_locale
        end
      end
    end
  end

  describe "overridden_term_dates" do
    before(:once) do
      account_model
      course account: @account
      @term = @account.enrollment_terms.create!
    end

    it "should return the dates for a single enrollment" do
      @term.set_overrides(@account, 'StudentEnrollment' => { start_at: '2014-12-01', end_at: '2014-12-31' })
      enrollment = student_in_course
      expect(@term.overridden_term_dates([enrollment])).to eq([Date.parse('2014-12-01'), Date.parse('2014-12-31')])
    end

    it "should return the most favorable dates given multiple enrollments" do
      @term.set_overrides(@account, 'StudentEnrollment' => { start_at: '2014-12-01', end_at: '2015-01-31' },
                                    'ObserverEnrollment' => { start_at: '2014-11-01', end_at: '2014-12-31' })
      student_enrollment = student_in_course
      observer_enrollment = @course.enroll_user(student_enrollment.user, 'ObserverEnrollment')
      expect(@term.overridden_term_dates([student_enrollment, observer_enrollment])).to eq([Date.parse('2014-11-01'), Date.parse('2015-01-31')])
    end

    it "should prioritize nil (unrestricted) dates if present" do
      @term.set_overrides(@account, 'StudentEnrollment' => { start_at: '2014-12-01', end_at: nil },
                                    'TaEnrollment' => { start_at: nil, end_at: '2014-12-31' })
      student_enrollment = student_in_course
      ta_enrollment = course_with_ta course: @course, user: student_enrollment.user
      expect(@term.overridden_term_dates([student_enrollment, ta_enrollment])).to eq([nil, nil])
    end
  end

  describe "deletion" do
    it "should not be able to delete a default term" do
      account_model
      expect { @account.default_enrollment_term.destroy }.to raise_error
    end

    it "should not be able to delete an enrollment term with active courses" do
      account_model
      @term = @account.enrollment_terms.create!
      course account: @account
      @course.enrollment_term = @term
      @course.save!

      expect { @term.destroy }.to raise_error

      @course.destroy

      @term.destroy
    end
  end

end
