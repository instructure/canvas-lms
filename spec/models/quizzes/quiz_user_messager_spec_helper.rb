# Copyright (C) 2014 Instructure, Inc.
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
module Quizzes
  module QuizUserMessagerSpecHelper

    def conversation(recipients)
      {
        subject: "Do you want ants?",
        body: "Because that's how you get ants",
        recipients: recipients
      }
    end

    def send_message(recipients='all')
      options = {
        quiz: @quiz,
        sender: @teacher,
        conversation: conversation(recipients),
        root_account_id: Account.default.id
      }
      Quizzes::QuizUserMessager.new(options).send
      run_jobs
    end

    def recipient_messages(target_group)
      recipients = @finder.send("#{target_group}_students")
      recipients.map(&:all_conversations).map(&:size).reduce(:+) || 0
    end

  end
end
