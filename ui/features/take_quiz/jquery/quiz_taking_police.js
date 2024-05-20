/* eslint-disable import/no-commonjs */
/* eslint-disable no-inner-declarations */
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

/*
The quiz taking police has arrived.

 Spawn this worker and ask it (politely) to provide you with a reliable
 "stopwatch" which you can use to do interval-based tasks such as
 auto-submitting the quiz, or saving answers, in a consistent manner regardless
 of whether the window/tab currently has focus.

 Example usage of the "startStopwatch" event:

     var quizTakingPolice = require('path/to/quiz_taking_police');

     if (!quizTakingPolice) {
        //browser doesn't support web workers
     } else {

       // Notify me every 1.5 seconds:
       quizTakingPolice.postMessage({
         code: 'startStopwatch',
         frequency: 1500
       });

       // Play a very loud siren every 1.5 seconds, even if the user has navigated
       // away from our website, for maximum annoyance
       quizTakingPolice.addEventListener('message', function(evt) {
         if (evt.data === 'stopwatchTick') {
           policeSiren.play();
         }
       });
     }
*/

/* eslint-disable no-restricted-globals */

if (!window.Worker) {
  // If this browser doesn't support web workers, this module does nothing
  module.exports = null
} else {
  function worker() {
    let stopwatch

    self.addEventListener(
      'message',
      function (e) {
        const message = e.data || {}
        switch (message.code) {
          case 'startStopwatch':
            stopwatch = setInterval(function () {
              self.postMessage('stopwatchTick')
            }, message.frequency || 1000)
            break
          case 'stop':
            clearInterval(stopwatch)
            break
        }
      },
      false
    )
  }

  let code = worker.toString()
  code = code.substring(code.indexOf('{') + 1, code.lastIndexOf('}'))

  const blob = new Blob([code], {type: 'application/javascript'})
  const quizTakingPolice = new Worker(URL.createObjectURL(blob))

  module.exports = quizTakingPolice
}
