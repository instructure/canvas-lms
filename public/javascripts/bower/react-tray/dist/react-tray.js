(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("react"), require("ReactDOM"));
	else if(typeof define === 'function' && define.amd)
		define(["react", "ReactDOM"], factory);
	else if(typeof exports === 'object')
		exports["ReactTray"] = factory(require("react"), require("ReactDOM"));
	else
		root["ReactTray"] = factory(root["React"], root["ReactDOM"]);
})(this, function(__WEBPACK_EXTERNAL_MODULE_2__, __WEBPACK_EXTERNAL_MODULE_3__) {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	module.exports = __webpack_require__(1);

/***/ },
/* 1 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, '__esModule', {
	  value: true
	});

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

	var _react = __webpack_require__(2);

	var _react2 = _interopRequireDefault(_react);

	var _reactDom = __webpack_require__(3);

	var _reactDom2 = _interopRequireDefault(_reactDom);

	var _TrayPortal = __webpack_require__(4);

	var _TrayPortal2 = _interopRequireDefault(_TrayPortal);

	var renderSubtreeIntoContainer = _reactDom2['default'].unstable_renderSubtreeIntoContainer;

	exports['default'] = _react2['default'].createClass({
	  displayName: 'Tray',

	  propTypes: {
	    isOpen: _react2['default'].PropTypes.bool,
	    onBlur: _react2['default'].PropTypes.func,
	    closeTimeoutMS: _react2['default'].PropTypes.number,
	    closeOnBlur: _react2['default'].PropTypes.bool
	  },

	  getDefaultProps: function getDefaultProps() {
	    return {
	      isOpen: false,
	      closeTimeoutMS: 0,
	      closeOnBlur: true
	    };
	  },

	  componentDidMount: function componentDidMount() {
	    this.node = document.createElement('div');
	    this.node.className = 'ReactTrayPortal';
	    document.body.appendChild(this.node);
	    this.renderPortal(this.props);
	  },

	  componentWillReceiveProps: function componentWillReceiveProps(props) {
	    this.renderPortal(props);
	  },

	  componentWillUnmount: function componentWillUnmount() {
	    _reactDom2['default'].unmountComponentAtNode(this.node);
	    document.body.removeChild(this.node);
	  },

	  renderPortal: function renderPortal(props) {
	    delete props.ref;

	    renderSubtreeIntoContainer(this, _react2['default'].createElement(_TrayPortal2['default'], props), this.node);
	  },

	  render: function render() {
	    return null;
	  }
	});
	module.exports = exports['default'];

/***/ },
/* 2 */
/***/ function(module, exports) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_2__;

/***/ },
/* 3 */
/***/ function(module, exports) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_3__;

/***/ },
/* 4 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, '__esModule', {
	  value: true
	});

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

	var _react = __webpack_require__(2);

	var _react2 = _interopRequireDefault(_react);

	var _classnames = __webpack_require__(5);

	var _classnames2 = _interopRequireDefault(_classnames);

	var _helpersFocusManager = __webpack_require__(6);

	var _helpersFocusManager2 = _interopRequireDefault(_helpersFocusManager);

	var _helpersIsLeavingNode = __webpack_require__(7);

	var _helpersIsLeavingNode2 = _interopRequireDefault(_helpersIsLeavingNode);

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
	  /* eslint no-cond-assign:0 */
	  while (node = node.parentNode) {
	    if (node === parent) {
	      return true;
	    }
	  }
	  return false;
	}

	exports['default'] = _react2['default'].createClass({
	  displayName: 'TrayPortal',

	  propTypes: {
	    className: _react.PropTypes.string,
	    overlayClassName: _react.PropTypes.string,
	    isOpen: _react.PropTypes.bool,
	    onBlur: _react.PropTypes.func,
	    closeOnBlur: _react.PropTypes.bool,
	    closeTimeoutMS: _react.PropTypes.number,
	    children: _react.PropTypes.any
	  },

	  getInitialState: function getInitialState() {
	    return {
	      afterOpen: false,
	      beforeClose: false
	    };
	  },

	  componentDidMount: function componentDidMount() {
	    if (this.props.isOpen) {
	      this.setFocusAfterRender(true);
	      this.open();
	    }
	  },

	  componentWillReceiveProps: function componentWillReceiveProps(props) {
	    if (props.isOpen) {
	      this.setFocusAfterRender(true);
	      this.open();
	    } else if (this.props.isOpen && !props.isOpen) {
	      this.close();
	    }
	  },

	  componentDidUpdate: function componentDidUpdate() {
	    if (this.focusAfterRender) {
	      this.focusContent();
	      this.setFocusAfterRender(false);
	    }
	  },

	  setFocusAfterRender: function setFocusAfterRender(focus) {
	    this.focusAfterRender = focus;
	  },

	  focusContent: function focusContent() {
	    this.refs.content.focus();
	  },

	  handleOverlayClick: function handleOverlayClick(e) {
	    if (!isChild(this.refs.content, e.target)) {
	      this.props.onBlur();
	    }
	  },

	  handleContentKeyDown: function handleContentKeyDown(e) {
	    // Treat ESC as blur/close
	    if (e.keyCode === 27) {
	      this.props.onBlur();
	    }

	    // Treat tabbing away from content as blur/close if closeOnBlur
	    if (e.keyCode === 9 && this.props.closeOnBlur && (0, _helpersIsLeavingNode2['default'])(this.refs.content, e)) {
	      e.preventDefault();
	      this.props.onBlur();
	    }
	  },

	  open: function open() {
	    var _this = this;

	    _helpersFocusManager2['default'].markForFocusLater();
	    this.setState({ isOpen: true }, function () {
	      _this.setState({ afterOpen: true });
	    });
	  },

	  close: function close() {
	    if (this.props.closeTimeoutMS > 0) {
	      this.closeWithTimeout();
	    } else {
	      this.closeWithoutTimeout();
	    }
	  },

	  closeWithTimeout: function closeWithTimeout() {
	    var _this2 = this;

	    this.setState({ beforeClose: true }, function () {
	      setTimeout(_this2.closeWithoutTimeout, _this2.props.closeTimeoutMS);
	    });
	  },

	  closeWithoutTimeout: function closeWithoutTimeout() {
	    this.setState({
	      afterOpen: false,
	      beforeClose: false
	    }, this.afterClose);
	  },

	  afterClose: function afterClose() {
	    _helpersFocusManager2['default'].returnFocus();
	  },

	  shouldBeClosed: function shouldBeClosed() {
	    return !this.props.isOpen && !this.state.beforeClose;
	  },

	  buildClassName: function buildClassName(which) {
	    var className = CLASS_NAMES[which].base;
	    if (this.state.afterOpen) {
	      className += ' ' + CLASS_NAMES[which].afterOpen;
	    }
	    if (this.state.beforeClose) {
	      className += ' ' + CLASS_NAMES[which].beforeClose;
	    }
	    return className;
	  },

	  render: function render() {
	    return this.shouldBeClosed() ? _react2['default'].createElement('div', null) : _react2['default'].createElement(
	      'div',
	      {
	        ref: 'overlay',
	        style: styles.overlay,
	        className: (0, _classnames2['default'])(this.buildClassName('overlay'), this.props.overlayClassName),
	        onClick: this.handleOverlayClick
	      },
	      _react2['default'].createElement(
	        'div',
	        {
	          ref: 'content',
	          style: styles.content,
	          className: (0, _classnames2['default'])(this.buildClassName('content'), this.props.className),
	          onKeyDown: this.handleContentKeyDown,
	          tabIndex: '-1'
	        },
	        this.props.children
	      )
	    );
	  }
	});
	module.exports = exports['default'];

/***/ },
/* 5 */
/***/ function(module, exports, __webpack_require__) {

	var __WEBPACK_AMD_DEFINE_RESULT__;/*!
	  Copyright (c) 2015 Jed Watson.
	  Licensed under the MIT License (MIT), see
	  http://jedwatson.github.io/classnames
	*/
	/* global define */

	(function () {
		'use strict';

		var hasOwn = {}.hasOwnProperty;

		function classNames () {
			var classes = '';

			for (var i = 0; i < arguments.length; i++) {
				var arg = arguments[i];
				if (!arg) continue;

				var argType = typeof arg;

				if (argType === 'string' || argType === 'number') {
					classes += ' ' + arg;
				} else if (Array.isArray(arg)) {
					classes += ' ' + classNames.apply(null, arg);
				} else if (argType === 'object') {
					for (var key in arg) {
						if (hasOwn.call(arg, key) && arg[key]) {
							classes += ' ' + key;
						}
					}
				}
			}

			return classes.substr(1);
		}

		if (typeof module !== 'undefined' && module.exports) {
			module.exports = classNames;
		} else if (true) {
			// register as 'classnames', consistent with npm package name
			!(__WEBPACK_AMD_DEFINE_RESULT__ = function () {
				return classNames;
			}.call(exports, __webpack_require__, exports, module), __WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
		} else {
			window.classNames = classNames;
		}
	}());


/***/ },
/* 6 */
/***/ function(module, exports) {

	'use strict';

	var focusLaterElement = null;

	exports.markForFocusLater = function markForFocusLater() {
	  focusLaterElement = document.activeElement;
	};

	exports.returnFocus = function returnFocus() {
	  try {
	    focusLaterElement.focus();
	  } catch (e) {
	    /* eslint no-console:0 */
	    console.warn('You tried to return focus to ' + focusLaterElement + ' but it is not in the DOM anymore');
	  }
	  focusLaterElement = null;
	};

/***/ },
/* 7 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, '__esModule', {
	  value: true
	});

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

	var _helpersTabbable = __webpack_require__(8);

	var _helpersTabbable2 = _interopRequireDefault(_helpersTabbable);

	exports['default'] = function (node, event) {
	  var tabbable = (0, _helpersTabbable2['default'])(node);
	  var finalTabbable = tabbable[event.shiftKey ? 0 : tabbable.length - 1];
	  var isLeavingNode = finalTabbable === document.activeElement;
	  return isLeavingNode;
	};

	module.exports = exports['default'];

/***/ },
/* 8 */
/***/ function(module, exports) {

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

	'use strict';

	Object.defineProperty(exports, '__esModule', {
	  value: true
	});
	function hidden(el) {
	  return el.offsetWidth <= 0 && el.offsetHeight <= 0 || el.style.display === 'none';
	}

	function visible(element) {
	  var el = element;
	  while (el) {
	    if (el === document.body) break;
	    if (hidden(el)) return false;
	    el = el.parentNode;
	  }
	  return true;
	}

	function focusable(element, isTabIndexNotNaN) {
	  var nodeName = element.nodeName.toLowerCase();
	  /* eslint no-nested-ternary:0 */
	  return (/input|select|textarea|button|object/.test(nodeName) ? !element.disabled : nodeName === 'a' ? element.href || isTabIndexNotNaN : isTabIndexNotNaN) && visible(element);
	}

	function tabbable(element) {
	  var tabIndex = element.getAttribute('tabindex');
	  if (tabIndex === null) tabIndex = undefined;
	  var isTabIndexNaN = isNaN(tabIndex);
	  return (isTabIndexNaN || tabIndex >= 0) && focusable(element, !isTabIndexNaN);
	}

	function findTabbableDescendants(element) {
	  return [].slice.call(element.querySelectorAll('*'), 0).filter(function (el) {
	    return tabbable(el);
	  });
	}

	exports['default'] = findTabbableDescendants;
	module.exports = exports['default'];

/***/ }
/******/ ])
});
;
//# sourceMappingURL=react-tray.js.map