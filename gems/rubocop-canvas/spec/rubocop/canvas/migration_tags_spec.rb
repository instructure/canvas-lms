# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'parser/current'

describe RuboCop::Canvas::MigrationTags do
  subject { Class.new.tap { |c| c.include(described_class) }.new }

  it 'collects the list of tags for the migration' do
    node = Parser::CurrentRuby.parse('tag :predeploy, :cassandra')
    subject.on_send(node)
    expect(subject.tags).to eq([:predeploy, :cassandra])
  end
end
