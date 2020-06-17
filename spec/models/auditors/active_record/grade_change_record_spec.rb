#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../sharding_spec_helper.rb')

describe Auditors::ActiveRecord::GradeChangeRecord do
  let(:request_id){ 'abcde-12345'}

  it "it appropriately connected to a table" do
    expect(Auditors::ActiveRecord::GradeChangeRecord.count).to eq(0)
  end

  describe "mapping from event stream record" do
    let(:submission_record){ graded_submission_model }
    let(:es_record){ Auditors::GradeChange::Record.generate(submission_record) }

    it "is creatable from an event_stream record of the correct type" do
      ar_rec = Auditors::ActiveRecord::GradeChangeRecord.create_from_event_stream!(es_record)
      expect(ar_rec.id).to_not be_nil
      expect(ar_rec.uuid).to eq(es_record.id)
      course = submission_record.assignment.context
      expect(ar_rec.grade_after).to eq(es_record.grade_after)
      expect(ar_rec.account_id).to eq(course.account.id)
      expect(ar_rec.root_account_id).to eq(course.account.root_account.id)
      expect(ar_rec.assignment_id).to eq(submission_record.assignment_id)
      expect(ar_rec.event_type).to eq("grade_change")
      expect(ar_rec.context_id).to eq(course.id)
      expect(ar_rec.course_id).to eq(course.id)
      expect(ar_rec.context_type).to eq('Course')
      expect(ar_rec.grader_id).to eq(submission_record.grader_id)
      expect(ar_rec.student_id).to eq(submission_record.user_id)
      expect(ar_rec.submission_id).to eq(submission_record.id)
      expect(ar_rec.submission_version_number).to eq(submission_record.version_number)
      expect(ar_rec.version_number).to eq(submission_record.version_number)
      expect(ar_rec.created_at).to_not be_nil
    end

    it "is updatable from ES record" do
      ar_rec = Auditors::ActiveRecord::GradeChangeRecord.create_from_event_stream!(es_record)
      es_record.request_id = "aaa-111-bbb-222"
      Auditors::ActiveRecord::GradeChangeRecord.update_from_event_stream!(es_record)
      expect(ar_rec.reload.request_id).to eq("aaa-111-bbb-222")
    end
  end
end