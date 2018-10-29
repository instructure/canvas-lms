/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import React from 'react'
import ReactDOM from 'react-dom'
import CourseWizard from '../course_wizard/CourseWizard'

/*
  * This essentially handles binding the button events and calling out to the
  * CourseWizard React component that is the actual wizard.
  */

const $wizard_box = $('#wizard_box')

$('.wizard_popup_link').click(event => {
  ReactDOM.render(<CourseWizard showWizard />, $wizard_box[0])
})

// We are currently not allowing the wizard to popup automatically,
// uncommenting the following code will re-enable that functionality.
//
// setTimeout( ->
//   if (!userSettings.get('hide_wizard_' + pathname))
//     $(".wizard_popup_link.auto_open:first").click()
// , 500)
