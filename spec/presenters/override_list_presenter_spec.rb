# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe OverrideListPresenter do
  include TextHelper
  before do
    allow(AssignmentOverrideApplicator).to receive(:assignment_overridden_for)
      .with(assignment, user).and_return overridden_assignment
    allow(AssignmentOverrideApplicator).to receive(:assignment_overridden_for)
      .with(assignment, nil).and_return assignment
    allow(assignment).to receive(:has_active_overrides?).and_return true
  end

  around do |example|
    Timecop.freeze(Time.zone.local(2013, 3, 13, 0, 0), &example)
  end

  let(:course) { course_factory(active_all: true) }
  let(:assignment) { course.assignments.create!(title: "Testing") }
  let(:user) { student_in_course(course:, name: "Testing").user }
  let(:second_user) { student_in_course(course:, name: "Testing 2").user }
  let(:overridden_assignment) { assignment }
  let(:presenter) { OverrideListPresenter.new assignment, user }

  describe "#initialize" do
    it "keeps a reference to the user" do
      presenter = OverrideListPresenter.new nil, user
      expect(presenter.user).to eq user
    end

    context "assignment present? and user present?" do
      it "stores a reference to the overridden assignment for that user" do
        presenter = OverrideListPresenter.new assignment, user
        expect(presenter.assignment).to eq overridden_assignment
      end
    end

    context "assignment or user not present?" do
      it "stores the assignment as nil if assignment not present?" do
        presenter = OverrideListPresenter.new nil, user
        expect(presenter.assignment).to be_nil
        expect(presenter.user).to eq user
      end
    end
  end

  describe "#formatted_date_string" do
    context "due_at" do
      it "returns - if due_at isn't present" do
        due_date_hash = { due_at: nil }
        expect(presenter.formatted_date_string(:due_at, due_date_hash)).to eq "-"
        due_date_hash[:due_at] = ""
        expect(presenter.formatted_date_string(:due_at, due_date_hash)).to eq "-"
      end

      it "returns a shortened version with just the date if time is 11:59" do
        fancy_midnight = CanvasTime.fancy_midnight Time.zone.now
        due_date_hash = { due_at: fancy_midnight }
        expect(presenter.formatted_date_string(:due_at, due_date_hash)).to eq(
          date_string(fancy_midnight, :no_words)
        )
      end

      it "returns returns datetime_string if not all day but date present" do
        due_date_hash = { due_at: Time.zone.now }
        expect(presenter.formatted_date_string(:due_at, due_date_hash)).to eq(
          datetime_string(Time.zone.now)
        )
      end
    end

    context "lock_at and unlock_at" do
      it "returns returns datetime_string of not all day but date present" do
        due_date_hash = { lock_at: Time.zone.now, unlock_at: 1.day.ago }
        expect(presenter.formatted_date_string(:lock_at, due_date_hash)).to eq(
          datetime_string(Time.zone.now)
        )
        expect(presenter.formatted_date_string(:unlock_at, due_date_hash)).to eq(
          datetime_string(1.day.ago)
        )
      end

      it "returns - if due_at isn't present" do
        due_date_hash = { lock_at: nil }
        expect(presenter.formatted_date_string(:lock_at, due_date_hash)).to eq "-"
        due_date_hash[:lock_at] = ""
        expect(presenter.formatted_date_string(:lock_at, due_date_hash)).to eq "-"
        due_date_hash = { unlock_at: nil }
        expect(presenter.formatted_date_string(:unlock_at, due_date_hash)).to eq "-"
        due_date_hash[:unlock_at] = ""
        expect(presenter.formatted_date_string(:unlock_at, due_date_hash)).to eq "-"
      end

      it "never takes all_day into effect" do
        due_date_hash = { lock_at: Time.zone.now, all_day: true }
        expect(presenter.formatted_date_string(:lock_at, due_date_hash)).to eq(
          datetime_string(Time.zone.now)
        )
        due_date_hash = { unlock_at: Time.zone.now, all_day: true }
        expect(presenter.formatted_date_string(:unlock_at, due_date_hash)).to eq(
          datetime_string(Time.zone.now)
        )
      end
    end
  end

  describe "#multiple_due_dates?" do
    it "returns the result of assignment.multiple_due_dates_apply_to?(user)" do
      expect(assignment).to receive(:has_active_overrides?).and_return true
      expect(presenter.multiple_due_dates?).to be true
      expect(assignment).to receive(:has_active_overrides?).and_return false
      expect(presenter.multiple_due_dates?).to be false
    end

    it "returns false if its assignment is nil" do
      presenter = OverrideListPresenter.new nil, user
      expect(presenter.multiple_due_dates?).to be false
    end
  end

  describe "#due_for" do
    it "returns the due date's title if it is present?" do
      due_date = { title: "default" }
      expect(presenter.due_for(due_date)).to eq "default"
    end

    it "returns 'Everyone else' if multiple due dates for assignment" do
      expect(assignment).to receive(:has_active_overrides?).once.and_return true
      due_date = {}
      expect(presenter.due_for(due_date)).to eq(
        I18n.t("overrides.everyone_else", "Everyone else")
      )
    end

    it "returns 'Everyone' translated if not multiple due dates" do
      expect(assignment).to receive(:has_active_overrides?).once.and_return false
      due_date = {}
      expect(presenter.due_for(due_date)).to eq(
        I18n.t("overrides.everyone", "Everyone")
      )
    end

    context "for ADHOC overrides" do
      before do
        override = assignment.assignment_overrides.create!(due_at: 1.week.from_now)
        override.assignment_override_students.create!(user:, assignment:)
        override.assignment_override_students.create!(user: second_user, assignment:)
        override.save!

        @due_date = presenter.assignment.dates_hash_visible_to(user).first
      end

      it "returns a dynamically generated title based on the number of current and invited users" do
        expect(presenter.due_for(@due_date)).to eql("2 students")
      end

      it "does not count concluded students" do
        course.enrollments.find_by(user: second_user).conclude
        expect(presenter.due_for(@due_date)).to eql("1 student")
      end

      it "does not count inactive students" do
        course.enrollments.find_by(user: second_user).deactivate
        expect(presenter.due_for(@due_date)).to eql("1 student")
      end

      it "does not count deleted students" do
        course.enrollments.find_by(user: second_user).destroy
        expect(presenter.due_for(@due_date)).to eql("1 student")
      end

      it "does not double-count students that have multiple enrollments in the course" do
        section = course.course_sections.create!
        course.enroll_student(user, section:, enrollment_state: "active", allow_multiple_enrollments: true)
        expect(presenter.due_for(@due_date)).to eql("2 students")
      end
    end
  end

  describe "#visible_due_dates" do
    context "with standardize_assignment_date_formatting disabled" do
      before do
        Account.site_admin.disable_feature!(:standardize_assignment_date_formatting)
      end

      attr_reader :visible_due_dates

      let(:sections) do
        # the count is the important part, the actual course sections are
        # not used
        [double, double, double]
      end

      def dates_visible_to_user
        [
          { due_at: "", lock_at: nil, unlock_at: nil, set_type: "CourseSection" },
          { due_at: 1.day.from_now, lock_at: nil, unlock_at: nil, set_type: "CourseSection" },
          { due_at: 2.days.from_now, lock_at: nil, unlock_at: nil, set_type: "CourseSection" },
          { due_at: 2.days.ago, lock_at: nil, unlock_at: nil, base: true }
        ]
      end

      it "returns empty array if assignment is not present" do
        presenter = OverrideListPresenter.new nil, user
        expect(presenter.visible_due_dates).to eq []
      end

      context "when all sections have overrides" do
        before do
          allow(assignment.context).to receive(:active_section_count)
            .and_return sections.count
          allow(assignment).to receive(:all_dates_visible_to).with(user)
                                                             .and_return dates_visible_to_user
          @visible_due_dates = presenter.visible_due_dates
        end

        it "doesn't include the default due date" do
          expect(visible_due_dates.length).to eq 3
          visible_due_dates.each do |override|
            expect(override[:base]).not_to be_truthy
          end
        end

        it "sorts due dates by due_at, placing not present?/nil after dates" do
          expect(visible_due_dates.first[:due_at]).to eq(
            presenter.formatted_date_string(:due_at, dates_visible_to_user.second)
          )
          expect(visible_due_dates.second[:due_at]).to eq(
            presenter.formatted_date_string(:due_at, dates_visible_to_user.third)
          )
          expect(visible_due_dates.third[:due_at]).to eq(
            presenter.formatted_date_string(:due_at, dates_visible_to_user.first)
          )
        end

        it "includes the actual Time for presentation transforms in templates" do
          expect(visible_due_dates.second[:raw][:due_at]).to be_a(Time)
        end
      end

      context "only some sections have overrides" do
        let(:dates_visible) { dates_visible_to_user[1..] }

        before do
          allow(assignment.context).to receive(:active_section_count)
            .and_return sections.count
          allow(assignment).to receive(:all_dates_visible_to).with(user)
                                                             .and_return dates_visible
          @visible_due_dates = presenter.visible_due_dates
        end

        it "includes the default due date" do
          expect(visible_due_dates.detect { |due_date| due_date[:base] == true })
            .not_to be_nil
        end
      end
    end

    context "with standardize_assignment_date_formatting enabled" do
      before do
        Account.site_admin.enable_feature!(:standardize_assignment_date_formatting)
      end

      attr_reader :visible_due_dates

      def dates_visible_to_user
        [
          { due_at: "", lock_at: nil, unlock_at: nil, set_type: "CourseSection" },
          { due_at: 1.hour.from_now, lock_at: nil, unlock_at: nil, set_type: "CourseSection" },
          { due_at: 2.hours.from_now, lock_at: nil, unlock_at: nil, set_type: "CourseSection" },
          { due_at: 1.hour.ago, lock_at: nil, unlock_at: nil, base: true }
        ]
      end

      it "returns empty array if assignment is not present" do
        presenter = OverrideListPresenter.new nil, user
        expect(presenter.visible_due_dates).to eq []
      end

      context "with assignment present as a teacher" do
        before do
          @section1 = course.course_sections.create! name: "section 1"
          @section2 = course.course_sections.create! name: "section 2"
          @overridden_assignment = course.assignments.create!(title: "Overridden Assignment")
          @teacher = teacher_in_course(course:, name: "Testing").user
          allow(AssignmentOverrideApplicator).to receive(:assignment_overridden_for)
            .with(@overridden_assignment, @teacher).and_return @overridden_assignment
          @presenter = OverrideListPresenter.new @overridden_assignment, @teacher
        end

        context "when all sections have overrides" do
          before do
            @overridden_assignment.assignment_overrides.create!(set: @section1)
            @overridden_assignment.assignment_overrides.create!(set: @section2, due_at: 1.hour.from_now)
            @overridden_assignment.assignment_overrides.create!(set: course.default_section, due_at: 2.hours.from_now)
            @overridden_assignment.due_at = 1.hour.ago
            @overridden_assignment.save!

            @visible_due_dates = @presenter.visible_due_dates
          end

          it "doesn't include the default due date" do
            expect(visible_due_dates.length).to eq 3
            visible_due_dates.each do |override|
              expect(override[:base]).not_to be_truthy
            end
          end

          it "sorts due dates by due_at, placing not present?/nil after dates" do
            expect(visible_due_dates.first[:due_at]).to eq(
              presenter.formatted_date_string(:due_at, dates_visible_to_user.second)
            )
            expect(visible_due_dates.second[:due_at]).to eq(
              presenter.formatted_date_string(:due_at, dates_visible_to_user.third)
            )
            expect(visible_due_dates.third[:due_at]).to eq(
              presenter.formatted_date_string(:due_at, dates_visible_to_user.first)
            )
          end

          it "includes the actual Time for presentation transforms in templates" do
            expect(visible_due_dates.second[:raw][:due_at]).to be_a(Time)
          end
        end

        context "only some sections have overrides" do
          before do
            @overridden_assignment.assignment_overrides.create!(set: @section2, due_at: 1.day.from_now)
            @overridden_assignment.due_at = 2.days.ago
            @overridden_assignment.save!

            @visible_due_dates = @presenter.visible_due_dates
          end

          it "includes the default due date" do
            expect(visible_due_dates.detect { |due_date| due_date[:due_for] == "Everyone else" })
              .not_to be_nil
          end
        end

        context "with module overrides" do
          before do
            @module = course.context_modules.create!(name: "Module 1")
            @module.add_item(type: "assignment", id: @overridden_assignment.id)
            @module.assignment_overrides.create!(set: @section1)
            @overridden_assignment.due_at = 2.days.ago
            @overridden_assignment.save!

            @visible_due_dates = @presenter.visible_due_dates
          end

          it "does not include the default due date" do
            expect(visible_due_dates.detect { |due_date| due_date[:due_for] == "Everyone else" })
              .to be_nil
          end

          it "includes the module overrides" do
            expect(visible_due_dates.detect { |due_date| due_date[:due_for] == "1 Section" })
              .not_to be_nil
          end

          it "does not duplicate overwritten module overrides" do
            @overridden_assignment.assignment_overrides.create!(set: @section1, due_at: 1.day.from_now)
            @overridden_assignment.due_at = 2.days.ago
            @overridden_assignment.save!
            @visible_due_dates = @presenter.visible_due_dates

            expect(visible_due_dates.length).to eq 1
            expect(visible_due_dates.first[:due_for]).to eq "1 Section"
            expect(visible_due_dates.first[:due_at]).to_not be_nil
          end

          it "ignores unassigned module overrides" do
            @module.assignment_overrides.create!(set: @section2)
            @overridden_assignment.assignment_overrides.create!(set: @section2, unassign_item: true)

            @visible_due_dates = @presenter.visible_due_dates
            expect(visible_due_dates.length).to eq 1
            expect(visible_due_dates.first[:due_for]).to eq "1 Section"
          end

          it "includes Course overrides" do
            @overridden_assignment.assignment_overrides.create!(set: course, due_at: 1.hour.from_now)
            @overridden_assignment.due_at = 2.days.ago
            @overridden_assignment.save!

            @visible_due_dates = @presenter.visible_due_dates
            expect(visible_due_dates.length).to eq 2
            expect(visible_due_dates.detect do |due_date|
              due_date[:due_for] == "Everyone else" &&
              due_date[:due_at] == presenter.formatted_date_string(:due_at, dates_visible_to_user.second)
            end)
              .not_to be_nil
          end
        end
      end
    end
  end

  describe "#formatted_due_for" do
    context "when standardize_assignment_date_formatting feature is disabled" do
      before do
        Account.site_admin.disable_feature!(:standardize_assignment_date_formatting)
      end

      context "with everyone option" do
        it "returns 'Everyone' when no other due dates exist" do
          formatted_override = { options: ["everyone"] }
          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq "Everyone"
        end

        it "returns 'Everyone else' when other due dates exist" do
          formatted_override = { options: ["everyone"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: true)
          expect(result).to eq "Everyone else"
        end
      end

      context "pluralization" do
        it "does not pluralize for single section, group, differentiation tag and student" do
          formatted_override = { options: %w[section-1 group-1 tag-1 student-1] }
          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq "1 Section, 1 Group, 1 Tag, 1 Student"
        end

        it "pluralizes for multiple sections, groups, differentiation tags and students" do
          formatted_override = { options: %w[section-1 section-2 group-1 group-2 tag-1 tag-2 student-1 student-2] }
          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq "2 Sections, 2 Groups, 2 Tags, 2 Students"
        end
      end

      context "with mastery paths option" do
        it "returns mastery paths text" do
          formatted_override = { options: ["mastery_paths"] }
          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq "Mastery Paths"
        end
      end

      context "with mixed options" do
        it "returns all option types including mastery paths" do
          formatted_override = { options: %w[everyone section-1 group-1 tag-1 student-1 mastery_paths] }
          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq "Everyone else, 1 Section, 1 Group, 1 Tag, 1 Student, Mastery Paths"
        end
      end

      context "with no options" do
        it "returns empty string" do
          formatted_override = { options: [] }
          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq ""
        end
      end

      context "with invalid options" do
        it "processes only valid options and ignores invalid ones" do
          formatted_override = { options: %w[invalid-option section-1 tag-123 bad-format] }
          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq "1 Section, 1 Tag"
        end
      end

      context "with differentiation tags overrides" do
        it "formats single tag override correctly" do
          formatted_override = {
            options: ["tag-123"]
          }

          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq("1 Tag")
        end

        it "formats multiple tag overrides correctly" do
          formatted_override = {
            options: %w[tag-123 tag-456 tag-789]
          }

          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq("3 Tags")
        end

        it "formats mixed overrides with tags correctly" do
          formatted_override = {
            options: %w[section-1 tag-123 tag-456 group-1]
          }

          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq("1 Section, 1 Group, 2 Tags")
        end

        it "handles 'Everyone else' with tags" do
          formatted_override = {
            options: ["everyone", "tag-123"]
          }

          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq("Everyone else, 1 Tag")
        end

        it "handles complex override with all types including tags" do
          formatted_override = {
            options: %w[section-1 section-2 group-1 tag-123 tag-456 tag-789 student-1 mastery_paths]
          }

          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq("2 Sections, 1 Group, 3 Tags, 1 Student, Mastery Paths")
        end

        it "correctly identifies tag options with regex pattern" do
          formatted_override = {
            options: ["tag-12345", "not-a-tag", "tag-", "tag-abc", "tag-999"]
          }

          # Only "tag-12345" and "tag-999" should match the pattern /\Atag-\d+\z/
          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq("2 Tags")
        end
      end
    end

    context "when standardize_assignment_date_formatting feature is enabled" do
      before do
        Account.site_admin.enable_feature!(:standardize_assignment_date_formatting)
      end

      context "with everyone option" do
        it "returns 'Everyone' when no other due dates exist" do
          formatted_override = { options: ["Course"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("Everyone")
        end

        it "returns 'Everyone else' when other due dates exist" do
          formatted_override = { options: ["Course"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: true)
          expect(result).to eq("Everyone else")
        end

        it "handles nil option as everyone" do
          formatted_override = { options: [nil] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("Everyone")
        end
      end

      context "with section options" do
        it "returns singular section count" do
          formatted_override = { options: ["CourseSection"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("1 Section")
        end

        it "returns plural section count" do
          formatted_override = { options: %w[CourseSection CourseSection CourseSection] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("3 Sections")
        end
      end

      context "with group options" do
        it "returns singular group count" do
          formatted_override = { options: ["Group"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("1 Group")
        end

        it "returns plural group count" do
          formatted_override = { options: ["Group", "Group"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("2 Groups")
        end
      end

      context "with tag options" do
        it "returns singular tag count" do
          formatted_override = { options: ["Tag"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("1 Tag")
        end

        it "returns plural tag count" do
          formatted_override = { options: %w[Tag Tag Tag] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("3 Tags")
        end
      end

      context "with student options" do
        it "returns singular student count" do
          formatted_override = { options: ["student1"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("1 Student")
        end

        it "returns plural student count" do
          formatted_override = { options: ["student5"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("5 Students")
        end

        it "sums multiple student counts" do
          formatted_override = { options: ["student3", "student2"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("5 Students")
        end

        it "handles student options without numbers" do
          formatted_override = { options: ["student"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("")
        end
      end

      context "with mastery paths option" do
        it "returns mastery paths text" do
          formatted_override = { options: ["Noop"] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("Mastery Paths")
        end
      end

      context "with mixed options" do
        it "combines multiple option types correctly" do
          formatted_override = { options: %w[Course CourseSection Group Tag student3 Noop] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: true)
          expect(result).to eq("Everyone else, 1 Section, 1 Group, 1 Tag, 3 Students, Mastery Paths")
        end

        it "combines multiple counts of same type" do
          formatted_override = { options: %w[CourseSection CourseSection Group Group Group] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("2 Sections, 3 Groups")
        end
      end

      context "with no options" do
        it "returns empty string" do
          formatted_override = { options: [] }
          result = presenter.formatted_due_for(formatted_override)
          expect(result).to eq("")
        end
      end

      context "with invalid/unknown options" do
        it "ignores unknown options" do
          formatted_override = { options: %w[UnknownType CourseSection InvalidOption] }
          result = presenter.formatted_due_for(formatted_override, other_due_dates_exist: false)
          expect(result).to eq("1 Section")
        end
      end
    end
  end

  context "non-collaborative groups" do
    let!(:collaborative_group_category) { course.group_categories.create!(name: "Collaborative Category") }
    let!(:non_collaborative_group_category) { course.group_categories.create!(name: "Non-Collaborative Category", non_collaborative: true) }
    let!(:collaborative_group) { collaborative_group_category.groups.create!(name: "Collaborative Group", context: course) }
    let!(:non_collaborative_group) { non_collaborative_group_category.groups.create!(name: "Non-Collaborative Group", context: course) }
    let!(:another_non_collaborative_group) { non_collaborative_group_category.groups.create!(name: "Another Non-Collaborative Group", context: course) }

    describe "#convert_non_collaborative_groups_to_tags" do
      it "returns empty array when given empty overrides" do
        result = presenter.convert_non_collaborative_groups_to_tags([])
        expect(result).to eq([])
      end

      it "leaves collaborative groups unchanged" do
        overrides = [
          {
            options: ["group-#{collaborative_group.id}", "section-123"],
            due_at: 1.day.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags(overrides)

        expect(result).to eq([
                               {
                                 options: ["group-#{collaborative_group.id}", "section-123"],
                                 due_at: 1.day.from_now
                               }
                             ])
      end

      it "converts non-collaborative groups to tags" do
        overrides = [
          {
            options: ["group-#{non_collaborative_group.id}", "section-123"],
            due_at: 1.day.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags(overrides)

        expect(result).to eq([
                               {
                                 options: ["tag-#{non_collaborative_group.id}", "section-123"],
                                 due_at: 1.day.from_now
                               }
                             ])
      end

      it "handles mixed collaborative and non-collaborative groups" do
        overrides = [
          {
            options: ["group-#{collaborative_group.id}", "group-#{non_collaborative_group.id}", "section-123"],
            due_at: 1.day.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags(overrides)

        expect(result).to eq([
                               {
                                 options: ["group-#{collaborative_group.id}", "tag-#{non_collaborative_group.id}", "section-123"],
                                 due_at: 1.day.from_now
                               }
                             ])
      end

      it "handles multiple overrides with different group types" do
        overrides = [
          {
            options: ["group-#{collaborative_group.id}"],
            due_at: 1.day.from_now
          },
          {
            options: ["group-#{non_collaborative_group.id}", "group-#{another_non_collaborative_group.id}"],
            due_at: 2.days.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags(overrides)

        expect(result).to eq([
                               {
                                 options: ["group-#{collaborative_group.id}"],
                                 due_at: 1.day.from_now
                               },
                               {
                                 options: ["tag-#{non_collaborative_group.id}", "tag-#{another_non_collaborative_group.id}"],
                                 due_at: 2.days.from_now
                               }
                             ])
      end

      it "ignores options that don't match group format" do
        overrides = [
          {
            options: %w[student-123 section-456 everyone invalid-format],
            due_at: 1.day.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags(overrides)

        expect(result).to eq([
                               {
                                 options: %w[student-123 section-456 everyone invalid-format],
                                 due_at: 1.day.from_now
                               }
                             ])
      end

      it "handles non-existent group IDs gracefully" do
        non_existent_group_id = Group.maximum(:id).to_i + 1000
        overrides = [
          {
            options: ["group-#{non_existent_group_id}", "section-123"],
            due_at: 1.day.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags(overrides)

        expect(result).to eq([
                               {
                                 options: ["group-#{non_existent_group_id}", "section-123"],
                                 due_at: 1.day.from_now
                               }
                             ])
      end

      it "optimizes database queries by batching group lookups" do
        overrides = [
          {
            options: ["group-#{non_collaborative_group.id}"],
            due_at: 1.day.from_now
          },
          {
            options: ["group-#{another_non_collaborative_group.id}"],
            due_at: 2.days.from_now
          }
        ]

        expect(Group).to receive(:non_collaborative).once.and_call_original

        presenter.convert_non_collaborative_groups_to_tags(overrides)
      end

      it "preserves all other override properties" do
        custom_property = "custom_value"
        overrides = [
          {
            options: ["group-#{non_collaborative_group.id}"],
            due_at: 1.day.from_now,
            lock_at: 2.days.from_now,
            unlock_at: 1.day.ago,
            custom_property:
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags(overrides)

        expect(result.first[:custom_property]).to eq(custom_property)
        expect(result.first[:due_at]).to eq(overrides.first[:due_at])
        expect(result.first[:lock_at]).to eq(overrides.first[:lock_at])
        expect(result.first[:unlock_at]).to eq(overrides.first[:unlock_at])
      end
    end

    describe "#convert_non_collaborative_groups_to_tags_v2" do
      it "returns empty array when given empty overrides" do
        result = presenter.convert_non_collaborative_groups_to_tags_v2([])
        expect(result).to eq([])
      end

      it "converts non-collaborative groups to tags" do
        overrides = [
          {
            set_type: "Group",
            set_id: non_collaborative_group.id,
            due_at: 1.day.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags_v2(overrides)

        expect(result.first[:set_type]).to eq("Tag")
        expect(result.first[:set_id]).to eq(non_collaborative_group.id)
      end

      it "leaves collaborative groups unchanged" do
        overrides = [
          {
            set_type: "Group",
            set_id: collaborative_group.id,
            due_at: 1.day.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags_v2(overrides)

        expect(result.first[:set_type]).to eq("Group")
        expect(result.first[:set_id]).to eq(collaborative_group.id)
      end

      it "handles mixed override types correctly" do
        section = course.course_sections.create!(name: "Test Section")
        overrides = [
          {
            set_type: "Group",
            set_id: non_collaborative_group.id,
            due_at: 1.day.from_now
          },
          {
            set_type: "Group",
            set_id: collaborative_group.id,
            due_at: 2.days.from_now
          },
          {
            set_type: "CourseSection",
            set_id: section.id,
            due_at: 3.days.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags_v2(overrides)

        expect(result[0][:set_type]).to eq("Tag") # non-collaborative group converted
        expect(result[1][:set_type]).to eq("Group") # collaborative group unchanged
        expect(result[2][:set_type]).to eq("CourseSection") # section unchanged
      end

      it "preserves all other override attributes" do
        due_date = 1.day.from_now
        overrides = [
          {
            set_type: "Group",
            set_id: non_collaborative_group.id,
            due_at: due_date,
            unlock_at: 1.hour.ago,
            lock_at: 2.days.from_now,
            title: "Test Override"
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags_v2(overrides)

        expect(result.first[:set_type]).to eq("Tag")
        expect(result.first[:set_id]).to eq(non_collaborative_group.id)
        expect(result.first[:due_at]).to eq(due_date)
        expect(result.first[:unlock_at]).to eq(overrides.first[:unlock_at])
        expect(result.first[:lock_at]).to eq(overrides.first[:lock_at])
        expect(result.first[:title]).to eq("Test Override")
      end

      it "handles non-existent group IDs gracefully" do
        non_existent_id = Group.maximum(:id).to_i + 1
        overrides = [
          {
            set_type: "Group",
            set_id: non_existent_id,
            due_at: 1.day.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags_v2(overrides)

        expect(result.first[:set_type]).to eq("Group") # unchanged since group doesn't exist
        expect(result.first[:set_id]).to eq(non_existent_id)
      end

      it "ignores non-Group override types" do
        section = course.course_sections.create!(name: "Test Section")
        overrides = [
          {
            set_type: "CourseSection",
            set_id: section.id,
            due_at: 1.day.from_now
          },
          {
            set_type: "Course",
            set_id: course.id,
            due_at: 2.days.from_now
          }
        ]

        result = presenter.convert_non_collaborative_groups_to_tags_v2(overrides)

        expect(result[0][:set_type]).to eq("CourseSection")
        expect(result[1][:set_type]).to eq("Course")
      end
    end
  end
end
