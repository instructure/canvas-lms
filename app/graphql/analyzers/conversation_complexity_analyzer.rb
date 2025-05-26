# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Analyzers
  # For more information about the reasonings behind this analyzer, see this document:
  # https://docs.google.com/document/d/1fV3ZSiBsiLJrljsTB8keXjd7D4TdZ_pDnVETtZS7jXU
  class ConversationComplexityAnalyzer < BaseAnalyzer
    def initialize(subject)
      super

      @recipient_score = 0
      @user_uuid = subject.context[:current_user]&.uuid
    end

    def on_enter_field(node, _parent, visitor)
      return unless Account.site_admin.feature_enabled?(:create_conversation_graphql_rate_limit)
      return unless node.name == "createConversation"

      recipients = argument_value(node, visitor, :recipients)
      unless recipients.is_a?(Array)
        log_to_sentry("Conversation Complexity Analyzer: unable to process recipients", recipients:)
        return
      end

      @recipient_score += recipients.sum do |r|
        case r.to_s
        when /_teachers$/   then GraphQLTuning.create_conversation_rate_limit(:teachers_score)
        when /^group/       then GraphQLTuning.create_conversation_rate_limit(:group_score)
        when /_observers$/  then GraphQLTuning.create_conversation_rate_limit(:observers_score)
        when /^section/     then GraphQLTuning.create_conversation_rate_limit(:section_score)
        when /_students$/   then GraphQLTuning.create_conversation_rate_limit(:students_score)
        when /^course/      then GraphQLTuning.create_conversation_rate_limit(:course_score)
        else
          1
        end
      end
    end

    def result
      return unless Account.site_admin.feature_enabled?(:create_conversation_graphql_rate_limit)
      return if @recipient_score.nil? || @user_uuid.nil?
      return unless Canvas.redis_enabled?

      key = "conversation_message_limit:#{@user_uuid}"
      score = Canvas.redis.incrby(key, @recipient_score)

      if Canvas.redis.ttl(key) < 0
        Canvas.redis.expire(key, 10.minutes.to_i)
        Rails.logger.info("TTL was missing or expired, reset to 10 minutes")
      end

      Rails.logger.info("Recipient score: #{score} for key: #{key}")

      if score.to_i > GraphQLTuning.create_conversation_rate_limit(:threshold)
        log_to_sentry("GraphQL: CreateConversation rate limit exceeded", retry_after: Canvas.redis.ttl(key))
        GraphQL::AnalysisError.new("Rate limit exceeded.")
      end
    end
  end
end
