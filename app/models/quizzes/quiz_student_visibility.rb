# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class Quizzes::QuizStudentVisibility < ActiveRecord::Base
  # necessary for general_model_spec

  include VisibilityPluckingHelper

  # create_or_update checks for !readonly? before persisting
  def readonly?
    true
  end

  def self.where_with_guard(*args)
    if Account.site_admin.feature_enabled?(:selective_release_backend)
      raise StandardError, "QuizStudentVisibility view should not be used when selective_release_backend site admin flag is on.  Use QuizVisibilityService instead"
    end

    where_without_guard(*args)
  end

  class << self
    alias_method :where_without_guard, :where
    alias_method :where, :where_with_guard
  end

  def self.visible_quiz_ids_in_course_by_user(opts)
    visible_object_ids_in_course_by_user(:quiz_id, opts)
  end

  # readonly? is not checked in destroy though
  before_destroy { raise ActiveRecord::ReadOnlyRecord }
end
