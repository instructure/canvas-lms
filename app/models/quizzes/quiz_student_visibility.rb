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

  # we are temporarily using a setting here because the feature flag
  # is not able to be directly checked when canvas boots
  def self.reset_table_name
    return super unless Setting.get("differentiated_modules_setting", "false") == "true"

    self.table_name = "quiz_student_visibilities_v2"
  end

  # create_or_update checks for !readonly? before persisting
  def readonly?
    true
  end

  def self.visible_quiz_ids_in_course_by_user(opts)
    visible_object_ids_in_course_by_user(:quiz_id, opts)
  end

  # readonly? is not checked in destroy though
  before_destroy { raise ActiveRecord::ReadOnlyRecord }
end
