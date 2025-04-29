# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../common"

describe "Alerts" do
  include_context "in-process server selenium tests"

  shared_examples "alert CRUD and validation" do
    it("should render an existing alert correctly") do
      alert = @alerts.create!(
        recipients: [:student, :teachers],
        criteria: [{ criterion_type: "Interaction", threshold: 1 }, { criterion_type: "UngradedCount", threshold: 2 }, { criterion_type: "UngradedTimespan", threshold: 3 }],
        repetition: 1
      )
      get page_url
      f("#tab-alerts").click

      alerts = f("[data-testid='alerts']")
      expect(alerts).to include_text("A teacher has not interacted with the student for #{alert.criteria[0].threshold.to_i} days.")
      expect(alerts).to include_text("More than #{alert.criteria[1].threshold.to_i} submissions have not been graded.")
      expect(alerts).to include_text("A submission has been left ungraded for #{alert.criteria[2].threshold.to_i} days.")
      expect(alerts).to include_text("Student")
      expect(alerts).to include_text("Teacher")
      expect(alerts).to include_text("Every #{alert.repetition} days until resolved.")
    end

    it "should be able to create a new alert" do
      get page_url
      f("#tab-alerts").click
      f("[aria-label='Create new alert']").click

      tray = f("[aria-label='New Alert']")
      add_trigger = tray.find_element(:css, "[aria-label='Add trigger']")
      3.times { add_trigger.click }
      tray.find_element(:css, "[type='checkbox'][value=':student'] + label").click
      tray.find_element(:css, "[type='checkbox'][value=':teachers'] + label").click
      tray.find_element(:css, "[type='checkbox'][name='doNotResend'] + label").click
      tray.find_element(:css, "[type='submit']").click

      expect(@alerts.last.reload).to have_attributes(
        recipients: [:student, :teachers],
        repetition: 1,
        criteria: contain_exactly(
          have_attributes(criterion_type: "Interaction", threshold: 7.0),
          have_attributes(criterion_type: "UngradedCount", threshold: 3.0),
          have_attributes(criterion_type: "UngradedTimespan", threshold: 7.0)
        )
      )
    end

    it "should be able to delete an existing alert" do
      @alerts.create!(
        recipients: [:student, :teachers],
        criteria: [{ criterion_type: "Interaction", threshold: 1 }, { criterion_type: "UngradedCount", threshold: 2 }, { criterion_type: "UngradedTimespan", threshold: 3 }],
        repetition: 1
      )
      get page_url
      f("#tab-alerts").click

      alerts = f("[data-testid='alerts']")
      alerts.find_element(:css, "[aria-label='Delete alert button']").click

      expect(@alerts.reload).to be_empty
    end

    it "should be able to update an existing alert" do
      alert = @alerts.create!(
        recipients: [:student, :teachers],
        criteria: [{ criterion_type: "Interaction", threshold: 1 }, { criterion_type: "UngradedCount", threshold: 2 }, { criterion_type: "UngradedTimespan", threshold: 3 }],
        repetition: 1
      )
      get page_url
      f("#tab-alerts").click

      alerts = f("[data-testid='alerts']")
      alerts.find_element(:css, "[aria-label='Edit alert button']").click
      tray = f("[aria-label='Edit Alert']")
      tray.find_element(:css, "#no_teacher_interaction").send_keys([:control, "a"], "4")
      tray.find_element(:css, "#ungraded_submissions_count").send_keys([:control, "a"], "5")
      tray.find_element(:css, "#ungraded_submissions_time").send_keys([:control, "a"], "6")
      tray.find_element(:css, "[type='checkbox'][value=':teachers'] + label").click
      tray.find_element(:css, "[type='checkbox'][name='doNotResend'] + label").click
      tray.find_element(:css, "[type='submit']").click

      expect(alert.reload).to have_attributes(
        recipients: [:student],
        repetition: nil,
        criteria: contain_exactly(
          have_attributes(criterion_type: "Interaction", threshold: 4.0),
          have_attributes(criterion_type: "UngradedCount", threshold: 5.0),
          have_attributes(criterion_type: "UngradedTimespan", threshold: 6.0)
        )
      )
    end

    it "should show validation errors if the form invalid" do
      get page_url
      f("#tab-alerts").click
      f("[aria-label='Create new alert']").click

      tray = f("[aria-label='New Alert']")
      tray.find_element(:css, "[type='submit']").click

      expect(tray).to include_text("Please add at least one trigger.")
      expect(tray).to include_text("Please select at least one option.")
    end
  end

  context "when context is Account" do
    before do
      admin_logged_in
      @context = Account.default
      @context.settings[:enable_alerts] = true
      @context.save!
      @alerts = @context.alerts
      stub_rcs_config
    end

    let(:page_url) { "/accounts/#{@context.id}/settings" }

    include_examples "alert CRUD and validation"

    it "should show and be able to edit alert with custom role" do
      custom_role = custom_account_role("Custom role", account: @context)
      alert = @alerts.create!(recipients: [{ role_id: custom_role.id }, :student], criteria: [{ criterion_type: "Interaction", threshold: 7 }])
      get page_url
      f("#tab-alerts").click

      alerts = f("[data-testid='alerts']")
      expect(alerts).to include_text(custom_role.name)

      alerts.find_element(:css, "[aria-label='Edit alert button']").click
      tray = f("[aria-label='Edit Alert']")
      tray.find_element(:css, "[type='checkbox'][value='#{custom_role.id}'] + label").click
      tray.find_element(:css, "[type='submit']").click

      expect(alert.reload.recipients).not_to include(custom_role.id)
    end
  end

  context "when context is Course" do
    before do
      account = Account.default
      account.settings[:enable_alerts] = true
      account.save!
      course_with_admin_logged_in(account:)
      @context = @course
      @alerts = @context.alerts
      stub_rcs_config
    end

    let(:page_url) { "/courses/#{@context.id}/settings" }

    include_examples "alert CRUD and validation"
  end
end
