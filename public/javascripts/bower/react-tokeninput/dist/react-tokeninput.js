(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("react"));
	else if(typeof define === 'function' && define.amd)
		define(["react"], factory);
	else if(typeof exports === 'object')
		exports["TokenInput"] = factory(require("react"));
	else
		root["TokenInput"] = factory(root["react"]);
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
/******/ 	__webpack_require__.p = "/";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';
	
	Object.defineProperty(exports, "__esModule", {
	  value: true
	});
	exports.Token = exports.Option = exports.Combobox = undefined;
	
	var _combobox = __webpack_require__(1);
	
	var _combobox2 = _interopRequireDefault(_combobox);
	
	var _option = __webpack_require__(4);
	
	var _option2 = _interopRequireDefault(_option);
	
	var _token = __webpack_require__(5);
	
	var _token2 = _interopRequireDefault(_token);
	
	var _main = __webpack_require__(6);
	
	var _main2 = _interopRequireDefault(_main);
	
	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }
	
	exports.Combobox = _combobox2.default;
	exports.Option = _option2.default;
	exports.Token = _token2.default;
	
	
	/**
	 * You can't do an import and then immediately export it :(
	 * And `export default TokenInput from './main'` doesn't seem to
	 * work either :(
	 * So this little variable swapping stuff gets it to work.
	 */
	var TokenInput = _main2.default;
	exports.default = TokenInput;

/***/ },
/* 1 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';
	
	var React = __webpack_require__(2);
	var guid = 0;
	var k = function k() {};
	var addClass = __webpack_require__(3);
	var ComboboxOption = __webpack_require__(4);
	
	var div = React.createFactory('div');
	var span = React.createFactory('span');
	var input = React.createFactory('input');
	
	module.exports = React.createClass({
	  displayName: 'exports',
	
	
	  propTypes: {
	    /**
	     * Called when the combobox receives user input, this is your chance to
	     * filter the data and rerender the options.
	     *
	     * Signature:
	     *
	     * ```js
	     * function(userInput){}
	     * ```
	    */
	    onInput: React.PropTypes.func,
	
	    /**
	     * Called when the combobox receives a selection. You probably want to reset
	     * the options to the full list at this point.
	     *
	     * Signature:
	     *
	     * ```js
	     * function(selectedValue){}
	     * ```
	    */
	    onSelect: React.PropTypes.func,
	
	    /**
	     * Shown when the combobox is empty.
	    */
	    placeholder: React.PropTypes.string
	  },
	
	  getDefaultProps: function getDefaultProps() {
	    return {
	      autocomplete: 'both',
	      onInput: k,
	      onSelect: k,
	      value: null,
	      showListOnFocus: false
	    };
	  },
	
	  getInitialState: function getInitialState() {
	    return {
	      value: this.props.value,
	      // the value displayed in the input
	      inputValue: this.findInitialInputValue(),
	      isOpen: false,
	      focusedIndex: null,
	      matchedAutocompleteOption: null,
	      // this prevents crazy jumpiness since we focus options on mouseenter
	      usingKeyboard: false,
	      activedescendant: null,
	      listId: 'ic-tokeninput-list-' + ++guid,
	      menu: {
	        children: [],
	        activedescendant: null,
	        isEmpty: true
	      }
	    };
	  },
	
	  componentWillMount: function componentWillMount() {
	    this.setState({ menu: this.makeMenu(this.props.children) });
	  },
	
	  componentWillReceiveProps: function componentWillReceiveProps(newProps) {
	    this.setState({ menu: this.makeMenu(newProps.children) }, function () {
	      if (newProps.children.length && (this.isOpen || document.activeElement === this.refs.input)) {
	        if (!this.state.menu.children.length) {
	          return;
	        }
	        this.setState({
	          isOpen: true
	        }, function () {
	          this.refs.list.scrollTop = 0;
	        }.bind(this));
	      } else {
	        this.hideList();
	      }
	    }.bind(this));
	  },
	
	  /**
	   * We don't create the <ComboboxOption> components, the user supplies them,
	   * so before rendering we attach handlers to facilitate communication from
	   * the ComboboxOption to the Combobox.
	  */
	  makeMenu: function makeMenu(children) {
	    var activedescendant;
	    var isEmpty = true;
	
	    // Should this instead use React.addons.cloneWithProps or React.cloneElement?
	    var _children = React.Children.map(children, function (child, index) {
	      // console.log(child.type, ComboboxOption.type)
	      if (child.type !== ComboboxOption) {
	        // allow random elements to live in this list
	        return child;
	      }
	      isEmpty = false;
	      // TODO: cloneWithProps and map instead of altering the children in-place
	      var props = child.props;
	      var newProps = {};
	      if (this.state.value === child.props.value) {
	        // need an ID for WAI-ARIA
	        newProps.id = props.id || 'ic-tokeninput-selected-' + ++guid;
	        newProps.isSelected = true;
	        activedescendant = props.id;
	      }
	      newProps.onBlur = this.handleOptionBlur;
	      newProps.onClick = this.selectOption.bind(this, child);
	      newProps.onFocus = this.handleOptionFocus;
	      newProps.onKeyDown = this.handleOptionKeyDown.bind(this, child);
	      newProps.onMouseEnter = this.handleOptionMouseEnter.bind(this, index);
	
	      return React.cloneElement(child, newProps);
	    }.bind(this));
	
	    return {
	      children: _children,
	      activedescendant: activedescendant,
	      isEmpty: isEmpty
	    };
	  },
	
	  getClassName: function getClassName() {
	    var className = addClass(this.props.className, 'ic-tokeninput');
	    if (this.state.isOpen) className = addClass(className, 'ic-tokeninput-is-open');
	    return className;
	  },
	
	  /**
	   * When the user begins typing again we need to clear out any state that has
	   * to do with an existing or potential selection.
	  */
	  clearSelectedState: function clearSelectedState(cb) {
	    this.setState({
	      focusedIndex: null,
	      inputValue: null,
	      value: null,
	      matchedAutocompleteOption: null,
	      activedescendant: null
	    }, cb);
	  },
	
	  handleInputChange: function handleInputChange() {
	    var value = this.refs.input.value;
	    this.clearSelectedState(function () {
	      this.props.onInput(value);
	    }.bind(this));
	  },
	
	  handleInputFocus: function handleInputFocus() {
	    this.maybeShowList();
	  },
	
	  handleInputClick: function handleInputClick() {
	    this.maybeShowList();
	  },
	
	  maybeShowList: function maybeShowList() {
	    if (this.props.showListOnFocus) {
	      this.showList();
	    }
	  },
	
	  handleInputBlur: function handleInputBlur() {
	    var focusedAnOption = this.state.focusedIndex != null;
	    if (focusedAnOption) return;
	    this.maybeSelectAutocompletedOption();
	    this.hideList();
	  },
	
	  handleOptionBlur: function handleOptionBlur() {
	    // don't want to hide the list if we focused another option
	    this.blurTimer = setTimeout(this.hideList, 0);
	  },
	
	  handleOptionFocus: function handleOptionFocus() {
	    // see `handleOptionBlur`
	    clearTimeout(this.blurTimer);
	  },
	
	  handleInputKeyUp: function handleInputKeyUp(event) {
	    if (this.state.menu.isEmpty ||
	    // autocompleting while backspacing feels super weird, so let's not
	    event.keyCode === 8 /*backspace*/ || !this.props.autocomplete.match(/both|inline/)) return;
	  },
	
	  handleButtonClick: function handleButtonClick() {
	    this.state.isOpen ? this.hideList() : this.showList();
	    this.focusInput();
	  },
	
	  showList: function showList() {
	    if (!this.state.menu.children.length) {
	      return;
	    }
	    this.setState({ isOpen: true });
	  },
	
	  hideList: function hideList() {
	    this.setState({
	      isOpen: false,
	      focusedIndex: null
	    });
	  },
	
	  hideOnEscape: function hideOnEscape(event) {
	    this.hideList();
	    this.focusInput();
	    event.preventDefault();
	  },
	
	  focusInput: function focusInput() {
	    this.refs.input.focus();
	  },
	
	  selectInput: function selectInput() {
	    this.refs.input.select();
	  },
	
	  inputKeydownMap: {
	    8: 'removeLastToken', // delete
	    13: 'selectOnEnter', // enter
	    188: 'selectOnEnter', // comma
	    27: 'hideOnEscape', // escape
	    38: 'focusPrevious', // up arrow
	    40: 'focusNext' // down arrow
	  },
	
	  optionKeydownMap: {
	    13: 'selectOption',
	    27: 'hideOnEscape',
	    38: 'focusPrevious',
	    40: 'focusNext'
	  },
	
	  handleKeydown: function handleKeydown(event) {
	    var handlerName = this.inputKeydownMap[event.keyCode];
	    if (!handlerName) return;
	    this.setState({ usingKeyboard: true });
	    return this[handlerName].call(this, event);
	  },
	
	  handleOptionKeyDown: function handleOptionKeyDown(child, event) {
	    var handlerName = this.optionKeydownMap[event.keyCode];
	    if (!handlerName) {
	      // if the user starts typing again while focused on an option, move focus
	      // to the inpute, select so it wipes out any existing value
	      this.selectInput();
	      return;
	    }
	    event.preventDefault();
	    this.setState({ usingKeyboard: true });
	    this[handlerName].call(this, child);
	  },
	
	  handleOptionMouseEnter: function handleOptionMouseEnter(index) {
	    if (this.state.usingKeyboard) this.setState({ usingKeyboard: false });else this.focusOptionAtIndex(index);
	  },
	
	  selectOnEnter: function selectOnEnter(event) {
	    event.preventDefault();
	    this.maybeSelectAutocompletedOption();
	  },
	
	  maybeSelectAutocompletedOption: function maybeSelectAutocompletedOption() {
	    if (!this.state.matchedAutocompleteOption) {
	      this.selectText();
	    } else {
	      this.selectOption(this.state.matchedAutocompleteOption, { focus: false });
	    }
	  },
	
	  selectOption: function selectOption(child, options) {
	    options = options || {};
	    this.setState({
	      // value: child.props.value,
	      // inputValue: getLabel(child),
	      matchedAutocompleteOption: null
	    }, function () {
	      this.props.onSelect(child.props.value, child);
	      this.hideList();
	      this.clearSelectedState(); // added
	      if (options.focus !== false) this.selectInput();
	    }.bind(this));
	    this.refs.input.value = ''; // added
	  },
	
	  selectText: function selectText() {
	    var value = this.refs.input.value;
	    if (!value) return;
	    this.props.onSelect(value);
	    this.clearSelectedState();
	    this.refs.input.value = ''; // added
	  },
	
	  focusNext: function focusNext(event) {
	    if (event.preventDefault) event.preventDefault();
	    if (this.state.menu.isEmpty) return;
	    var index = this.state.focusedIndex == null ? 0 : this.state.focusedIndex + 1;
	    this.focusOptionAtIndex(index);
	  },
	
	  removeLastToken: function removeLastToken() {
	    if (this.props.onRemoveLast && !this.refs.input.value) {
	      this.props.onRemoveLast();
	    }
	    return true;
	  },
	
	  focusPrevious: function focusPrevious(event) {
	    if (event.preventDefault) event.preventDefault();
	    if (this.state.menu.isEmpty) return;
	    var last = this.props.children.length - 1;
	    var index = this.state.focusedIndex == null ? last : this.state.focusedIndex - 1;
	    this.focusOptionAtIndex(index);
	  },
	
	  focusSelectedOption: function focusSelectedOption() {
	    var selectedIndex;
	    React.Children.forEach(this.props.children, function (child, index) {
	      if (child.props.value === this.state.value) selectedIndex = index;
	    }.bind(this));
	    this.showList();
	    this.setState({
	      focusedIndex: selectedIndex
	    }, this.focusOption);
	  },
	
	  findInitialInputValue: function findInitialInputValue() {
	    // TODO: might not need this, we should know this in `makeMenu`
	    var inputValue;
	    React.Children.forEach(this.props.children, function (child) {
	      if (child.props.value === this.props.value) inputValue = getLabel(child);
	    }.bind(this));
	    return inputValue;
	  },
	
	  focusOptionAtIndex: function focusOptionAtIndex(index) {
	    if (!this.state.isOpen && this.state.value) return this.focusSelectedOption();
	    this.showList();
	    var length = this.props.children.length;
	    if (index === -1) index = length - 1;else if (index === length) index = 0;
	    this.setState({
	      focusedIndex: index
	    }, this.focusOption);
	  },
	
	  focusOption: function focusOption() {
	    var index = this.state.focusedIndex;
	    this.refs.list.childNodes[index].focus();
	  },
	
	  render: function render() {
	    var ariaLabel = this.props['aria-label'] || 'Start typing to search. ' + 'Press the down arrow to navigate results. If you don\'t find an ' + 'acceptable option, you can input an alternative. Once you find or ' + 'input the tag you want, press Enter or Comma to add it.';
	
	    return div({ className: this.getClassName() }, this.props.value, this.state.inputValue, input({
	      ref: 'input',
	      autoComplete: 'off',
	      spellCheck: 'false',
	      'aria-label': ariaLabel,
	      'aria-expanded': this.state.isOpen + '',
	      'aria-haspopup': 'true',
	      'aria-activedescendant': this.state.menu.activedescendant,
	      'aria-autocomplete': 'list',
	      'aria-owns': this.state.listId,
	      id: this.props.id,
	      disabled: this.props.isDisabled,
	      className: 'ic-tokeninput-input',
	      onFocus: this.handleInputFocus,
	      onClick: this.handleInputClick,
	      onChange: this.handleInputChange,
	      onBlur: this.handleInputBlur,
	      onKeyDown: this.handleKeydown,
	      onKeyUp: this.handleInputKeyUp,
	      placeholder: this.props.placeholder,
	      role: 'combobox'
	    }), span({
	      'aria-hidden': 'true',
	      className: 'ic-tokeninput-button',
	      onClick: this.handleButtonClick
	    }, '▾'), div({
	      id: this.state.listId,
	      ref: 'list',
	      className: 'ic-tokeninput-list',
	      role: 'listbox'
	    }, this.state.menu.children));
	  }
	});
	
	function getLabel(component) {
	  return component.props.label || component.props.children;
	}
	
	function matchFragment(userInput, firstChildLabel) {
	  userInput = userInput.toLowerCase();
	  firstChildLabel = firstChildLabel.toLowerCase();
	  if (userInput === '' || userInput === firstChildLabel) return false;
	  if (firstChildLabel.toLowerCase().indexOf(userInput.toLowerCase()) === -1) return false;
	  return true;
	}

/***/ },
/* 2 */
/***/ function(module, exports) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_2__;

/***/ },
/* 3 */
/***/ function(module, exports) {

	'use strict';
	
	module.exports = addClass;
	
	function addClass(existing, added) {
	  if (!existing) return added;
	  if (existing.indexOf(added) > -1) return existing;
	  return existing + ' ' + added;
	}

/***/ },
/* 4 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';
	
	var React = __webpack_require__(2);
	var addClass = __webpack_require__(3);
	var div = React.createFactory('div');
	
	module.exports = React.createClass({
	  displayName: 'exports',
	
	
	  propTypes: {
	
	    /**
	     * The value that will be sent to the `onSelect` handler of the
	     * parent Combobox.
	    */
	    value: React.PropTypes.any.isRequired,
	
	    /**
	     * What value to put into the input element when this option is
	     * selected, defaults to its children coerced to a string.
	    */
	    label: React.PropTypes.string
	  },
	
	  getDefaultProps: function getDefaultProps() {
	    return {
	      role: 'option',
	      tabIndex: '-1',
	      className: 'ic-tokeninput-option',
	      isSelected: false
	    };
	  },
	
	  render: function render() {
	    var props = this.props;
	    if (props.isSelected) {
	      props.className = addClass(props.className, 'ic-tokeninput-selected');
	      props.ariaSelected = true;
	    }
	    return div(props);
	  }
	
	});

/***/ },
/* 5 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';
	
	var React = __webpack_require__(2);
	var span = React.DOM.span;
	var li = React.createFactory('li');
	
	module.exports = React.createClass({
	  displayName: 'exports',
	
	  handleClick: function handleClick() {
	    this.props.onRemove(this.props.value);
	  },
	
	  handleKeyDown: function handleKeyDown(key) {
	    var enterKey = 13;
	    if (key.keyCode === enterKey) this.props.onRemove(this.props.value);
	  },
	
	  render: function render() {
	    return li({
	      className: "ic-token inline-flex"
	    }, span({
	      role: 'button',
	      onClick: this.handleClick,
	      onKeyDown: this.handleKeyDown,
	      'aria-label': 'Remove \'' + this.props.name + '\'',
	      className: "ic-token-delete-button",
	      tabIndex: 0
	    }, "✕"), span({ className: "ic-token-label" }, this.props.name));
	  }
	});

/***/ },
/* 6 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';
	
	var React = __webpack_require__(2);
	var Combobox = React.createFactory(__webpack_require__(1));
	var Token = React.createFactory(__webpack_require__(5));
	var classnames = __webpack_require__(7);
	
	var ul = React.DOM.ul;
	var li = React.DOM.li;
	
	module.exports = React.createClass({
	  displayName: 'exports',
	
	  propTypes: {
	    isLoading: React.PropTypes.bool,
	    loadingComponent: React.PropTypes.any,
	    onInput: React.PropTypes.func,
	    onSelect: React.PropTypes.func.isRequired,
	    onRemove: React.PropTypes.func.isRequired,
	    selected: React.PropTypes.array.isRequired,
	    menuContent: React.PropTypes.any,
	    showListOnFocus: React.PropTypes.bool,
	    placeholder: React.PropTypes.string
	  },
	
	  getInitialState: function getInitialState() {
	    return {
	      selectedToken: null
	    };
	  },
	
	  handleClick: function handleClick() {
	    // TODO: Expand combobox API for focus
	    this.refs['combo-li'].querySelector('input').focus();
	  },
	
	  handleInput: function handleInput(inputValue) {
	    this.props.onInput(inputValue);
	  },
	
	  handleSelect: function handleSelect(event, option) {
	    var input = this.refs['combo-li'].querySelector('input');
	    this.props.onSelect(event, option);
	    this.setState({
	      selectedToken: null
	    });
	    this.props.onInput(input.value);
	  },
	
	  handleRemove: function handleRemove(value) {
	    var input = this.refs['combo-li'].querySelector('input');
	    this.props.onRemove(value);
	    input.focus();
	  },
	
	  handleRemoveLast: function handleRemoveLast() {
	    this.props.onRemove(this.props.selected[this.props.selected.length - 1]);
	  },
	
	  render: function render() {
	    var isDisabled = this.props.isDisabled;
	    var tokens = this.props.selected.map(function (token) {
	      return Token({
	        onRemove: this.handleRemove,
	        value: token,
	        name: token.name,
	        key: token.id });
	    }.bind(this));
	
	    var classes = classnames('ic-tokens flex', {
	      'ic-tokens-disabled': isDisabled
	    });
	
	    return ul({ className: classes, onClick: this.handleClick }, tokens, li({ className: 'inline-flex', ref: 'combo-li' }, Combobox({
	      id: this.props.id,
	      ariaLabel: this.props['combobox-aria-label'],
	      ariaDisabled: isDisabled,
	      onInput: this.handleInput,
	      showListOnFocus: this.props.showListOnFocus,
	      onSelect: this.handleSelect,
	      onRemoveLast: this.handleRemoveLast,
	      value: this.state.selectedToken,
	      isDisabled: isDisabled,
	      placeholder: this.props.placeholder
	    }, this.props.menuContent)), this.props.isLoading && li({ className: 'ic-tokeninput-loading flex' }, this.props.loadingComponent));
	  }
	});

/***/ },
/* 7 */
/***/ function(module, exports, __webpack_require__) {

	var __WEBPACK_AMD_DEFINE_ARRAY__, __WEBPACK_AMD_DEFINE_RESULT__;/*!
	  Copyright (c) 2016 Jed Watson.
	  Licensed under the MIT License (MIT), see
	  http://jedwatson.github.io/classnames
	*/
	/* global define */
	
	(function () {
		'use strict';
	
		var hasOwn = {}.hasOwnProperty;
	
		function classNames () {
			var classes = [];
	
			for (var i = 0; i < arguments.length; i++) {
				var arg = arguments[i];
				if (!arg) continue;
	
				var argType = typeof arg;
	
				if (argType === 'string' || argType === 'number') {
					classes.push(arg);
				} else if (Array.isArray(arg)) {
					classes.push(classNames.apply(null, arg));
				} else if (argType === 'object') {
					for (var key in arg) {
						if (hasOwn.call(arg, key) && arg[key]) {
							classes.push(key);
						}
					}
				}
			}
	
			return classes.join(' ');
		}
	
		if (typeof module !== 'undefined' && module.exports) {
			module.exports = classNames;
		} else if (true) {
			// register as 'classnames', consistent with npm package name
			!(__WEBPACK_AMD_DEFINE_ARRAY__ = [], __WEBPACK_AMD_DEFINE_RESULT__ = function () {
				return classNames;
			}.apply(exports, __WEBPACK_AMD_DEFINE_ARRAY__), __WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
		} else {
			window.classNames = classNames;
		}
	}());


/***/ }
/******/ ])
});
;
//# sourceMappingURL=react-tokeninput.js.map