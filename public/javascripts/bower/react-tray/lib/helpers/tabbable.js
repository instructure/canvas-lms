/*!
 * Adapted from jQuery UI core
 *
 * http://jqueryui.com
 *
 * Copyright 2014 jQuery Foundation and other contributors
 * Released under the MIT license.
 * http://jquery.org/license
 *
 * http://api.jqueryui.com/category/ui-core/
 */

function hidden(el) {
  return (el.offsetWidth <= 0 && el.offsetHeight <= 0) ||
    el.style.display === 'none';
}

function visible(element) {
  let el = element;
  while (el) {
    if (el === document.body) break;
    if (hidden(el)) return false;
    el = el.parentNode;
  }
  return true;
}

function focusable(element, isTabIndexNotNaN) {
  const nodeName = element.nodeName.toLowerCase();
  /* eslint no-nested-ternary:0 */
  return (/input|select|textarea|button|object/.test(nodeName) ?
    !element.disabled :
    nodeName === 'a' ?
      element.href || isTabIndexNotNaN :
      isTabIndexNotNaN) && visible(element);
}

function tabbable(element) {
  let tabIndex = element.getAttribute('tabindex');
  if (tabIndex === null) tabIndex = undefined;
  const isTabIndexNaN = isNaN(tabIndex);
  return (isTabIndexNaN || tabIndex >= 0) && focusable(element, !isTabIndexNaN);
}

function findTabbableDescendants(element) {
  return [].slice.call(element.querySelectorAll('*'), 0).filter((el) => {
    return tabbable(el);
  });
}

export default findTabbableDescendants;
