#
# Copyright (C) 2019 - present Instructure, Inc.
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

class AddQuizAndExternalToolToAnonymousOrModerationEvents < ActiveRecord::Migration[5.1]
  tag :predeploy

  def up
    change_column_null :anonymous_or_moderation_events, :user_id, true

    self.connection.execute(<<-SQL)
        ALTER TABLE #{AnonymousOrModerationEvent.quoted_table_name} ADD COLUMN context_external_tool_id bigint CONSTRAINT fk_rails_f492821432 REFERENCES #{ContextExternalTool.quoted_table_name}(id);
        ALTER TABLE #{AnonymousOrModerationEvent.quoted_table_name} ADD COLUMN quiz_id bigint CONSTRAINT fk_rails_a862303024 REFERENCES #{Quizzes::Quiz.quoted_table_name}(id);
    SQL
  end

  def down
    change_column_null :anonymous_or_moderation_events, :user_id, false
    self.connection.execute(<<-SQL)
        ALTER TABLE #{AnonymousOrModerationEvent.quoted_table_name} DROP COLUMN context_external_tool_id;
        ALTER TABLE #{AnonymousOrModerationEvent.quoted_table_name} DROP COLUMN quiz_id;
    SQL
  end
end
