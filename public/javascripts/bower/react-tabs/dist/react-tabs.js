(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("React"));
	else if(typeof define === 'function' && define.amd)
		define(["React"], factory);
	else if(typeof exports === 'object')
		exports["ReactTabs"] = factory(require("React"));
	else
		root["ReactTabs"] = factory(root["React"]);
})(this, function(__WEBPACK_EXTERNAL_MODULE_2__) {
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
	
	module.exports = {
	  Tabs: __webpack_require__(1),
	  TabList: __webpack_require__(7),
	  Tab: __webpack_require__(6),
	  TabPanel: __webpack_require__(9)
	};

/***/ },
/* 1 */
/***/ function(module, exports, __webpack_require__) {

	/* eslint indent:0 */
	'use strict';
	
	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }
	
	var _reactAddons = __webpack_require__(2);
	
	var _reactAddons2 = _interopRequireDefault(_reactAddons);
	
	var _jsStylesheet = __webpack_require__(3);
	
	var _jsStylesheet2 = _interopRequireDefault(_jsStylesheet);
	
	var _helpersUuid = __webpack_require__(4);
	
	var _helpersUuid2 = _interopRequireDefault(_helpersUuid);
	
	var _helpersChildrenPropType = __webpack_require__(5);
	
	var _helpersChildrenPropType2 = _interopRequireDefault(_helpersChildrenPropType);
	
	// Determine if a node from event.target is a Tab element
	function isTabNode(node) {
	  return node.nodeName === 'LI' && node.getAttribute('role') === 'tab';
	}
	
	// Determine if a tab node is disabled
	function isTabDisabled(node) {
	  return node.getAttribute('aria-disabled') === 'true';
	}
	
	module.exports = _reactAddons2['default'].createClass({
	  displayName: 'Tabs',
	
	  propTypes: {
	    selectedIndex: _reactAddons.PropTypes.number,
	    onSelect: _reactAddons.PropTypes.func,
	    focus: _reactAddons.PropTypes.bool,
	    children: _helpersChildrenPropType2['default'],
	    forceRenderTabPanel: _reactAddons.PropTypes.bool
	  },
	
	  childContextTypes: {
	    forceRenderTabPanel: _reactAddons.PropTypes.bool
	  },
	
	  getDefaultProps: function getDefaultProps() {
	    return {
	      selectedIndex: -1,
	      focus: false,
	      forceRenderTabPanel: false
	    };
	  },
	
	  getInitialState: function getInitialState() {
	    return this.copyPropsToState(this.props);
	  },
	
	  getChildContext: function getChildContext() {
	    return {
	      forceRenderTabPanel: this.props.forceRenderTabPanel
	    };
	  },
	
	  componentWillMount: function componentWillMount() {
	    (0, _jsStylesheet2['default'])(__webpack_require__(8));
	  },
	
	  componentWillReceiveProps: function componentWillReceiveProps(newProps) {
	    this.setState(this.copyPropsToState(newProps));
	  },
	
	  handleClick: function handleClick(e) {
	    var node = e.target;
	    do {
	      if (isTabNode(node)) {
	        if (isTabDisabled(node)) {
	          return;
	        }
	
	        var index = [].slice.call(node.parentNode.children).indexOf(node);
	        this.setSelected(index);
	        return;
	      }
	    } while ((node = node.parentNode) !== null);
	  },
	
	  handleKeyDown: function handleKeyDown(e) {
	    if (isTabNode(e.target)) {
	      var index = this.state.selectedIndex;
	      var preventDefault = false;
	
	      // Select next tab to the left
	      if (e.keyCode === 37 || e.keyCode === 38) {
	        index = this.getPrevTab(index);
	        preventDefault = true;
	      }
	      // Select next tab to the right
	      /* eslint brace-style:0 */
	      else if (e.keyCode === 39 || e.keyCode === 40) {
	          index = this.getNextTab(index);
	          preventDefault = true;
	        }
	
	      // This prevents scrollbars from moving around
	      if (preventDefault) {
	        e.preventDefault();
	      }
	
	      this.setSelected(index, true);
	    }
	  },
	
	  setSelected: function setSelected(index, focus) {
	    // Don't do anything if nothing has changed
	    if (index === this.state.selectedIndex) return;
	    // Check index boundary
	    if (index < 0 || index >= this.getTabsCount()) return;
	
	    // Keep reference to last index for event handler
	    var last = this.state.selectedIndex;
	
	    // Update selected index
	    this.setState({ selectedIndex: index, focus: focus === true });
	
	    // Call change event handler
	    if (typeof this.props.onSelect === 'function') {
	      this.props.onSelect(index, last);
	    }
	  },
	
	  getNextTab: function getNextTab(index) {
	    var count = this.getTabsCount();
	
	    // Look for non-disabled tab from index to the last tab on the right
	    for (var i = index + 1; i < count; i++) {
	      var tab = this.getTab(i);
	      if (!isTabDisabled(tab.getDOMNode())) {
	        return i;
	      }
	    }
	
	    // If no tab found, continue searching from first on left to index
	    for (var i = 0; i < index; i++) {
	      var tab = this.getTab(i);
	      if (!isTabDisabled(tab.getDOMNode())) {
	        return i;
	      }
	    }
	
	    // No tabs are disabled, return index
	    return index;
	  },
	
	  getPrevTab: function getPrevTab(index) {
	    var i = index;
	
	    // Look for non-disabled tab from index to first tab on the left
	    while (i--) {
	      var tab = this.getTab(i);
	      if (!isTabDisabled(tab.getDOMNode())) {
	        return i;
	      }
	    }
	
	    // If no tab found, continue searching from last tab on right to index
	    i = this.getTabsCount();
	    while (i-- > index) {
	      var tab = this.getTab(i);
	      if (!isTabDisabled(tab.getDOMNode())) {
	        return i;
	      }
	    }
	
	    // No tabs are disabled, return index
	    return index;
	  },
	
	  getTabsCount: function getTabsCount() {
	    return this.props.children && this.props.children[0] ? _reactAddons2['default'].Children.count(this.props.children[0].props.children) : 0;
	  },
	
	  getPanelsCount: function getPanelsCount() {
	    return _reactAddons2['default'].Children.count(this.props.children.slice(1));
	  },
	
	  getTabList: function getTabList() {
	    return this.refs.tablist;
	  },
	
	  getTab: function getTab(index) {
	    return this.refs['tabs-' + index];
	  },
	
	  getPanel: function getPanel(index) {
	    return this.refs['panels-' + index];
	  },
	
	  getChildren: function getChildren() {
	    var index = 0;
	    var count = 0;
	    var children = this.props.children;
	    var state = this.state;
	    var tabIds = this.tabIds = this.tabIds || [];
	    var panelIds = this.panelIds = this.panelIds || [];
	    var diff = this.tabIds.length - this.getTabsCount();
	
	    // Add ids if new tabs have been added
	    // Don't bother removing ids, just keep them in case they are added again
	    // This is more efficient, and keeps the uuid counter under control
	    while (diff++ < 0) {
	      tabIds.push((0, _helpersUuid2['default'])());
	      panelIds.push((0, _helpersUuid2['default'])());
	    }
	
	    // Map children to dynamically setup refs
	    return _reactAddons2['default'].Children.map(children, function (child) {
	      var result = null;
	
	      // Clone TabList and Tab components to have refs
	      if (count++ === 0) {
	        // TODO try setting the uuid in the "constructor" for `Tab`/`TabPanel`
	        result = _reactAddons2['default'].addons.cloneWithProps(child, {
	          ref: 'tablist',
	          children: _reactAddons2['default'].Children.map(child.props.children, function (tab) {
	            var ref = 'tabs-' + index;
	            var id = tabIds[index];
	            var panelId = panelIds[index];
	            var selected = state.selectedIndex === index;
	            var focus = selected && state.focus;
	
	            index++;
	
	            return _reactAddons2['default'].addons.cloneWithProps(tab, {
	              ref: ref,
	              id: id,
	              panelId: panelId,
	              selected: selected,
	              focus: focus
	            });
	          })
	        });
	
	        // Reset index for panels
	        index = 0;
	      }
	      // Clone TabPanel components to have refs
	      else {
	          var ref = 'panels-' + index;
	          var id = panelIds[index];
	          var tabId = tabIds[index];
	          var selected = state.selectedIndex === index;
	
	          index++;
	
	          result = _reactAddons2['default'].addons.cloneWithProps(child, {
	            ref: ref,
	            id: id,
	            tabId: tabId,
	            selected: selected
	          });
	        }
	
	      return result;
	    });
	  },
	
	  render: function render() {
	    var _this = this;
	
	    // This fixes an issue with focus management.
	    //
	    // Ultimately, when focus is true, and an input has focus,
	    // and any change on that input causes a state change/re-render,
	    // focus gets sent back to the active tab, and input loses focus.
	    //
	    // Since the focus state only needs to be remembered
	    // for the current render, we can reset it once the
	    // render has happened.
	    //
	    // Don't use setState, because we don't want to re-render.
	    //
	    // See https://github.com/mzabriskie/react-tabs/pull/7
	    if (this.state.focus) {
	      setTimeout(function () {
	        _this.state.focus = false;
	      }, 0);
	    }
	
	    return _reactAddons2['default'].createElement(
	      'div',
	      {
	        className: 'react-tabs',
	        onClick: this.handleClick,
	        onKeyDown: this.handleKeyDown
	      },
	      this.getChildren()
	    );
	  },
	
	  // This is an anti-pattern, so sue me
	  copyPropsToState: function copyPropsToState(props) {
	    var selectedIndex = props.selectedIndex;
	
	    // If no selectedIndex prop was supplied, then try
	    // preserving the existing selectedIndex from state.
	    // If the state has not selectedIndex, default
	    // to the first tab in the TabList.
	    //
	    // TODO: Need automation testing around this
	    // Manual testing can be done using examples/focus
	    // See 'should preserve selectedIndex when typing' in specs/Tabs.spec.js
	    if (selectedIndex === -1) {
	      if (this.state && this.state.selectedIndex) {
	        selectedIndex = this.state.selectedIndex;
	      } else {
	        selectedIndex = 0;
	      }
	    }
	
	    return {
	      selectedIndex: selectedIndex,
	      focus: props.focus
	    };
	  }
	});

/***/ },
/* 2 */
/***/ function(module, exports) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_2__;

/***/ },
/* 3 */
/***/ function(module, exports, __webpack_require__) {

	!(function() {
	  function jss(blocks) {
	    var css = [];
	    for (var block in blocks)
	      css.push(createStyleBlock(block, blocks[block]));
	    injectCSS(css);
	  }
	
	  function createStyleBlock(selector, rules) {
	    return selector + ' {\n' + parseRules(rules) + '\n}';
	  }
	
	  function parseRules(rules) {
	    var css = [];
	    for (var rule in rules)
	      css.push('  '+rule+': '+rules[rule]+';');
	    return css.join('\n');
	  }
	
	  function injectCSS(css) {
	    var style = document.getElementById('jss-styles');
	    if (!style) {
	      style = document.createElement('style');
	      style.setAttribute('id', 'jss-styles');
	      var head = document.getElementsByTagName('head')[0];
	      head.insertBefore(style, head.firstChild);
	    }
	    var node = document.createTextNode(css.join('\n\n'));
	    style.appendChild(node);
	  }
	
	  if (true)
	    module.exports = jss;
	  else
	    window.jss = jss;
	
	})();
	


/***/ },
/* 4 */
/***/ function(module, exports) {

	// Get a universally unique identifier
	'use strict';
	
	var count = 0;
	module.exports = function uuid() {
	  return 'react-tabs-' + count++;
	};

/***/ },
/* 5 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';
	
	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }
	
	var _react = __webpack_require__(2);
	
	var _react2 = _interopRequireDefault(_react);
	
	var _componentsTab = __webpack_require__(6);
	
	var _componentsTab2 = _interopRequireDefault(_componentsTab);
	
	var _componentsTabList = __webpack_require__(7);
	
	var _componentsTabList2 = _interopRequireDefault(_componentsTabList);
	
	module.exports = function childrenPropTypes(props, propName) {
	  var error = undefined;
	  var tabsCount = 0;
	  var panelsCount = 0;
	  var children = props[propName];
	
	  _react2['default'].Children.forEach(children, function (child) {
	    if (child.type === _componentsTabList2['default']) {
	      _react2['default'].Children.forEach(child.props.children, function (c) {
	        if (c.type === _componentsTab2['default']) {
	          tabsCount++;
	        } else {
	          error = new Error('Expected `Tab` but found `' + (c.type.displayName || c.type) + '`');
	        }
	      });
	    } else if (child.type.displayName === 'TabPanel') {
	      panelsCount++;
	    } else {
	      error = new Error('Expected `TabList` or `TabPanel` but found `' + (child.type.displayName || child.type) + '`');
	    }
	  });
	
	  if (tabsCount !== panelsCount) {
	    error = new Error('There should be an equal number of `Tabs` and `TabPanels`. ' + 'Received ' + tabsCount + ' `Tabs` and ' + panelsCount + ' `TabPanels`.');
	  }
	
	  return error;
	};

/***/ },
/* 6 */
/***/ function(module, exports, __webpack_require__) {

	/* eslint indent:0 */
	'use strict';
	
	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }
	
	var _react = __webpack_require__(2);
	
	var _react2 = _interopRequireDefault(_react);
	
	function syncNodeAttributes(node, props) {
	  if (props.selected) {
	    node.setAttribute('tabindex', 0);
	    node.setAttribute('selected', 'selected');
	    if (props.focus) {
	      node.focus();
	    }
	  } else {
	    node.removeAttribute('tabindex');
	    node.removeAttribute('selected');
	  }
	}
	
	module.exports = _react2['default'].createClass({
	  displayName: 'Tab',
	
	  propTypes: {
	    id: _react.PropTypes.string,
	    selected: _react.PropTypes.bool,
	    disabled: _react.PropTypes.bool,
	    panelId: _react.PropTypes.string,
	    children: _react.PropTypes.oneOfType([_react.PropTypes.array, _react.PropTypes.object, _react.PropTypes.string])
	  },
	
	  getDefaultProps: function getDefaultProps() {
	    return {
	      focus: false,
	      selected: false,
	      id: null,
	      panelId: null
	    };
	  },
	
	  componentDidMount: function componentDidMount() {
	    syncNodeAttributes(this.getDOMNode(), this.props);
	  },
	
	  componentDidUpdate: function componentDidUpdate() {
	    syncNodeAttributes(this.getDOMNode(), this.props);
	  },
	
	  render: function render() {
	    return _react2['default'].createElement(
	      'li',
	      {
	        role: 'tab',
	        id: this.props.id,
	        'aria-selected': this.props.selected ? 'true' : 'false',
	        'aria-expanded': this.props.selected ? 'true' : 'false',
	        'aria-disabled': this.props.disabled ? 'true' : 'false',
	        'aria-controls': this.props.panelId
	      },
	      this.props.children
	    );
	  }
	});

/***/ },
/* 7 */
/***/ function(module, exports, __webpack_require__) {

	/* eslint indent:0 */
	'use strict';
	
	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }
	
	var _react = __webpack_require__(2);
	
	var _react2 = _interopRequireDefault(_react);
	
	module.exports = _react2['default'].createClass({
	  displayName: 'TabList',
	
	  propTypes: {
	    children: _react.PropTypes.oneOfType([_react.PropTypes.object, _react.PropTypes.array])
	  },
	
	  render: function render() {
	    return _react2['default'].createElement(
	      'ul',
	      { role: 'tablist' },
	      this.props.children
	    );
	  }
	});

/***/ },
/* 8 */
/***/ function(module, exports) {

	'use strict';
	
	module.exports = {
	  '.react-tabs [role=tablist]': {
	    'border-bottom': '1px solid #aaa',
	    'margin': '0 0 10px',
	    'padding': '0'
	  },
	
	  '.react-tabs [role=tab]': {
	    'display': 'inline-block',
	    'border': '1px solid transparent',
	    'border-bottom': 'none',
	    'bottom': '-1px',
	    'position': 'relative',
	    'list-style': 'none',
	    'padding': '6px 12px',
	    'cursor': 'pointer'
	  },
	
	  '.react-tabs [role=tab][aria-selected=true]': {
	    'background': '#fff',
	    'border-color': '#aaa',
	    'border-radius': '5px 5px 0 0',
	    '-moz-border-radius': '5px 5px 0 0',
	    '-webkit-border-radius': '5px 5px 0 0'
	  },
	
	  '.react-tabs [role=tab][aria-disabled=true]': {
	    'color': 'GrayText',
	    'cursor': 'default'
	  },
	
	  '.react-tabs [role=tab]:focus': {
	    'box-shadow': '0 0 5px hsl(208, 99%, 50%)',
	    'border-color': 'hsl(208, 99%, 50%)',
	    'outline': 'none'
	  },
	
	  '.react-tabs [role=tab]:focus:after': {
	    'content': '""',
	    'position': 'absolute',
	    'height': '5px',
	    'left': '-4px',
	    'right': '-4px',
	    'bottom': '-5px',
	    'background': '#fff'
	  }
	};

/***/ },
/* 9 */
/***/ function(module, exports, __webpack_require__) {

	/* eslint indent:0 */
	'use strict';
	
	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }
	
	var _react = __webpack_require__(2);
	
	var _react2 = _interopRequireDefault(_react);
	
	module.exports = _react2['default'].createClass({
	  displayName: 'TabPanel',
	
	  propTypes: {
	    selected: _react.PropTypes.bool,
	    id: _react.PropTypes.string,
	    tabId: _react.PropTypes.string,
	    children: _react.PropTypes.oneOfType([_react.PropTypes.array, _react.PropTypes.object, _react.PropTypes.string])
	  },
	
	  contextTypes: {
	    forceRenderTabPanel: _react.PropTypes.bool
	  },
	
	  getDefaultProps: function getDefaultProps() {
	    return {
	      selected: false,
	      id: null,
	      tabId: null
	    };
	  },
	
	  render: function render() {
	    var children = this.context.forceRenderTabPanel || this.props.selected ? this.props.children : null;
	
	    return _react2['default'].createElement(
	      'div',
	      {
	        role: 'tabpanel',
	        id: this.props.id,
	        'aria-labeledby': this.props.tabId,
	        style: { display: this.props.selected ? null : 'none' }
	      },
	      children
	    );
	  }
	});

/***/ }
/******/ ])
});
;
//# sourceMappingURL=react-tabs.js.map