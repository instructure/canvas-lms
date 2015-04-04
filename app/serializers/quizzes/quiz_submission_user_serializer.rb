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
  class QuizSubmissionUserSerializer < Canvas::APISerializer
    include Api::V1::User

    root :user
    attr_reader :quiz, :quiz_submissions

    # For Api::V1::User#user_json
    def_delegators :@controller,
      :service_enabled?

    attributes :id

    has_one :quiz_submission, embed_in_root: true, embed: :ids, key: :quiz_submission, serializer: Quizzes::QuizSubmissionSerializer

    LEGACY_INSTANCE_VARIABLES = %w[
      current_user
      domain_root_account
    ].freeze

    def quiz_submission
      quiz_submissions[object.id]
    end

    def initialize(object, options)
      super(object, options)

      @quiz = options.fetch(:quiz)
      # QuizSubmissions should be preloaded by the controller and provided to
      # the serializer so we don't have a bunch of N+1 queries
      @quiz_submissions = options[:quiz_submissions] || []

      # For Api::V1::User#user_json
      LEGACY_INSTANCE_VARIABLES.each do |ivar|
        instance_variable_set "@#{ivar}", @controller.instance_variable_get("@#{ivar}")
      end
    end

    def filter(keys)
      keys.select do |key|
        case key
        when :quiz_submission then sideloads.include?('quiz_submissions')
        else true
        end
      end
    end

    def serializable_object(options={})
      super.merge!(
        user_json(object, current_user, session, sideloads)
      )
    end
  end
end
