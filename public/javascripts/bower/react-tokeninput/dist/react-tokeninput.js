(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("react"));
	else if(typeof define === 'function' && define.amd)
		define(["react"], factory);
	else if(typeof exports === 'object')
		exports["TokenInput"] = factory(require("react"));
	else
		root["TokenInput"] = factory(root["React"]);
})(this, function(__WEBPACK_EXTERNAL_MODULE_3__) {
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

	var TokenInput = __webpack_require__(1)
	TokenInput.Option = __webpack_require__(2)
	
	module.exports = TokenInput


/***/ },
/* 1 */
/***/ function(module, exports, __webpack_require__) {

	var React = __webpack_require__(3);
	var Combobox = React.createFactory(__webpack_require__(4));
	var Token = React.createFactory(__webpack_require__(5));
	
	var ul = React.createFactory('ul');
	var li = React.createFactory('li');
	
	module.exports = React.createClass({displayName: "exports",
	  propTypes: {
	    onInput: React.PropTypes.func,
	    onSelect: React.PropTypes.func.isRequired,
	    onRemove: React.PropTypes.func.isRequired,
	    selected: React.PropTypes.array.isRequired,
	    menuContent: React.PropTypes.any
	  },
	
	  getInitialState: function() {
	    return {
	      selectedToken: null
	    };
	  },
	
	  handleClick: function() {
	    // TODO: Expand combobox API for focus
	    this.refs['combo-li'].getDOMNode().querySelector('input').focus();
	  },
	
	  handleInput: function(event) {
	    this.props.onInput(event);
	  },
	
	  handleSelect: function(event) {
	    this.props.onSelect(event)
	    this.setState({
	      selectedToken: null
	    })
	  },
	
	  handleRemove: function(value) {
	    this.props.onRemove(value);
	    this.refs['combo-li'].getDOMNode().querySelector('input').focus();
	  },
	
	  handleRemoveLast: function() {
	    this.props.onRemove(this.props.selected[this.props.selected.length - 1]);
	  },
	
	  render: function() {
	    var tokens = this.props.selected.map(function(token) {
	      return (
	        Token({
	          onRemove: this.handleRemove,
	          value: token,
	          name: token.name,
	          key: token.id})
	      )
	    }.bind(this))
	
	    return ul({className: 'ic-tokens flex', onClick: this.handleClick},
	      tokens,
	      li({className: 'inline-flex', ref: 'combo-li'},
	        Combobox({
	          id: this.props.id,
	          ariaLabel: this.props['combobox-aria-label'],
	          onInput: this.handleInput,
	          onSelect: this.handleSelect,
	          onRemoveLast: this.handleRemoveLast,
	          value: this.state.selectedToken
	        },
	          this.props.menuContent
	        )
	      )
	    );
	  }
	})


/***/ },
/* 2 */
/***/ function(module, exports, __webpack_require__) {

	var React = __webpack_require__(3);
	var addClass = __webpack_require__(6);
	var div = React.createFactory('div');
	
	module.exports = React.createClass({displayName: "exports",
	
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
	
	  getDefaultProps: function() {
	    return {
	      role: 'option',
	      tabIndex: '-1',
	      className: 'ic-tokeninput-option',
	      isSelected: false
	    };
	  },
	
	  render: function() {
	    var props = this.props;
	    if (props.isSelected) {
	      props.className = addClass(props.className, 'ic-tokeninput-selected');
	      props.ariaSelected = true;
	    }
	    return div(props);
	  }
	
	});


/***/ },
/* 3 */
/***/ function(module, exports, __webpack_require__) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_3__;

/***/ },
/* 4 */
/***/ function(module, exports, __webpack_require__) {

	var React = __webpack_require__(3);
	var guid = 0;
	var k = function(){};
	var addClass = __webpack_require__(6);
	var ComboboxOption = React.createFactory(__webpack_require__(2));
	
	var div = React.createFactory('div');
	var span = React.createFactory('span');
	var input = React.createFactory('input');
	
	module.exports = React.createClass({displayName: "exports",
	
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
	    onSelect: React.PropTypes.func
	  },
	
	  getDefaultProps: function() {
	    return {
	      autocomplete: 'both',
	      onInput: k,
	      onSelect: k,
	      value: null
	    };
	  },
	
	  getInitialState: function() {
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
	      listId: 'ic-tokeninput-list-'+(++guid),
	      menu: {
	        children: [],
	        activedescendant: null,
	        isEmpty: true
	      }
	    };
	  },
	
	  componentWillMount: function() {
	    this.setState({menu: this.makeMenu()});
	  },
	
	  componentWillReceiveProps: function(newProps) {
	    this.setState({menu: this.makeMenu(newProps.children)}, function() {
	      if(newProps.children.length && (this.isOpen || document.activeElement === this.refs.input.getDOMNode())) {
	        this.showList();
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
	  makeMenu: function(children) {
	    var activedescendant;
	    var isEmpty = true;
	    children = children || this.props.children;
	
	    // Should this instead use React.addons.cloneWithProps or React.cloneElement?
	    React.Children.forEach(children, function(child, index) {
	      if (child.type !== ComboboxOption.type)
	        // allow random elements to live in this list
	        return;
	      isEmpty = false;
	      // TODO: cloneWithProps and map instead of altering the children in-place
	      var props = child.props;
	      if (this.state.value === props.value) {
	        // need an ID for WAI-ARIA
	        props.id = props.id || 'ic-tokeninput-selected-'+(++guid);
	        props.isSelected = true
	        activedescendant = props.id;
	      }
	      props.onBlur = this.handleOptionBlur;
	      props.onClick = this.selectOption.bind(this, child);
	      props.onFocus = this.handleOptionFocus;
	      props.onKeyDown = this.handleOptionKeyDown.bind(this, child);
	      props.onMouseEnter = this.handleOptionMouseEnter.bind(this, index);
	    }.bind(this));
	
	    return {
	      children: children,
	      activedescendant: activedescendant,
	      isEmpty: isEmpty
	    };
	  },
	
	  getClassName: function() {
	    var className = addClass(this.props.className, 'ic-tokeninput');
	    if (this.state.isOpen)
	      className = addClass(className, 'ic-tokeninput-is-open');
	    return className;
	  },
	
	  /**
	   * When the user begins typing again we need to clear out any state that has
	   * to do with an existing or potential selection.
	  */
	  clearSelectedState: function(cb) {
	    this.setState({
	      focusedIndex: null,
	      inputValue: null,
	      value: null,
	      matchedAutocompleteOption: null,
	      activedescendant: null
	    }, cb);
	  },
	
	  handleInputChange: function(event) {
	    var value = this.refs.input.getDOMNode().value;
	    this.clearSelectedState(function() {
	      this.props.onInput(value);
	    }.bind(this));
	  },
	
	  handleInputBlur: function() {
	    var focusedAnOption = this.state.focusedIndex != null;
	    if (focusedAnOption)
	      return;
	    this.maybeSelectAutocompletedOption();
	    this.hideList();
	  },
	
	  handleOptionBlur: function() {
	    // don't want to hide the list if we focused another option
	    this.blurTimer = setTimeout(this.hideList, 0);
	  },
	
	  handleOptionFocus: function() {
	    // see `handleOptionBlur`
	    clearTimeout(this.blurTimer);
	  },
	
	  handleInputKeyUp: function(event) {
	    if (
	      this.state.menu.isEmpty ||
	      // autocompleting while backspacing feels super weird, so let's not
	      event.keyCode === 8 /*backspace*/ ||
	      !this.props.autocomplete.match(/both|inline/)
	    ) return;
	  },
	
	  handleButtonClick: function() {
	    this.state.isOpen ? this.hideList() : this.showList();
	    this.focusInput();
	  },
	
	  showList: function() {
	    if(!this.state.menu.children.length) {
	      return
	    }
	    this.setState({isOpen: true})
	  },
	
	  hideList: function() {
	    this.setState({isOpen: false});
	  },
	
	  hideOnEscape: function(event) {
	    this.hideList();
	    this.focusInput();
	    event.preventDefault();
	  },
	
	  focusInput: function() {
	    this.refs.input.getDOMNode().focus();
	  },
	
	  selectInput: function() {
	    this.refs.input.getDOMNode().select();
	  },
	
	  inputKeydownMap: {
	    8: 'removeLastToken',
	    13: 'selectOnEnter',
	    27: 'hideOnEscape',
	    38: 'focusPrevious',
	    40: 'focusNext'
	  },
	
	  optionKeydownMap: {
	    13: 'selectOption',
	    27: 'hideOnEscape',
	    38: 'focusPrevious',
	    40: 'focusNext'
	  },
	
	  handleKeydown: function(event) {
	    var handlerName = this.inputKeydownMap[event.keyCode];
	    if (!handlerName)
	      return
	    this.setState({usingKeyboard: true});
	    return this[handlerName].call(this,event);
	  },
	
	  handleOptionKeyDown: function(child, event) {
	    var handlerName = this.optionKeydownMap[event.keyCode];
	    if (!handlerName) {
	      // if the user starts typing again while focused on an option, move focus
	      // to the inpute, select so it wipes out any existing value
	      this.selectInput();
	      return;
	    }
	    event.preventDefault();
	    this.setState({usingKeyboard: true});
	    this[handlerName].call(this, child);
	  },
	
	  handleOptionMouseEnter: function(index) {
	    if (this.state.usingKeyboard)
	      this.setState({usingKeyboard: false});
	    else
	      this.focusOptionAtIndex(index);
	  },
	
	  selectOnEnter: function(event) {
	    event.preventDefault();
	    this.maybeSelectAutocompletedOption()
	  },
	
	  maybeSelectAutocompletedOption: function() {
	    if (!this.state.matchedAutocompleteOption) {
	      this.selectText()
	    } else {
	      this.selectOption(this.state.matchedAutocompleteOption, {focus: false});
	    }
	  },
	
	  selectOption: function(child, options) {
	    options = options || {};
	    this.setState({
	      // value: child.props.value,
	      // inputValue: getLabel(child),
	      matchedAutocompleteOption: null
	    }, function() {
	      this.props.onSelect(child.props.value, child);
	      this.hideList();
	      this.clearSelectedState(); // added
	      if (options.focus !== false)
	        this.selectInput();
	    }.bind(this));
	    this.refs.input.getDOMNode().value = '' // added
	  },
	
	  selectText: function() {
	    var value = this.refs.input.getDOMNode().value;
	    if(!value) return;
	    this.props.onSelect(value);
	    this.clearSelectedState();
	    this.refs.input.getDOMNode().value = '' // added
	  },
	
	  focusNext: function(event) {
	    if(event.preventDefault) event.preventDefault();
	    if (this.state.menu.isEmpty) return;
	    var index = this.state.focusedIndex == null ?
	      0 : this.state.focusedIndex + 1;
	    this.focusOptionAtIndex(index);
	  },
	
	  removeLastToken: function() {
	    if(this.props.onRemoveLast && !this.refs.input.getDOMNode().value) {
	      this.props.onRemoveLast()
	    }
	    return true
	  },
	
	  focusPrevious: function(event) {
	    if(event.preventDefault) event.preventDefault();
	    if (this.state.menu.isEmpty) return;
	    var last = this.props.children.length - 1;
	    var index = this.state.focusedIndex == null ?
	      last : this.state.focusedIndex - 1;
	    this.focusOptionAtIndex(index);
	  },
	
	  focusSelectedOption: function() {
	    var selectedIndex;
	    React.Children.forEach(this.props.children, function(child, index) {
	      if (child.props.value === this.state.value)
	        selectedIndex = index;
	    }.bind(this));
	    this.showList();
	    this.setState({
	      focusedIndex: selectedIndex
	    }, this.focusOption);
	  },
	
	  findInitialInputValue: function() {
	    // TODO: might not need this, we should know this in `makeMenu`
	    var inputValue;
	    React.Children.forEach(this.props.children, function(child) {
	      if (child.props.value === this.props.value)
	        inputValue = getLabel(child);
	    }.bind(this));
	    return inputValue;
	  },
	
	  focusOptionAtIndex: function(index) {
	    if (!this.state.isOpen && this.state.value)
	      return this.focusSelectedOption();
	    this.showList();
	    var length = this.props.children.length;
	    if (index === -1)
	      index = length - 1;
	    else if (index === length)
	      index = 0;
	    this.setState({
	      focusedIndex: index
	    }, this.focusOption);
	  },
	
	  focusOption: function() {
	    var index = this.state.focusedIndex;
	    this.refs.list.getDOMNode().childNodes[index].focus();
	  },
	
	  render: function() {
	    var ariaLabel = this.props['aria-label'] || 'Start typing to search. ' +
	      'Press the down arrow to navigate results. If you don\'t find an ' +
	      'acceptable option, you can enter an alternative.'
	
	    return div({className: this.getClassName()},
	      this.props.value,
	      this.state.inputValue,
	      input({
	        ref: 'input',
	        autoComplete: 'off',
	        spellCheck: 'false',
	        'aria-label': ariaLabel,
	        'aria-expanded': this.state.isOpen+'',
	        'aria-haspopup': 'true',
	        'aria-activedescendant': this.state.menu.activedescendant,
	        'aria-autocomplete': 'list',
	        'aria-owns': this.state.listId,
	        id: this.props.id,
	        className: 'ic-tokeninput-input',
	        onChange: this.handleInputChange,
	        onBlur: this.handleInputBlur,
	        onKeyDown: this.handleKeydown,
	        onKeyUp: this.handleInputKeyUp,
	        role: 'combobox'
	      }),
	      span({
	        'aria-hidden': 'true',
	        className: 'ic-tokeninput-button',
	        onClick: this.handleButtonClick
	      }, '▾'),
	      div({
	        id: this.state.listId,
	        ref: 'list',
	        className: 'ic-tokeninput-list',
	        role: 'listbox'
	      }, this.state.menu.children)
	    );
	  }
	});
	
	function getLabel(component) {
	  return component.props.label || component.props.children;
	}
	
	function matchFragment(userInput, firstChildLabel) {
	  userInput = userInput.toLowerCase();
	  firstChildLabel = firstChildLabel.toLowerCase();
	  if (userInput === '' || userInput === firstChildLabel)
	    return false;
	  if (firstChildLabel.toLowerCase().indexOf(userInput.toLowerCase()) === -1)
	    return false;
	  return true;
	}


/***/ },
/* 5 */
/***/ function(module, exports, __webpack_require__) {

	var React = __webpack_require__(3);
	var span = React.DOM.span;
	var li = React.createFactory('li');
	
	module.exports = React.createClass({displayName: "exports",
	  handleClick: function() {
	    this.props.onRemove(this.props.value)
	  },
	
	  handleKeyDown: function(key) {
	    var enterKey = 13;
	    if(key.keyCode === enterKey) this.props.onRemove(this.props.value)
	  },
	
	  render: function() {
	    return (
	      li({
	        className: "ic-token inline-flex"
	      },
	        span({
	          role: 'button',
	          onClick: this.handleClick,
	          onKeyDown: this.handleKeyDown,
	          'aria-label': 'Remove \'' + this.props.name + '\'',
	          className: "ic-token-delete-button",
	          tabIndex: 0
	        }, "✕"),
	        span({className: "ic-token-label"}, this.props.name)
	      )
	    )
	  }
	})


/***/ },
/* 6 */
/***/ function(module, exports, __webpack_require__) {

	module.exports = addClass;
	
	function addClass(existing, added) {
	  if (!existing) return added;
	  if (existing.indexOf(added) > -1) return existing;
	  return existing + ' ' + added;
	}


/***/ }
/******/ ])
});
;
//# sourceMappingURL=react-tokeninput.js.map