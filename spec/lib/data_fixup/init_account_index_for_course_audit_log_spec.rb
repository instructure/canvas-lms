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
#

require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

describe DataFixup::InitAccountIndexForCourseAuditLog do

  include_examples 'cassandra audit logs'

  def insert_cql
    %{
      INSERT INTO courses (id, course_id, created_at, event_source, event_type )
      VALUES (?, ?, ?, ?, ?) USING TTL ?
    }
  end

  INDEX_TABLES = %w(
    courses_by_account
  ).freeze

  before(:each) do
    @database = Canvas::Cassandra::DatabaseBuilder.from_config(:auditors)
    skip("requires cassandra auditors") unless @database

    course_factory

    @values = [
      [
        '08d87bfc-a679-4f5d-9315-470a5fc7d7d0',
        @course.global_id,
        2.days.ago,
        'manual',
        'published',
        1.month
      ],
      [
        'fc85afda-538e-4fcb-a7fb-45697c551b71',
        @course.global_id,
        1.day.ago,
        'api',
        'claimed',
        1.month
      ]
    ]

    @values.each do |v|
      @database.execute(insert_cql, *v)
    end

  end

  it 'populates the account_id column' do
    DataFixup::InitAccountIndexForCourseAuditLog.run

    cql = 'SELECT id, account_id FROM courses'
    account_ids = []
    @database.execute(cql).fetch do |row|
      account_ids << row['account_id']
    end
    expect(account_ids).to include(@course.global_account_id)
  end

  it 'creates all the new indexes records' do
    DataFixup::InitAccountIndexForCourseAuditLog.run

    cql = 'SELECT id FROM courses_by_account'
    ids = []
    @database.execute(cql).fetch do |row|
      ids << row['id']
    end

    expect(ids).to include(@values.first.first)
  end

end
