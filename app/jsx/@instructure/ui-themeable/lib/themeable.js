"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _classCallCheck2 = _interopRequireDefault(require("@babel/runtime/helpers/classCallCheck"));

var _createClass2 = _interopRequireDefault(require("@babel/runtime/helpers/createClass"));

var _possibleConstructorReturn2 = _interopRequireDefault(require("@babel/runtime/helpers/possibleConstructorReturn"));

var _getPrototypeOf3 = _interopRequireDefault(require("@babel/runtime/helpers/getPrototypeOf"));

var _get2 = _interopRequireDefault(require("@babel/runtime/helpers/get"));

var _inherits2 = _interopRequireDefault(require("@babel/runtime/helpers/inherits"));

var _objectSpread2 = _interopRequireDefault(require("@babel/runtime/helpers/objectSpread"));

var _console = require("@instructure/console");

var _propTypes = _interopRequireDefault(require("prop-types"));

var _uiDecorator = _interopRequireDefault(require("@instructure/ui-decorator"));

var _shallowEqual = _interopRequireDefault(require("@instructure/ui-utils/lib/shallowEqual"));

var _isEmpty = _interopRequireDefault(require("@instructure/ui-utils/lib/isEmpty"));

var _uid = _interopRequireDefault(require("@instructure/uid"));

var _deepEqual = _interopRequireDefault(require("@instructure/ui-utils/lib/deepEqual"));

var _findDOMNode = _interopRequireDefault(require("@instructure/ui-utils/lib/dom/findDOMNode"));

var _ThemeContextTypes = require("@instructure/ui-themeable/lib/ThemeContextTypes");

var _applyVariablesToNode = _interopRequireDefault(require("@instructure/ui-themeable/lib/utils/applyVariablesToNode"));

var _getCssText = _interopRequireDefault(require("@instructure/ui-themeable/lib/utils/getCssText"));

var _setTextDirection = _interopRequireDefault(require("@instructure/ui-themeable/lib/utils/setTextDirection"));

var _registry = require("@instructure/ui-themeable/lib/registry");

var _StyleSheet = _interopRequireDefault(require("@instructure/ui-themeable/lib/StyleSheet"));

var _transformCss = require("@instructure/ui-themeable/lib/utils/transformCss");

/*
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

/**
* ---
* category: utilities/themes
* ---
* A decorator or higher order component that makes a component `themeable`.
*
* As a HOC:
*
* ```js
* import themeable from '@instructure/ui-themeable'
* import styles from 'styles.css'
* import theme from 'theme.js'
*
* class Example extends React.Component {
*   render () {
*     return <div className={styles.root}>Hello</div>
*   }
* }
*
* export default themeable(theme, styles)(Example)
* ```
*
* Note: in the above example, the CSS file must be transformed into a JS object
* via [babel](#babel-plugin-themeable-styles) or [webpack](#ui-webpack-config) loader.
*
* Themeable components inject their themed styles into the document when they are mounted.
*
* After the initial mount, a themeable component's theme can be configured explicitly
* via its `theme` prop or passed via React context using the [ApplyTheme](#ApplyTheme) component.
*
* Themeable components register themselves with the [global theme registry](#registry)
* when they are imported into the application, so you will need to be sure to import them
* before you mount your application so that the default themed styles can be generated and injected.
*
* @param {function} theme - A function that generates the component theme variables.
* @param {object} styles - The component styles object.
* @return {function} composes the themeable component.
*/
var emptyObj = {};
var themeable = (0, _uiDecorator.default)(function (ComposedComponent, theme) {
  var styles = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : {};
  var displayName = ComposedComponent.displayName || ComposedComponent.name;
  var componentId = "".concat(styles && styles.componentId || (0, _uid.default)());

  if (process.env.NODE_ENV !== 'production') {
    componentId = "".concat(displayName, "__").concat(componentId);
  }

  var contextKey = Symbol(componentId);
  var template = styles && typeof styles.template === 'function' ? styles.template : function () {
    /*#__PURE__*/
    (
    /*#__PURE__*/
    0, _console.warn)(false, '[themeable] Invalid styles for: %O. Use @instructure/babel-plugin-themeable-styles to transform CSS imports.', displayName);
    return '';
  };
  (0, _registry.registerComponentTheme)(contextKey, theme);

  var getContext = function getContext(context) {
    var themeContext = (0, _ThemeContextTypes.getThemeContext)(context);
    return themeContext || emptyObj;
  };

  var getThemeFromContext = function getThemeFromContext(context) {
    var _getContext = getContext(context),
        theme = _getContext.theme;

    if (theme && theme[contextKey]) {
      return (0, _objectSpread2.default)({}, theme[contextKey]);
    } else {
      return emptyObj;
    }
  };

  var generateThemeForContextKey = function generateThemeForContextKey(themeKey, overrides) {
    return (0, _registry.generateComponentTheme)(contextKey, themeKey, overrides);
  };

  var ThemeableComponent =
  /*#__PURE__*/
  function (_ComposedComponent) {
    (0, _inherits2.default)(ThemeableComponent, _ComposedComponent);

    function ThemeableComponent() {
      var _getPrototypeOf2;

      var _this;

      (0, _classCallCheck2.default)(this, ThemeableComponent);

      for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }

      _this = (0, _possibleConstructorReturn2.default)(this, (_getPrototypeOf2 = (0, _getPrototypeOf3.default)(ThemeableComponent)).call.apply(_getPrototypeOf2, [this].concat(args)));
      _this._themeCache = null;
      _this._instanceId = (0, _uid.default)(displayName);
      return _this;
    }

    (0, _createClass2.default)(ThemeableComponent, [{
      key: "componentWillMount",
      value: function componentWillMount() {
        if (!_StyleSheet.default.mounted(componentId)) {
          var defaultTheme = generateThemeForContextKey();
          var cssText = (0, _getCssText.default)(template, defaultTheme, componentId);

          _StyleSheet.default.mount(componentId, (0, _transformCss.toRules)(cssText));
        }

        if ((0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "componentWillMount", this)) {
          (0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "componentWillMount", this).call(this);
        }
      }
    }, {
      key: "componentDidMount",
      value: function componentDidMount() {
        this.applyTheme();
        (0, _setTextDirection.default)();

        if ((0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "componentDidMount", this)) {
          (0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "componentDidMount", this).call(this);
        }
      }
    }, {
      key: "shouldComponentUpdate",
      value: function shouldComponentUpdate(nextProps, nextState, nextContext) {
        var themeContextWillChange = !(0, _deepEqual.default)((0, _ThemeContextTypes.getThemeContext)(this.context), (0, _ThemeContextTypes.getThemeContext)(nextContext));
        if (themeContextWillChange) return true;

        if ((0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "shouldComponentUpdate", this)) {
          return (0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "shouldComponentUpdate", this).call(this, nextProps, nextState, nextContext);
        }

        return !(0, _shallowEqual.default)(this.props, nextProps) || !(0, _shallowEqual.default)(this.state, nextState) || !(0, _shallowEqual.default)(this.context, nextContext);
      }
    }, {
      key: "componentWillUpdate",
      value: function componentWillUpdate(nextProps, nextState, nextContext) {
        if (!(0, _deepEqual.default)(nextProps.theme, this.props.theme) || !(0, _deepEqual.default)(getThemeFromContext(nextContext), getThemeFromContext(this.context))) {
          this._themeCache = null;
        }

        if ((0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "componentWillUpdate", this)) {
          (0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "componentWillUpdate", this).call(this, nextProps, nextState, nextContext);
        }
      }
    }, {
      key: "componentDidUpdate",
      value: function componentDidUpdate(prevProps, prevState, prevContext) {
        this.applyTheme();

        if ((0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "componentDidUpdate", this)) {
          (0, _get2.default)((0, _getPrototypeOf3.default)(ThemeableComponent.prototype), "componentDidUpdate", this).call(this, prevProps, prevState, prevContext);
        }
      }
    }, {
      key: "applyTheme",
      value: function applyTheme(DOMNode) {
        if ((0, _isEmpty.default)(this.theme)) {
          return;
        }

        var defaultTheme = generateThemeForContextKey();
        (0, _applyVariablesToNode.default)(DOMNode || (0, _findDOMNode.default)(this), // eslint-disable-line react/no-find-dom-node
        this.theme, defaultTheme, componentId, template, // for IE 11
        this.scope // for IE 11
        );
      }
    }, {
      key: "scope",
      get: function get() {
        return "".concat(componentId, "__").concat(this._instanceId);
      }
    }, {
      key: "theme",
      get: function get() {
        if (this._themeCache !== null) {
          return this._themeCache;
        }

        var _getContext2 = getContext(this.context),
            immutable = _getContext2.immutable;

        var theme = getThemeFromContext(this.context);

        if (this.props.theme && !(0, _isEmpty.default)(this.props.theme)) {
          if (!theme) {
            theme = this.props.theme;
          } else if (immutable) {
            /*#__PURE__*/
            (
            /*#__PURE__*/
            0, _console.warn)(false, '[themeable] Parent theme is immutable. Cannot apply theme: %O', this.props.theme);
          } else {
            theme = (0, _isEmpty.default)(theme) ? this.props.theme : (0, _objectSpread2.default)({}, theme, this.props.theme);
          }
        } // pass in the component theme as overrides


        this._themeCache = generateThemeForContextKey(null, theme);
        return this._themeCache;
      }
    }]);
    return ThemeableComponent;
  }(require('newless')(ComposedComponent));

  ThemeableComponent.componentId = componentId;
  ThemeableComponent.theme = contextKey;
  ThemeableComponent.contextTypes = (0, _objectSpread2.default)({}, ComposedComponent.contextTypes, _ThemeContextTypes.ThemeContextTypes);
  ThemeableComponent.propTypes = (0, _objectSpread2.default)({}, ComposedComponent.propTypes, {
    theme: _propTypes.default.object // eslint-disable-line react/forbid-prop-types

  });
  ThemeableComponent.generateTheme = generateThemeForContextKey;
  return ThemeableComponent;
});
/**
* Utility to generate a theme for all themeable components that have been registered.
* This theme can be applied using the [ApplyTheme](#ApplyTheme) component.
*
* @param {String} themeKey The theme to use (for global theme variables across components)
* @param {Object} overrides theme variable overrides (usually for dynamic/user defined values)
* @return {Object} A theme config to use with `<ApplyTheme />`
*/

themeable.generateTheme = _registry.generateTheme;
var _default = themeable;
exports.default = _default;
