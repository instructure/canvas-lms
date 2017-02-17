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
define([], function () {
  if (!window.Worker) {
    // if this browser doesn't support web workers, this module does nothing
    return
  }

  function worker () {
    var stopwatch

    self.addEventListener('message', function (e) {
      var message = e.data || {}
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
    }, false)
  }
  var code = worker.toString()
  code = code.substring(code.indexOf('{') + 1, code.lastIndexOf('}'))

  var blob = new Blob([code], {type: 'application/javascript'})
  var quizTakingPolice = new Worker(URL.createObjectURL(blob))
  return quizTakingPolice
})
