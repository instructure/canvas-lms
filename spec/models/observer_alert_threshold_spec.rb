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

require_relative "../spec_helper"

describe ObserverAlertThreshold do
  before :once do
    @student = user_model
    @observer = user_model
    add_linked_observer(@student, @observer)
  end

  it "can link to an user_observation_link" do
    threshold = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_missing")

    expect(threshold.valid?).to be true
    expect(threshold.user_id).not_to be_nil
    expect(threshold.observer_id).not_to be_nil
  end

  it "wont allow random alert_type" do
    threshold = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "jigglypuff")

    expect(threshold.valid?).to be false
  end

  it "observer must be linked to student" do
    threshold = ObserverAlertThreshold.create(student: user_model, observer: @observer, alert_type: "assignment_missing")

    expect(threshold.valid?).to be false
  end

  it "wont allow random threshold" do
    threshold = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_grade_high", threshold: "jigglypuff")

    expect(threshold.valid?).to be false
  end

  it "wont allow threshold over the max" do
    threshold = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_grade_high", threshold: 101)

    expect(threshold.valid?).to be false
  end

  it "wont allow threshold over the min" do
    threshold = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_grade_high", threshold: "-1")

    expect(threshold.valid?).to be false
  end

  it "allows creating a high and low threshold as long as the high is not lower than the low" do
    threshold_one = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_grade_high", threshold: "80")
    threshold_two = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_grade_low", threshold: 60)

    expect(threshold_one.valid?).to be true
    expect(threshold_two.valid?).to be true
  end

  it "wont allow creating a low threshold that is higher than the high threshold" do
    threshold_one = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_grade_high", threshold: "80")
    threshold_two = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_grade_low", threshold: "80")
    threshold_three = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_grade_low", threshold: 100)

    expect(threshold_one.valid?).to be true
    expect(threshold_two.valid?).to be false
    expect(threshold_three.valid?).to be false
  end

  it "wont allow creating a high threshold that is lower than the low threshold" do
    threshold_one = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "course_grade_low", threshold: "40")
    threshold_two = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "course_grade_high", threshold: "40")
    threshold_three = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "course_grade_high", threshold: 30)

    expect(threshold_one.valid?).to be true
    expect(threshold_two.valid?).to be false
    expect(threshold_three.valid?).to be false
  end

  it "wont allow adding a threshold to an alert_type that does not support it" do
    threshold = ObserverAlertThreshold.create(student: @student, observer: @observer, alert_type: "assignment_missing", threshold: "40")

    expect(threshold.valid?).to be false
  end
end
