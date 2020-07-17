#
# Copyright (C) 2020 - present Instructure, Inc.
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

class ConditionalReleaseObjects
  class << self
    include SeleniumDependencies

    # Page edit
    def conditional_content_exists?
      element_exists?("#conditional_content")
    end

    # Assignment Index Page

    def assignment_kebob(page_title)
      fxpath("//a[.//*[text() = 'Settings for Assignment #{page_title}']]")
    end

    def edit_assignment(page_title)
      fxpath("//a[@aria-label='Edit Assignment #{page_title}']")
    end

    def due_at_exists?
      element_exists?("//*[contains(@class,'ui-dialog')]//input[@name='due_at']", true)
    end

    def points_possible_exists?
      element_exists?("//*[contains(@class,'ui-dialog')]//input[@name='points_possible']", true)
    end

    # Quizzes Page
    def quiz_conditional_release_link
      fxpath("//a[@href = '#mastery-paths-editor']")
    end

    def cr_editor_exists?
      element_exists?("#canvas-conditional-release-editor")
    end

    def disabled_cr_editor_exists?
      element_exists?("//li[@aria-disabled = 'true']/a[@href = '#mastery-paths-editor']", true)
    end

    # Assignment Edit
    def scoring_ranges
      ff(".cr-scoring-range")
    end

    def top_scoring_boundary
      f("[title='Top Bound']")
    end

    def lower_bound
      f("[title='Lower Bound']")
    end

    def division_cutoff1
      f("[title='Division cutoff 1']")
    end

    def division_cutoff2
      f("[title='Division cutoff 2']")
    end

    # Common Selectors
    def conditional_release_link
      f("#conditional_release_link")
    end

    def conditional_release_editor_exists?
      element_exists?("#canvas-conditional-release-editor")
    end

    def save_button
      f(".assignment__action-buttons .btn-primary")
    end
  end
end
