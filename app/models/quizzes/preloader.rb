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
module Quizzes
  # This is a pattern for dealing with eager loading things
  # that autoloading will not handle well.  Anything that needs to
  # enumerate a complete list of relevent constants, for example,
  # will not behave properly if those constants have not yet been
  # loaded.  This is SIMILAR to the problem often encountered with
  # lazy loading for STI models ( https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#single-table-inheritance ).
  module Preloader
    def self.preload_quiz_questions
      Dir[Rails.root.join("app/models/quizzes/quiz_question/*_question.rb")].each do |f|
        filename = f.split("/").last
        snake_case_const = filename.split(".").first
        ::Quizzes.const_get("QuizQuestion::#{snake_case_const.camelize}")
      end
    end

    # By including this module in the root quizzes module, we'll fire off explicit
    # loading for each of the constants we care about as soon as we start referencing the Quizzes module
    # anywhere, which should be early enough to prevent FS read order confusion.
    def self.included(_base)
      Preloader.preload_quiz_questions
    end
  end
end
