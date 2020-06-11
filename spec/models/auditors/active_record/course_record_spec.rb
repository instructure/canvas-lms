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

describe Auditors::ActiveRecord::CourseRecord do
  let(:request_id){ 'abcde-12345'}

  it "it appropriately connected to a table" do
    expect(Auditors::ActiveRecord::CourseRecord.count).to eq(0)
  end

  describe "mapping from event stream record" do
    let(:course_enrollment){ course_with_student }
    let(:course_record){ course_enrollment.course }
    let(:user_record){ course_enrollment.user }
    let(:event_data){ {"data-key" => "data-val"} }
    let(:es_record){ Auditors::Course::Record.generate(course_record, user_record, 'unconcluded', event_data) }

    it "is creatable from an event_stream record of the correct type" do
      ar_rec = Auditors::ActiveRecord::CourseRecord.create_from_event_stream!(es_record)
      expect(ar_rec.id).to_not be_nil
      expect(ar_rec.uuid).to eq(es_record.id)
      expect(ar_rec.course_id).to eq(course_record.id)
      expect(ar_rec.user_id).to eq(user_record.id)
      expect(ar_rec.event_source).to eq("manual")
      expect(ar_rec.event_type).to eq("unconcluded")
      expect(ar_rec.event_data).to eq({"data-key" => "data-val"})
      expect(ar_rec.sis_batch_id).to be_nil
      expect(ar_rec.created_at).to_not be_nil
    end

    it "is updatable from ES record" do
      ar_rec = Auditors::ActiveRecord::CourseRecord.create_from_event_stream!(es_record)
      es_record.request_id = "aaa-111-bbb-222"
      Auditors::ActiveRecord::CourseRecord.update_from_event_stream!(es_record)
      expect(ar_rec.reload.request_id).to eq("aaa-111-bbb-222")
    end
  end
end