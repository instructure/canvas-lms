
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
  class QuizUserMessager
    extend Forwardable
    attr_reader :sender, :async, :recipient_list, :conversation, :quiz
    attr_reader :root_account_id, :context_id

    def_delegators :@user_finder,
      :submitted_students,
      :all_students,
      :unsubmitted_students

    def initialize(options)
      @quiz = options.fetch(:quiz)
      @sender = options.fetch(:sender)
      @async = options.fetch(:async, true) ? :async : :sync
      @conversation = options.fetch(:conversation)
      @root_account_id = options.fetch(:root_account_id)
      @context_id = quiz.context_id
      @user_finder = Quizzes::QuizUserFinder.new(quiz, sender)
    end

    def send
      ConversationBatch.generate(
        message,
        recipients,
        async,
        subject: subject,
        context_id: context_id,
        group: false
      )
    end

    private

    def message
      @message ||= (
        Conversation.build_message(
          sender,
          body,
          root_account_id: root_account_id
        )
      )
    end

    def body
      conversation[:body]
    end

    def subject
      conversation[:subject]
    end

    def recipients
      list = conversation.fetch(:recipients, 'all')
      recipients = case list.to_s
                   when 'unsubmitted' then unsubmitted_students
                   when 'submitted' then submitted_students
                   else all_students
                   end
      sender.load_messageable_users(recipients.pluck(:id))
    end
  end
end
