'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.PaginationButton = exports.default = undefined;

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _dec, _class, _class2, _temp2; /*
                                    * The MIT License (MIT)
                                    *
                                    * Copyright (c) 2015 - present Instructure, Inc.
                                    *
                                    * Permission is hereby granted, free of charge, to any person obtaining a copy
                                    * of this software and associated documentation files (the "Software"), to deal
                                    * in the Software without restriction, including without limitation the rights
                                    * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                                    * copies of the Software, and to permit persons to whom the Software is
                                    * furnished to do so, subject to the following conditions:
                                    *
                                    * The above copyright notice and this permission notice shall be included in all
                                    * copies or substantial portions of the Software.
                                    *
                                    * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                                    * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                                    * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                                    * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                                    * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                                    * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                                    * SOFTWARE.
                                    */

var _PaginationButton = require('@instructure/ui-pagination/lib/components/Pagination/PaginationButton');

Object.defineProperty(exports, 'PaginationButton', {
  enumerable: true,
  get: function get() {
    return _interopRequireDefault(_PaginationButton).default;
  }
});

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _Button = require('@instructure/ui-buttons/lib/components/Button');

var _Button2 = _interopRequireDefault(_Button);

var _View = require('@instructure/ui-layout/lib/components/View');

var _View2 = _interopRequireDefault(_View);

var _IconArrowOpenStart = require('@instructure/ui-icons/lib/Solid/IconArrowOpenStart');

var _IconArrowOpenStart2 = _interopRequireDefault(_IconArrowOpenStart);

var _IconArrowOpenEnd = require('@instructure/ui-icons/lib/Solid/IconArrowOpenEnd');

var _IconArrowOpenEnd2 = _interopRequireDefault(_IconArrowOpenEnd);

var _uiThemeable = require('@instructure/ui-themeable');

var _uiThemeable2 = _interopRequireDefault(_uiThemeable);

var _passthroughProps = require('@instructure/ui-utils/lib/react/passthroughProps');

var _CustomPropTypes = require('@instructure/ui-utils/lib/react/CustomPropTypes');

var _CustomPropTypes2 = _interopRequireDefault(_CustomPropTypes);

var _ThemeablePropTypes = require('@instructure/ui-themeable/lib/utils/ThemeablePropTypes');

var _ThemeablePropTypes2 = _interopRequireDefault(_ThemeablePropTypes);

var _findTabbable = require('@instructure/ui-a11y/lib/utils/findTabbable');

var _findTabbable2 = _interopRequireDefault(_findTabbable);

var _ScreenReaderContent = require('@instructure/ui-a11y/lib/components/ScreenReaderContent');

var _ScreenReaderContent2 = _interopRequireDefault(_ScreenReaderContent);

var _PaginationButton2 = _interopRequireDefault(_PaginationButton);

var _theme = require('@instructure/ui-pagination/lib/components/Pagination/theme');

var _theme2 = _interopRequireDefault(_theme);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var styles = {
  template: function template(theme) {
    var tmpl = function tmpl() {
      return '/*  imported from styles.css  */\n\n._1SqaD8I {\n  text-align: center;\n}\n\n[dir="ltr"] ._1SqaD8I {\n  text-align: center;\n}\n\n[dir="rtl"] ._1SqaD8I {\n  text-align: center;\n}\n\n.B-miP21 {\n  display: inline-flex;\n  align-items: center;\n}\n';
    };

    return tmpl.call(theme, theme);
  },
  'root': '_1SqaD8I',
  'pages': 'B-miP21'
};

/** This is an [].findIndex optimized to work on really big, but sparse, arrays */

var fastFindIndex = function fastFindIndex(arr, fn) {
  return Number(Object.keys(arr).find(function (k) {
    return fn(arr[Number(k)]);
  }));
};

function propsHaveCompactView(props) {
  return props.variant === 'compact' && props.children.length > 5;
}

function shouldShowPrevButton(props, currentPageIndex) {
  return propsHaveCompactView(props) && currentPageIndex > 0;
}

function shouldShowNextButton(props, currentPageIndex) {
  return propsHaveCompactView(props) && currentPageIndex < props.children.length - 1;
}

/**
---
category: components/navigation
---
**/
var Pagination = (_dec = (0, _uiThemeable2.default)(_theme2.default, styles), _dec(_class = (_temp2 = _class2 = function (_Component) {
  _inherits(Pagination, _Component);

  function Pagination() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Pagination);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Pagination.__proto__ || Object.getPrototypeOf(Pagination)).call.apply(_ref, [this].concat(args))), _this), _this.handleElementRef = function (el) {
      if (el) {
        _this._root = el;
        if (typeof _this.props.elementRef === 'function') {
          _this.props.elementRef(el);
        }
      }
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Pagination, [{
    key: 'componentWillReceiveProps',
    value: function componentWillReceiveProps(nextProps) {
      if (!nextProps.shouldHandleFocus) {
        return;
      }

      if (!propsHaveCompactView(this.props) && !propsHaveCompactView(nextProps)) {
        return;
      }

      var focusable = (0, _findTabbable2.default)(this._root);
      if (focusable[0] === document.activeElement && !shouldShowPrevButton(nextProps)) {
        // Previous Page button has focus, but will no longer be rendered
        this._moveFocusTo = 'first';
        return;
      }

      if (focusable[focusable.length - 1] === document.activeElement && !shouldShowNextButton(nextProps)) {
        // Next Page button has focus, but will no longer be rendered
        this._moveFocusTo = 'last';
        return;
      }
    }
  }, {
    key: 'componentDidUpdate',
    value: function componentDidUpdate() {
      if (this.props.shouldHandleFocus === false || this.compactView === false) {
        return;
      }

      if (this._moveFocusTo != null) {
        var focusable = (0, _findTabbable2.default)(this._root);
        var focusIndex = this._moveFocusTo === 'first' ? 0 : focusable.length - 1;
        focusable[focusIndex].focus();
        delete this._moveFocusTo;
      }
    }
  }, {
    key: 'transferDisabledPropToChildren',
    value: function transferDisabledPropToChildren(children) {
      var _this2 = this;

      return this.props.disabled ? _react2.default.Children.map(children, function (page) {
        return _react2.default.cloneElement(page, { disabled: _this2.props.disabled });
      }) : children;
    }
  }, {
    key: 'renderLabel',
    value: function renderLabel() {
      if (this.props.label) {
        var display = this.props.variant === 'compact' ? 'block' : 'inline-block';
        return _react2.default.createElement(
          _View2.default,
          { padding: 'small', display: display },
          this.props.label
        );
      }
    }
  }, {
    key: 'renderPages',
    value: function renderPages(currentPageIndex) {
      var allPages = this.props.children;
      var visiblePages = allPages;

      if (this.compactView) {
        var firstIndex = 0;
        var lastIndex = allPages.length - 1;

        var sliceStart = Math.max(currentPageIndex - 1, firstIndex);
        var sliceEnd = Math.min(currentPageIndex + 4, lastIndex);

        visiblePages = allPages.slice(sliceStart, sliceEnd);

        var firstPage = allPages[firstIndex];
        var lastPage = allPages[lastIndex];

        if (sliceStart - firstIndex > 1) visiblePages.unshift(_react2.default.createElement(
          'span',
          { key: 'first', 'aria-hidden': 'true' },
          '...'
        ));
        if (sliceStart - firstIndex > 0) visiblePages.unshift(firstPage);
        if (lastIndex - sliceEnd + 1 > 1) visiblePages.push(_react2.default.createElement(
          'span',
          { key: 'last', 'aria-hidden': 'true' },
          '...'
        ));
        if (lastIndex - sliceEnd + 1 > 0) visiblePages.push(lastPage);
      }

      return _react2.default.createElement(
        _View2.default,
        { display: 'inline-block' },
        this.transferDisabledPropToChildren(visiblePages)
      );
    }
  }, {
    key: 'renderArrowButton',
    value: function renderArrowButton(icon, title, direction, currentPageIndex) {
      var _props$children$props = this.props.children[currentPageIndex + direction].props,
          onClick = _props$children$props.onClick,
          disabled = _props$children$props.disabled;

      return _react2.default.createElement(
        _Button2.default,
        {
          onClick: onClick,
          disabled: this.props.disabled || disabled,
          variant: 'icon',
          size: 'small',
          title: title,
          icon: icon
        },
        _react2.default.createElement(
          _ScreenReaderContent2.default,
          null,
          title
        )
      );
    }
  }, {
    key: 'render',
    value: function render() {
      var currentPageIndex = fastFindIndex(this.props.children, function (p) {
        return p && p.props && p.props.current;
      });

      return _react2.default.createElement(
        _View2.default,
        Object.assign({}, (0, _passthroughProps.omitProps)(this.props, Object.assign({}, Pagination.propTypes, _View2.default.propTypes)), {
          role: 'navigation',
          as: this.props.as,
          elementRef: this.handleElementRef,
          margin: this.props.margin,
          className: styles.root
        }),
        this.renderLabel(),
        _react2.default.createElement(
          _View2.default,
          { display: 'inline-block', className: styles.pages },
          shouldShowPrevButton(this.props, currentPageIndex) && this.renderArrowButton(_IconArrowOpenStart2.default, this.props.labelPrev, -1, currentPageIndex),
          this.renderPages(currentPageIndex),
          shouldShowNextButton(this.props, currentPageIndex) && this.renderArrowButton(_IconArrowOpenEnd2.default, this.props.labelNext, 1, currentPageIndex)
        )
      );
    }
  }, {
    key: 'compactView',
    get: function get() {
      return propsHaveCompactView(this.props);
    }
  }]);

  Pagination.displayName = 'Pagination'
  ;
  return Pagination;
}(_react.Component), _class2.propTypes = {
  /**
  * children of type PaginationButton
  */
  children: _CustomPropTypes2.default.Children.oneOf([_PaginationButton2.default]),
  /**
  * Disables interaction with all pages
  */
  disabled: _propTypes2.default.bool,
  /**
  * Visible label for component
  */
  label: _propTypes2.default.string,
  /**
  * Accessible label for next button
  */
  labelNext: _propTypes2.default.string,
  /**
  * Accessible label for previous button
  */
  labelPrev: _propTypes2.default.string,
  variant: _propTypes2.default.oneOf(['full', 'compact']),
  /**
  * Valid values are `0`, `none`, `auto`, `xxx-small`, `xx-small`, `x-small`,
  * `small`, `medium`, `large`, `x-large`, `xx-large`. Apply these values via
  * familiar CSS-like shorthand. For example: `margin="small auto large"`.
  */
  margin: _ThemeablePropTypes2.default.spacing,
  /**
  * the element type to render as
  */
  as: _CustomPropTypes2.default.elementType,
  /**
  * provides a reference to the underlying html root element
  */
  elementRef: _propTypes2.default.func,
  /**
  * For accessibility, Pagination sets focus on the first or last PaginationButtons,
  * respectively, when the Previous or Next arrow buttons are removed from the DOM.
  * Set this property to `false` to prevent this behavior.
  */
  shouldHandleFocus: _propTypes2.default.bool
}, _class2.defaultProps = {
  disabled: false,
  variant: 'full',
  as: 'div',
  elementRef: function elementRef(el) {},
  shouldHandleFocus: true
}, _temp2)) || _class);
exports.default = Pagination;