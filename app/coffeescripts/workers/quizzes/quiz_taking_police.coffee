# The quiz taking police has arrived.
#
# Spawn this worker and ask it (politely) to provide you with a reliable
# "stopwatch" which you can use to do interval-based tasks such as
# auto-submitting the quiz, or saving answers, in a consistent manner regardless
# of whether the window/tab currently has focus.
#
# Example usage of the "startStopwatch" event:
#
#     var quizTakingPolice = new Worker('/javascripts/compiled/views/quizzes/QuizTakingPolice.js');
#     
#     // Notify me every 1.5 seconds:
#     quizTakingPolice.postMessage({
#       code: 'startStopwatch',
#       frequency: 1500
#     });
#     
#     // Play a very loud siren every 1.5 seconds, even if the user has navigated
#     // away from our website, for maximum annoyance
#     quizTakingPolice.addEventListener('message', function(evt) {
#       if (evt.data === 'stopwatchTick') {
#         policeSiren.play();
#       }
#     });
stopwatch = null

self.addEventListener 'message', (e) ->
  message = e.data || {}

  switch message.code
    when 'startStopwatch'
      stopwatch = setInterval(->
        self.postMessage('stopwatchTick')
      , message.frequency || 1000)
    when 'stop'
      clearInterval(stopwatch)
, false