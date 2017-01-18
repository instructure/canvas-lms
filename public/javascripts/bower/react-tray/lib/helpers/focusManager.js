var focusLaterElement = null;

exports.markForFocusLater = function markForFocusLater() {
  focusLaterElement = document.activeElement;
};

exports.returnFocus = function returnFocus() {
  try {
    focusLaterElement.focus();
  }
  catch (e) {
    console.warn('You tried to return focus to '+focusLaterElement+' but it is not in the DOM anymore');
  }
  focusLaterElement = null;
};
