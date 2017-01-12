!function(e){if("object"==typeof exports&&"undefined"!=typeof module)module.exports=e();else if("function"==typeof define&&define.amd)define([],e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.ReactTray=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function (global){
var React = (typeof window !== "undefined" ? window.React : typeof global !== "undefined" ? global.React : null);
var TrayPortal = React.createFactory(require('./TrayPortal'));

var Tray = React.createClass({
  displayName: 'Tray',

  propTypes: {
    isOpen: React.PropTypes.bool,
    onBlur: React.PropTypes.func,
    closeTimeoutMS: React.PropTypes.number
  },

  getDefaultProps: function () {
    return {
      isOpen: false,
      closeTimeoutMS: 0
    };
  },

  componentDidMount: function () {
    this.node = document.createElement('div');
    this.node.className = 'ReactTrayPortal';
    document.body.appendChild(this.node);
    this.renderPortal(this.props);
  },

  componentWillReceiveProps: function (props) {
    this.renderPortal(props);
  },

  componentWillUnmount: function () {
    React.unmountComponentAtNode(this.node);
    document.body.removeChild(this.node);
  },

  renderPortal: function (props) {
    delete props.ref;

    if (this.portal) {
      this.portal.setProps(props);
    } else {
      this.portal = React.render(TrayPortal(props), this.node);
    }
  },

  render: function () {
    return null;
  }
});

module.exports = Tray;



}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"./TrayPortal":2}],2:[function(require,module,exports){
(function (global){
var React = (typeof window !== "undefined" ? window.React : typeof global !== "undefined" ? global.React : null);
var div = React.DOM.div;
var cx = require('../helpers/classSet');
var focusManager = require('../helpers/focusManager');
var isLeavingNode = require('../helpers/isLeavingNode');

var styles = {
  overlay: {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0
  },
  content: {
    position: 'absolute',
    background: '#fff'
  }
};

var CLASS_NAMES = {
  overlay: {
    base: 'ReactTray__Overlay',
    afterOpen: 'ReactTray__Overlay--after-open',
    beforeClose: 'ReactTray__Overlay--before-close'
  },
  content: {
    base: 'ReactTray__Content',
    afterOpen: 'ReactTray__Content--after-open',
    beforeClose: 'ReactTray__Content--before-close'
  }
};

function isChild(parent, child) {
  if (parent === child) {
    return true;
  }

  var node = child;
  while (node = node.parentNode) {
    if (node === parent) {
      return true;
    }
  }
  return false;
}

var TrayPortal = React.createClass({
  displayName: 'TrayPortal',

  getInitialState: function () {
    return {
      afterOpen: false,
      beforeClose: false
    };
  },

  componentDidMount: function () {
    if (this.props.isOpen) {
      this.setFocusAfterRender(true);
      this.open();
    }
  },

  componentWillReceiveProps: function (props) {
    if (props.isOpen) {
      this.setFocusAfterRender(true);
      this.open();
    } else if (this.props.isOpen && !props.isOpen) {
      this.close();
    }
  },

  componentDidUpdate: function () {
    if (this.focusAfterRender) {
      this.focusContent();
      this.setFocusAfterRender(false);
    }
  },

  setFocusAfterRender: function (focus) {
    this.focusAfterRender = focus;
  },

  focusContent: function () {
    this.refs.content.getDOMNode().focus();
  },

  handleOverlayClick: function (e) {
    if (!isChild(this.refs.content.getDOMNode(), e.target)) {
      this.props.onBlur();
    }
  },

  handleContentKeyDown: function (e) {
    // Treat ESC as blur/close
    if (e.keyCode === 27) {
      this.props.onBlur();
    }

    // Treat tabbing away from content as blur/close
    if (e.keyCode === 9 && isLeavingNode(this.refs.content.getDOMNode(), e)) {
      e.preventDefault();
      this.props.onBlur();
    }
  },
   
  open: function () {
    focusManager.markForFocusLater();
    this.setState({isOpen: true}, function () {
      this.setState({afterOpen: true});
    }.bind(this));
  },

  close: function () {
    if (this.props.closeTimeoutMS > 0) {
      this.closeWithTimeout();
    } else {
      this.closeWithoutTimeout();
    }
  },

  closeWithTimeout: function () {
    this.setState({beforeClose: true}, function () {
      setTimeout(this.closeWithoutTimeout, this.props.closeTimeoutMS);
    }.bind(this));
  },

  closeWithoutTimeout: function () {
    this.setState({
      afterOpen: false,
      beforeClose: false
    }, this.afterClose);
  },

  afterClose: function () {
    focusManager.returnFocus();
  },

  shouldBeClosed: function () {
    return !this.props.isOpen && !this.state.beforeClose;
  },

  buildClassName: function (which) {
    var className = CLASS_NAMES[which].base;
    if (this.state.afterOpen) {
      className += ' ' + CLASS_NAMES[which].afterOpen;
    }
    if (this.state.beforeClose) {
      className += ' ' + CLASS_NAMES[which].beforeClose;
    }
    return className;
  },

  render: function () {
    return this.shouldBeClosed() ? div() : (
      div({
        ref: 'overlay',
        style: styles.overlay,
        className: cx(this.buildClassName('overlay'), this.props.overlayClassName),
        onClick: this.handleOverlayClick
      },
        div({
          ref: 'content',
          style: styles.content,
          className: cx(this.buildClassName('content'), this.props.className),
          onKeyDown: this.handleContentKeyDown,
          tabIndex: '-1'
        },
          this.props.children
        )
      )
    );
  }
});

module.exports = TrayPortal;



}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"../helpers/classSet":3,"../helpers/focusManager":4,"../helpers/isLeavingNode":5}],3:[function(require,module,exports){
module.exports = function classSet(classNames) {
  if (typeof classNames == 'object') {
    return Object.keys(classNames).filter(function(className) {
      return classNames[className];
    }).join(' ');
  } else {
    return Array.prototype.join.call(arguments, ' ');
  }
};



},{}],4:[function(require,module,exports){
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



},{}],5:[function(require,module,exports){
var findTabbable = require('../helpers/tabbable');

module.exports = function (node, event) {
  var tabbable = findTabbable(node);
  var finalTabbable = tabbable[event.shiftKey ? 0 : tabbable.length - 1];
  var isLeavingNode = (
    finalTabbable === document.activeElement
  );
  return isLeavingNode;
};



},{"../helpers/tabbable":6}],6:[function(require,module,exports){
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

function focusable(element, isTabIndexNotNaN) {
  var nodeName = element.nodeName.toLowerCase();
  return (/input|select|textarea|button|object/.test(nodeName) ?
    !element.disabled :
    "a" === nodeName ?
      element.href || isTabIndexNotNaN :
      isTabIndexNotNaN) && visible(element);
}

function hidden(el) {
  return (el.offsetWidth <= 0 && el.offsetHeight <= 0) ||
    el.style.display === 'none';
}

function visible(element) {
  while (element) {
    if (element === document.body) break;
    if (hidden(element)) return false;
    element = element.parentNode;
  }
  return true;
}

function tabbable(element) {
  var tabIndex = element.getAttribute('tabindex');
  if (tabIndex === null) tabIndex = undefined;
  var isTabIndexNaN = isNaN(tabIndex);
  return (isTabIndexNaN || tabIndex >= 0) && focusable(element, !isTabIndexNaN);
}

function findTabbableDescendants(element) {
  return [].slice.call(element.querySelectorAll('*'), 0).filter(function(el) {
    return tabbable(el);
  });
}

module.exports = findTabbableDescendants;



},{}],7:[function(require,module,exports){
module.exports = require('./components/Tray');



},{"./components/Tray":1}]},{},[7])(7)
});