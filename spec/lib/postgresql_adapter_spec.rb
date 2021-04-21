# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe ActiveRecord::ConnectionAdapters::PostgreSQLAdapter do
  describe '#add_schema_to_search_path' do
    it 'restores if committing' do
      User.connection.add_schema_to_search_path("bogus") do
        expect(User.connection.schema_search_path).to match(/bogus/)
        expect(User.connection.select_value("SHOW search_path")).to match(/bogus/)
      end
      expect(User.connection.schema_search_path).not_to match(/bogus/)
      expect(User.connection.select_value("SHOW search_path")).not_to match(/bogus/)
    end

    it 'restores if explicitly rolling back' do
      User.connection.add_schema_to_search_path("bogus") do
        raise ActiveRecord::Rollback
      end
      expect(User.connection.schema_search_path).not_to match(/bogus/)
      expect(User.connection.select_value("SHOW search_path")).not_to match(/bogus/)
    end

    it 'restores on db error' do
      begin
        User.connection.add_schema_to_search_path("bogus") do
          User.connection.execute("garbage")
          # not reached
          expect(false).to eq true
        end
      rescue ActiveRecord::StatementInvalid
        nil
      end

      expect(User.connection.schema_search_path).not_to match(/bogus/)
      expect(User.connection.select_value("SHOW search_path")).not_to match(/bogus/)
    end
  end
end
