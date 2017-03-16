#
# Copyright (C) 2011-2016 Instructure, Inc.
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
  describe "validation" do
    before(:once) do
      @root_account = account_model
    end

    it "is valid with no grading_period_group" do
      term = EnrollmentTerm.new
      term.root_account = @root_account
      expect(term).to be_valid
    end

    it "is valid with a grading period group shared with another enrollment term" do
      term_1 = @root_account.enrollment_terms.create!
      term_2 = @root_account.enrollment_terms.create!
      group = @root_account.grading_period_groups.create!(title: "Example Group")
      term_1.update_attribute(:grading_period_group_id, group)
      term_2.grading_period_group = group
      expect(term_1).to be_valid
      expect(term_2).to be_valid
    end

    it "is not valid with a grading period group belonging to a different account" do
      term_1 = @root_account.enrollment_terms.create!
      term_2 = account_model.enrollment_terms.create!
      group = @root_account.grading_period_groups.create!(title: "Example Group")
      term_1.update_attribute(:grading_period_group_id, group)
      term_2.grading_period_group = group
      expect(term_1).to be_valid
      expect(term_2).not_to be_valid
    end
  end

  describe 'computation of course scores' do
    before(:once) do
      @root_account = Account.create!
      @term = @root_account.enrollment_terms.create!
      @root_account.courses.create!(enrollment_term: @term)
    end

    it 'recomputes course scores if the grading period set is changed' do
      grading_period_set = @root_account.grading_period_groups.create!
      Enrollment.expects(:recompute_final_score).once
      @term.update!(grading_period_group_id: grading_period_set)
    end

    it 'does not recompute course scores if the grading period set is not changed' do
      Enrollment.expects(:recompute_final_score).never
      @term.update!(name: 'The Best Term')
    end
  end

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
          I18n.config.available_locales_set << :test_locale
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
      course_factory account: @account
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
    before(:once) do
      @account = account_model
    end

    it "should not be able to delete a default term" do
      expect { @account.default_enrollment_term.destroy }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should not be able to delete an enrollment term with active courses" do
      @term = @account.enrollment_terms.create!
      course_factory account: @account
      @course.enrollment_term = @term
      @course.save!

      expect { @term.destroy }.to raise_error(ActiveRecord::RecordInvalid)

      @course.destroy
      @term.destroy
    end
  end

  describe "counts" do
    before(:once) do
      @t1 = Account.default.enrollment_terms.create!
      course_with_teacher(active_course: true, active_enrollment: true)
      @course.enrollment_term_id = @t1.id
      @course.save!

      @t2 = Account.default.enrollment_terms.create!
      course_with_teacher(active_course: true, active_enrollment: true)
      @course.enrollment_term_id = @t2.id
      @course.save!

      @t3 = Account.default.enrollment_terms.create!
      course_with_teacher(active_course: true, active_enrollment: true)
      @course.enrollment_term_id = @t3.id
      @course.save!
    end

    describe ".courses_counts" do
      it "returns course counts" do
        course_with_teacher(active_all: true)
        @course.enrollment_term_id = @t1.id
        @course.save!

        counts = {}
        counts[@t1.id] = 2
        counts[@t2.id] = 1
        expect(EnrollmentTerm.course_counts([@t1, @t2])).to eq counts
      end
    end
  end

  describe "scopes" do
    before(:once) do
      @root_account = account_model
      @terms = {}

      scopes = [{
        name: :active,
        criteria: {}
      },
      {
        name: :not_default,
        criteria: {}
      },
      {
        name: :ended,
        criteria: {
          end_at: 10.days.ago
        }
      },
      {
        name: :started_1,
        criteria: {
          start_at: 10.days.ago
        }
      },
      {
        name: :started_2,
        criteria: {
          start_at: nil
        }
      },
      {
        name: :not_ended_1,
        criteria: {
          end_at: 10.days.from_now
        }
      },
      {
        name: :not_ended_2,
        criteria: {
          end_at: nil
        }
      },
      {
        name: :not_started,
        criteria: {
          start_at: 10.days.from_now
        }
      }]

      scopes.each do |scope|
        @terms[scope[:name]] = @root_account.enrollment_terms.create!({name: scope[:name].to_s}.merge(scope[:criteria]))
        course_with_teacher(active_course: true, active_enrollment: true)
        @course.enrollment_term_id = @terms[scope[:name]].id
        @course.save!
      end
    end

    def term_ids_for_scope(scope)
      Array.wrap(@root_account
                  .enrollment_terms
                  .send(scope)
                  .pluck(:id)).sort
    end

    def validate_scope(scope, expected_scopes = nil, include_default: false)
      expected_scopes ||= scope
      expected_ids = term_ids_for_scope(scope)

      scopes = @terms.slice(*expected_scopes).values
      scopes << @root_account.default_enrollment_term if include_default
      actual_ids = scopes.map(&:id).sort

      expect(expected_ids).to eq(actual_ids)
    end

    it "should limit by active terms" do
      validate_scope(:active, @terms.keys, include_default: true)
    end

    it "should limit by ended terms" do
      validate_scope(:ended)
    end

    it "should limit by started terms" do
      validate_scope(:started, @terms.except(:not_started).keys, include_default: true)
    end

    it "should limit by not ended terms" do
      validate_scope(:not_ended, @terms.except(:ended).keys, include_default: true)
    end

    it "should limit by not started terms" do
      validate_scope(:not_started)
    end

    it "should limit by non-default terms" do
      validate_scope(:not_default, @terms.keys)
    end
  end
end
