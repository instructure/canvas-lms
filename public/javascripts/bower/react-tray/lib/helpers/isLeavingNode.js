var findTabbable = require('../helpers/tabbable');

module.exports = function (node, event) {
  var tabbable = findTabbable(node);
  var finalTabbable = tabbable[event.shiftKey ? 0 : tabbable.length - 1];
  var isLeavingNode = (
    finalTabbable === document.activeElement
  );
  return isLeavingNode;
};
