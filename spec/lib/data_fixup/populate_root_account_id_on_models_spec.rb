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

require 'spec_helper'

describe DataFixup::PopulateRootAccountIdOnModels do
  before :once do
    course_model
    @cm = @course.context_modules.create!
    @cm.update_columns(root_account_id: nil)
  end

  # add additional models here as they are calculated and added to migration_tables.
  context 'models' do
    it 'should populate the root_account_id on AccountUser' do
      au = AccountUser.create!(account: @course.account, user: user_model)
      au.update_columns(root_account_id: nil)
      expect(au.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(au.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should populate the root_account_id on ContextModule' do
      expect(@cm.root_account_id).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@cm.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should populate the root_account_id on DeveloperKey' do
      dk = DeveloperKey.create!(account: @course.account)
      dk.update_columns(root_account_id: nil)
      expect(dk.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(dk.reload.root_account_id).to eq @course.root_account_id

      account = account_model(root_account: account_model)
      dk = DeveloperKey.create!(account: account)
      dk.update_columns(root_account_id: nil)
      expect(dk.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(dk.reload.root_account_id).to eq account.root_account_id
    end

    it 'should populate the root_account_id on DeveloperKeyAccountBinding' do
      account_model
      dk = DeveloperKey.create!(account: @course.account)
      dkab = DeveloperKeyAccountBinding.create!(account: @account, developer_key: dk)
      dkab.update_columns(root_account_id: nil)
      expect(dkab.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(dkab.reload.root_account_id).to eq @account.id
    end

    it 'should populate the root_account_id on DiscussionTopic' do
      discussion_topic_model(context: @course)
      @topic.update_columns(root_account_id: nil)
      expect(@topic.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@topic.reload.root_account_id).to eq @course.root_account_id

      discussion_topic_model(context: group_model)
      @topic.update_columns(root_account_id: nil)
      expect(@topic.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@topic.reload.root_account_id).to eq @group.root_account_id
    end

    it 'should populate the root_account_id on DiscussionTopicParticipants' do
      discussion_topic_model
      dtp = @topic.discussion_topic_participants.create!(user: user_model)
      dtp.update_columns(root_account_id: nil)
      expect(dtp.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(dtp.reload.root_account_id).to eq @topic.root_account_id
    end

    it 'should populate the root_account_id on MasterCourse::MasterTemplate' do
      mcmt = MasterCourses::MasterTemplate.create(course: @course)
      mcmt.update_columns(root_account_id: nil)
      expect(mcmt.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(mcmt.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should populate the root_account_id on Quizzes::Quiz' do
      quiz_model(course: @course)
      @quiz.update_columns(root_account_id: nil)
      expect(@quiz.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@quiz.reload.root_account_id).to eq @course.root_account_id
    end
  end

  describe '#run' do
    it 'should create delayed jobs to backfill root_account_ids for the table' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:send_later_if_production_enqueue_args)
      DataFixup::PopulateRootAccountIdOnModels.run
    end
  end

  describe '#clean_and_filter_tables' do
    it 'should remove tables from the hash that were backfilled a while ago' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({Assignment => :course, ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should remove tables from the hash that are in progress' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({ContentTag => :context, ContextModule => :course})
      DataFixup::PopulateRootAccountIdOnModels.send_later_enqueue_args(:populate_root_account_ids,
        {
          priority: Delayed::MAX_PRIORITY,
          n_strand: ["root_account_id_backfill", Shard.current.database_server.id],
          tag: ContentTag
        },
        ContentTag, {course: :root_account_id}, 1, 2)
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should replace polymorphic associations with direction associations' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({ContextModule => :context})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should remove tables from the hash that have all their root account ids filled in' do
      DeveloperKey.create!(account: @course.account)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({DeveloperKey => :account, ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should remove tables if all the objects with given associations have root_account_ids, even if some objects do not' do
      ContentTag.create!(assignment: assignment_model, root_account_id: @assignment.root_account_id)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({ContentTag => :assignment, ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should filter tables whose prereqs are not filled with root_account_ids' do
      OriginalityReport.create!(submission: submission_model)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({OriginalityReport => :submission, ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should not filter tables whose prereqs are filled with root_account_ids' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end
  end

  describe '#hash_association' do
    it 'should build a hash association when only given a table name' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association(:assignment)).to eq(
        {assignment: :root_account_id}
      )
    end

    it 'should build a hash association when only given a hash' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association({assignment: :id})).to eq(
        {assignment: :id}
      )
    end

    it 'should build a hash association when given an array of strings/symbols' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association([:submission, :assignment])).to eq(
        {submission: :root_account_id, assignment: :root_account_id}
      )
    end

    it 'should build a hash association when given an array of hashes' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association([{submission: :id}, {assignment: :id}])).to eq(
        {submission: :id, assignment: :id}
      )
    end

    it 'should build a hash association when given a mixed array' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association([{submission: :id}, :assignment])).to eq(
        {submission: :id, assignment: :root_account_id}
      )
    end

    it 'should turn string associations/columns into symbols' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association(
        [{'submission' => ['root_account_id', 'id']}, 'assignment']
      )).to eq({submission: [:root_account_id, :id], assignment: :root_account_id})
    end
  end

  describe '#replace_polymorphic_associations' do
    it 'should leave non-polymorphic associations alone' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(ContextModule,
        {course: :root_account_id})).to eq({course: :root_account_id})
    end

    it 'should replace polymorphic associations in the hash (in original order)' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
        ContentTag, {context: [:root_account_id, :id], context_module: :root_account_id}
      )).to eq(
        {
          course: [:root_account_id, :id],
          learning_outcome_group: [:root_account_id, :id],
          assignment: [:root_account_id, :id],
          account: [:root_account_id, :id],
          quiz: [:root_account_id, :id],
          context_module: :root_account_id
        }
      )
    end

    it 'should allow overwriting for a previous association included in a polymorphic association' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
        ContentTag, {context: :root_account_id, course: [:root_account_id, :id]}
      )).to eq(
        {
          course: [:root_account_id, :id],
          learning_outcome_group: :root_account_id,
          assignment: :root_account_id,
          account: :root_account_id,
          quiz: :root_account_id
        }
      )
    end

    it 'should account for associations that have a polymorphic_prefix' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
        CalendarEvent, {context: :root_account_id}
      )).to eq(
        {
          :context_appointment_group => :root_account_id,
          :context_course => :root_account_id,
          :context_course_section => :root_account_id,
          :context_group => :root_account_id,
          :context_user => :root_account_id,
        }
      )
    end

    it 'should replace account association with both root_account_id and id' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
        ContextExternalTool, {course: :root_account_id, account: :root_account_id}
      )).to eq(
        {
          :account=>[:root_account_id, :id],
          :course=>:root_account_id
        }
      )
    end
  end

  describe '#check_if_table_has_root_account' do
    it 'should return correctly for tables with root_account_id' do
      DeveloperKey.create!(account: @course.account)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(DeveloperKey)).to be true

      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(ContextModule)).to be false
    end

    it 'should return correctly for tables where we only care about certain associations' do
      # this is meant to be used for models like Attachment where we may not populate root
      # account if the context is User, but we still want to work under the assumption that
      # the table is completely backfilled

      # User-context event doesn't have root account id so we use the user's account
      event = CalendarEvent.create!(context: user_model)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(
        CalendarEvent
      )).to be true

      # manually adding makes the check method think it does, though
      event.update_columns(root_account_id: @course.root_account_id)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(
        CalendarEvent
      )).to be true

      # adding another User-context event should make it return false,
      # except we are explicitly ignoring User-context events
      CalendarEvent.create(context: user_model)
      CalendarEvent.create(context: @course, root_account_id: @course.root_account_id)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(
        CalendarEvent, [:context_course, :context_group, :context_appointment_group, :context_course_section]
      )).to be true
    end
  end

  describe '#populate_root_account_ids' do
    it 'should only update models with an id in the given range' do
      cm2 = @course.context_modules.create!
      cm2.update_columns(root_account_id: nil)

      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids(ContextModule, {course: :root_account_id}, cm2.id, cm2.id)
      expect(@cm.reload.root_account_id).to be nil
      expect(cm2.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should restart the table fixup job if there are no other root account populate delayed jobs of this type still running' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:run).once
      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids(ContextModule, {course: :root_account_id}, @cm.id, @cm.id)
    end

    it 'should not restart the table fixup job if there are items in this table that do not have root_account_id' do
      cm2 = @course.context_modules.create!
      cm2.update_columns(root_account_id: nil)

      expect(DataFixup::PopulateRootAccountIdOnModels).not_to receive(:run)
      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids(ContextModule, {course: :root_account_id}, cm2.id, cm2.id)
    end
  end

  describe '#create_column_names' do
    it 'should create a single column name' do
      expect(DataFixup::PopulateRootAccountIdOnModels.create_column_names(:course, 'root_account_id')).to eq(
        'courses.root_account_id'
      )
    end

    it 'should coalesce multiple column names on a table' do
      expect(DataFixup::PopulateRootAccountIdOnModels.create_column_names(:account, ['root_account_id', :id])).to eq(
        "COALESCE(accounts.root_account_id, accounts.id)"
      )
    end
  end
end
