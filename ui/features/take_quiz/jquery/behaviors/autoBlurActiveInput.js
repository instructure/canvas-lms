//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'

let blurActiveInput = false
let initialized = false

export default function (enable = true) {
  blurActiveInput = enable
  if (initialized) return
  initialized = true

  // ensure that blur/change/focus events fire for the active form element
  // whenever the window gains or loses focus
  //
  // this is particularly useful for taking quizzes, where we do some stuff
  // whenever you answer a question (validate it, mark it as answered in the
  // UI, save the submission, etc.). this way it works correctly when you
  // click into tiny (iframe, so a separate window), or click on the chrome
  // outside of the viewport (e.g. change tabs). see #7475
  $(window).bind({
    blur(e) {
      if (blurActiveInput && document.activeElement && window === e.target) {
        $(document.activeElement).filter(':input').change().triggerHandler('blur')
      }
    },
    focus(e) {
      if (blurActiveInput && document.activeElement && window === e.target) {
        $(document.activeElement).filter(':input').triggerHandler('focus')
      }
    },
  })
}
