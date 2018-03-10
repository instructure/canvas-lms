/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import autocompleteItemTemplate from 'jst/courses/autocomplete_item'
import 'jqueryui/autocomplete'

$(document).ready(() => {
  const $courseSearchField = $('#course_name:visible')
  if ($courseSearchField.length) {
    const autocompleteSource = $courseSearchField.data('autocomplete-source')
    $courseSearchField.autocomplete({
      minLength: 4,
      delay: 150,
      source: autocompleteSource,
      select (e, ui) {
          // When selected, go to the course page.
        const path = autocompleteSource.replace(/\?.+$/, '')
        window.location = `${path}/${ui.item.id}`
      }
    })
      // Customize autocomplete to show the enrollment term for each matched course.
    $courseSearchField.data('ui-autocomplete')._renderItem = (ul, item) => $(autocompleteItemTemplate(item)).appendTo(ul)
  }
})
