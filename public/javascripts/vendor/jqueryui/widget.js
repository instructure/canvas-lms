import $ from 'jquery'
import 'jqueryui/widget-unpatched'

// This function is the same as $.widget.extend
// except for this additional check on the target:
//   && $.isPlainObject(target[key])
//
// The change is because it was merging strings and objects
// which caused problems. Here's an example of what it was doing:
//   $.widget.extend({}, {handle: 'e,s,se'}, {handle: {s: 'div.ui-resizable-s'}})
//   => {0: 'e',
//       1: ',',
//       2: 's',
//       3: ',',
//       4: 's',
//       5: 'e',
//       s: 'div.ui-resizable-s'}
$.widget.extend = function(target) {
  var input = Array.prototype.slice.call(arguments, 1),
    inputIndex = 0,
    inputLength = input.length,
    key,
    value
  for (; inputIndex < inputLength; inputIndex++) {
    for (key in input[inputIndex]) {
      value = input[inputIndex][key]
      if (input[inputIndex].hasOwnProperty(key) && value !== undefined) {
        target[key] =
          $.isPlainObject(value) && $.isPlainObject(target[key])
            ? $.widget.extend({}, target[key], value)
            : value
      }
    }
  }
  return target
}

export default $
