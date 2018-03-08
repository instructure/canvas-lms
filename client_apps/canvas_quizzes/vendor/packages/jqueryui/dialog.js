requirejs.config({
  map: {
    '*': {
      jqueryui: 'canvas/vendor/jqueryui'
    },

    'canvas/vendor/jqueryui/dialog': {
      'str/htmlEscape': 'canvas/str/htmlEscape'
    },

    'canvas/str/htmlEscape': {
      INST: 'canvas/INST'
    },

    'canvas/vendor/jqueryui/draggable': {
      'vendor/jquery.ui.touch-punch': 'canvas/vendor/jquery.ui.touch-punch'
    }
  }
})

define(['canvas/vendor/jqueryui/dialog'], function() {
  // dialog package has no return value
})
