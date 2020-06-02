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

require_relative '../spec_helper'

describe CustomGradebookColumnDatum do
  before(:once) do
    course_with_teacher(active_all: true)
  end

  describe "process_bulk_update_custom_columns" do
    before(:once) do
      @first_student = student_in_course(active_all: true, course: @course).user
      @second_student = student_in_course(active_all: true, course: @course).user
      @first_col = @course.custom_gradebook_columns.create!(title: "cc1", position: 1)
      @second_col = @course.custom_gradebook_columns.create!(title: "cc2", position: 2)

      CustomGradebookColumnDatum.process_bulk_update_custom_columns({}, @course, [
        {
          "column_id": @first_col.id.to_s,
          "user_id": @first_student.id.to_s,
          "content": "first column, first student"
        },
        {
          "column_id": @first_col.id.to_s,
          "user_id": @second_student.id.to_s,
          "content": "first column, second student"
        },
        {
          "column_id": @second_col.id.to_s,
          "user_id": @first_student.id.to_s,
          "content": "second column, first student"
        },
        {
          "column_id": @second_col.id.to_s,
          "user_id": @second_student.id.to_s,
          "content": "second column, second student"
        }
      ])
    end

    let(:first_student_data) do
      @course.custom_gradebook_columns.
        find_by!(id: @first_col.id).
        custom_gradebook_column_data.
        find_by(user_id: @first_student.id)
    end

    it "sets the root account id on the column datum" do
      expect(first_student_data.root_account_id).to eq @course.root_account.id
    end

    it "adds a datum for a matching student and column" do
      data = @course.custom_gradebook_columns.
        find_by!(id: @first_col.id).
        custom_gradebook_column_data.
        where(user_id: @first_student.id)
      expect(data.count).to be 1
    end

    it "checks content exists for the first student in the first column" do
      expect(first_student_data.content).to eql "first column, first student"
    end

    it "adds data for multiple students for a column" do
      data = @course.custom_gradebook_columns.find_by!(id: @first_col.id).custom_gradebook_column_data
      expect(data.count).to be 2
    end

    it "adds data for multiple columns" do
      data = @course.custom_gradebook_columns.where(id: [@first_col.id, @second_col.id])
      expect(data.count).to be 2
    end

    it "does not create new columns when column doesn't exist" do
      CustomGradebookColumnDatum.process_bulk_update_custom_columns({}, @course, [
        {
          "column_id": (@second_col.id + 1001).to_s,
          "user_id": @second_student.id.to_s,
          "content": "first column, second student"
        },
      ])

      data = @course.custom_gradebook_columns.where(id: @second_col.id + 1001)
      expect(data.count).to be 0
    end

    it "updates the content for existing student and column" do
      CustomGradebookColumnDatum.process_bulk_update_custom_columns({}, @course, [
        {
          "column_id": @second_col.id.to_s,
          "user_id": @second_student.id.to_s,
          "content": "2, 2"
        }
      ])

      data = @course.custom_gradebook_columns.find_by!(id: @second_col.id).
        custom_gradebook_column_data.find_by!(user_id: @second_student.id).content
      expect(data).to eql "2, 2"
    end

    it "can also pass the column ID as a number" do
      CustomGradebookColumnDatum.process_bulk_update_custom_columns({}, @course, [
        {
          "column_id": @second_col.id,
          "user_id": @second_student.id,
          "content": "2, 2"
        }
      ])

      data = @course.custom_gradebook_columns.find_by!(id: @second_col.id).
        custom_gradebook_column_data.find_by!(user_id: @second_student.id).content
      expect(data).to eql "2, 2"
    end

    it "does not update content in deleted columns" do
      @course.custom_gradebook_columns.find_by!(id: @second_col.id).
        custom_gradebook_column_data.find_by!(user_id: @first_student.id).delete
      @course.custom_gradebook_columns.find_by!(id: @second_col.id).
        custom_gradebook_column_data.find_by!(user_id: @second_student.id).delete
      @course.custom_gradebook_columns.find_by!(id: @second_col.id).delete

      CustomGradebookColumnDatum.process_bulk_update_custom_columns({}, @course, [
        {
          "column_id": @second_col.id.to_s,
          "user_id": @second_student.id.to_s,
          "content": "3, 2"
        },
      ])

      data = @course.custom_gradebook_columns.where(id: @second_col.id)
      expect(data.count).to be 0
    end

    it "destroys data when uploading empty string" do
      CustomGradebookColumnDatum.process_bulk_update_custom_columns({}, @course, [
        {
          "column_id": @first_col.id.to_s,
          "user_id": @first_student.id.to_s,
          "content": ""
        },
      ])

      expect(first_student_data).to be_nil
    end
  end

  describe "root_account_id" do
    before(:once) do
      @column = @course.custom_gradebook_columns.create!(title: "cc1", position: 1)
      @student = student_in_course(active_all: true, course: @course).user
    end

    context "on create" do
      it "sets root_account_id to the course's root_account_id if root_account_id is nil" do
        datum = @column.custom_gradebook_column_data.create!(content: "some content", user_id: @student.id)
        expect(datum.root_account_id).to eq @course.root_account_id
      end

      it "does not modify root_account_id if it is already set" do
        second_account = account_model
        datum = @column.custom_gradebook_column_data.create!(
          content: "some content",
          user_id: @student.id,
          root_account_id: second_account.id
        )
        expect(datum.root_account_id).to eq second_account.id
      end
    end

    context "on update" do
      it "sets root_account_id to the course's root_account_id if root_account_id is nil" do
        datum = @column.custom_gradebook_column_data.create!(content: "some content", user_id: @student.id)
        datum.update_column(:root_account_id, nil)
        datum.update!(content: "some new content")
        expect(datum.root_account_id).to eq @course.root_account_id
      end

      it "does not modify root_account_id if it is already set" do
        second_account = account_model
        datum = @column.custom_gradebook_column_data.create!(
          content: "some content",
          user_id: @student.id,
          root_account_id: second_account.id
        )
        datum.update!(content: "some new content")
        expect(datum.root_account_id).to eq second_account.id
      end
    end
  end
end
