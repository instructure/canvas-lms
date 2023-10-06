# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class CourseCopyPage
  class << self
    include SeleniumDependencies

    # CSS
    def migration_type_dropdown_id
      "#chooseMigrationConverter"
    end

    # Selectors
    def header
      f("#breadcrumbs .home + li a")
    end

    def create_course_button
      f('button[type="submit"]')
    end

    def body
      f("body")
    end

    def course_name_input
      f("#course_name")
    end

    def course_code_input
      f("#course_course_code")
    end

    def date_adjust_checkbox
      f("#dateAdjustCheckbox")
    end

    def add_day_substitution_button
      f("#addDaySubstitution")
    end

    def add_day_containers
      ff("#daySubstitution ul > div")
    end

    def old_start_date_input
      f("#oldStartDate")
    end

    def old_end_date_input
      f("#oldEndDate")
    end

    def new_start_date_input
      f("#newStartDate")
    end

    def new_end_date_input
      f("#newEndDate")
    end

    def date_remove_option
      f("#dateRemoveOption")
    end

    def course_copy_link
      f(".copy_course_link")
    end

    def course_start_at_input
      f("#course_start_at")
    end

    def course_conclude_at_input
      f("#course_conclude_at")
    end

    def migration_type_options
      ff("#chooseMigrationConverter option")
    end

    def cancel_copy_button
      f("#migrationConverterContainer .cancelBtn")
    end

    def day_substitution_containers
      ff("#daySubstitution ul > div")
    end

    def day_substitution_delete_button
      f("#daySubstitution ul > div a")
    end
  end
end
