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
import React, {Suspense} from 'react'
import ReactDOM from 'react-dom'

const CourseWizard = React.lazy(() => import('./react/CourseWizard'))

/*
 * This essentially handles binding the button events and calling out to the
 * CourseWizard React component that is the actual wizard.
 */
function renderWizard(showWizard) {
  ReactDOM.render(
    <Suspense fallback={<div />}>
      {showWizard && <CourseWizard onHideWizard={() => renderWizard(false)} />}
    </Suspense>,
    document.getElementById('wizard_box')
  )
}

$(document).on('click', '.wizard_popup_link', () => renderWizard(true))
