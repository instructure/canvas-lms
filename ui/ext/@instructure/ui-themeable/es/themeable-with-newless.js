// This file is copy/pasted from https://unpkg.com/@instructure/ui-themeable@6.10.0/es/themeable.js but with 'newless' added and the relative imports changed to absolute package paths

import _classCallCheck from '@babel/runtime/helpers/esm/classCallCheck'
import _createClass from '@babel/runtime/helpers/esm/createClass'
import _possibleConstructorReturn from '@babel/runtime/helpers/esm/possibleConstructorReturn'
import _getPrototypeOf from '@babel/runtime/helpers/esm/getPrototypeOf'
import _get from '@babel/runtime/helpers/esm/get'
import _inherits from '@babel/runtime/helpers/esm/inherits'
import {warn as _warn} from '@instructure/console'

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
import React from 'react'
import PropTypes from 'prop-types'
import {decorator} from '@instructure/ui-decorator'
import {isEmpty, shallowEqual, deepEqual} from '@instructure/ui-utils'
import {uid} from '@instructure/uid'
import {findDOMNode} from '@instructure/ui-dom-utils'
import {ThemeContext} from '@instructure/ui-themeable/es/ThemeContext'
import {applyVariablesToNode, setTextDirection} from '@instructure/ui-themeable'
import {
  generateComponentTheme,
  generateTheme,
  registerComponentTheme,
  mountComponentStyles
} from '@instructure/ui-themeable/es/ThemeRegistry'

import newless from 'newless'

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

const emptyObj = {}
/*
 * Note: there are consumers (like canvas-lms and other edu org repos) that are
 * consuming this file directly from "/src" (as opposed to "/es" or "/lib" like normal)
 * because they need this file to not have the babel "class" transform ran against it
 * (aka they need it to use real es6 `class`es, since you can't extend real es6
 * class from es5 transpiled code)
 *
 * Which means that for the time being, we can't use any other es6/7/8 features in
 * here that aren't supported by "last 2 edge versions" since we can't rely on babel
 * to transpile them for those apps.
 *
 * So, that means don't use "static" class properties (like `static PropTypes = {...}`),
 * or object spread (like "{...foo, ..bar}")" in this file until instUI 7 is released.
 * Once we release instUI 7, the plan is to stop transpiling the "/es" dir for ie11
 * so once we do that, this caveat no longer applies.
 */

const themeable = decorator(function (ComposedComponent, theme) {
  const styles = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : {}
  const displayName = ComposedComponent.displayName || ComposedComponent.name
  let componentId = ''.concat((styles && styles.componentId) || uid())

  if (process.env.NODE_ENV !== 'production') {
    componentId = ''.concat(displayName, '__').concat(componentId)

    /* #__PURE__ */

    /* #__PURE__ */
    _warn(
      parseInt(React.version) >= 15,
      '[themeable] React 15 or higher is required. You are running React version '.concat(
        React.version,
        '.'
      )
    )
  }

  const contextKey = Symbol(componentId)
  const template =
    styles && typeof styles.template === 'function'
      ? styles.template
      : function () {
          /* #__PURE__ */

          /* #__PURE__ */
          _warn(
            false,
            '[themeable] Invalid styles for: %O. Use @instructure/babel-plugin-themeable-styles to transform CSS imports.',
            displayName
          )

          return ''
        }
  registerComponentTheme(contextKey, theme)

  const getContext = function getContext(context) {
    const themeContext = ThemeContext.getThemeContext(context)
    return themeContext || emptyObj
  }

  const getThemeFromContext = function getThemeFromContext(context) {
    const _getContext = getContext(context),
      theme = _getContext.theme

    if (theme && theme[contextKey]) {
      return {...theme[contextKey]}
    } else {
      return emptyObj
    }
  }

  const generateThemeForContextKey = function generateThemeForContextKey(themeKey, overrides) {
    return generateComponentTheme(contextKey, themeKey, overrides)
  }

  const ThemeableComponent =
    /* #__PURE__ */
    (function (_ComposedComponent) {
      _inherits(ThemeableComponent, _ComposedComponent)

      function ThemeableComponent() {
        let _this

        _classCallCheck(this, ThemeableComponent)

        const res = (_this = _possibleConstructorReturn(
          this,
          _getPrototypeOf(ThemeableComponent).apply(this, arguments)
        ))

        _this._themeCache = null
        _this._instanceId = uid(displayName)
        return _possibleConstructorReturn(_this, res)
      }

      _createClass(ThemeableComponent, [
        {
          key: 'componentWillMount',
          value: function componentWillMount() {
            const defaultTheme = generateThemeForContextKey()
            mountComponentStyles(template, defaultTheme, componentId)

            if (_get(_getPrototypeOf(ThemeableComponent.prototype), 'componentWillMount', this)) {
              _get(_getPrototypeOf(ThemeableComponent.prototype), 'componentWillMount', this).call(
                this
              )
            }
          }
        },
        {
          key: 'componentDidMount',
          value: function componentDidMount() {
            this.applyTheme()
            setTextDirection()

            if (_get(_getPrototypeOf(ThemeableComponent.prototype), 'componentDidMount', this)) {
              _get(_getPrototypeOf(ThemeableComponent.prototype), 'componentDidMount', this).call(
                this
              )
            }
          }
        },
        {
          key: 'shouldComponentUpdate',
          value: function shouldComponentUpdate(nextProps, nextState, nextContext) {
            const themeContextWillChange = !deepEqual(
              ThemeContext.getThemeContext(this.context),
              ThemeContext.getThemeContext(nextContext)
            )
            if (themeContextWillChange) return true

            if (
              _get(_getPrototypeOf(ThemeableComponent.prototype), 'shouldComponentUpdate', this)
            ) {
              return _get(
                _getPrototypeOf(ThemeableComponent.prototype),
                'shouldComponentUpdate',
                this
              ).call(this, nextProps, nextState, nextContext)
            }

            return (
              !shallowEqual(this.props, nextProps) ||
              !shallowEqual(this.state, nextState) ||
              !shallowEqual(this.context, nextContext)
            )
          }
        },
        {
          key: 'componentWillUpdate',
          value: function componentWillUpdate(nextProps, nextState, nextContext) {
            if (
              !deepEqual(nextProps.theme, this.props.theme) ||
              !deepEqual(getThemeFromContext(nextContext), getThemeFromContext(this.context))
            ) {
              this._themeCache = null
            }

            if (_get(_getPrototypeOf(ThemeableComponent.prototype), 'componentWillUpdate', this)) {
              _get(_getPrototypeOf(ThemeableComponent.prototype), 'componentWillUpdate', this).call(
                this,
                nextProps,
                nextState,
                nextContext
              )
            }
          }
        },
        {
          key: 'componentDidUpdate',
          value: function componentDidUpdate(prevProps, prevState, prevContext) {
            this.applyTheme()

            if (_get(_getPrototypeOf(ThemeableComponent.prototype), 'componentDidUpdate', this)) {
              _get(_getPrototypeOf(ThemeableComponent.prototype), 'componentDidUpdate', this).call(
                this,
                prevProps,
                prevState,
                prevContext
              )
            }
          }
        },
        {
          key: 'applyTheme',
          value: function applyTheme(DOMNode) {
            if (isEmpty(this.theme)) {
              return
            }

            const defaultTheme = generateThemeForContextKey()
            applyVariablesToNode(
              DOMNode || findDOMNode(this), // eslint-disable-line react/no-find-dom-node
              this.theme,
              defaultTheme,
              componentId,
              template, // for IE 11
              this.scope // for IE 11
            )
          }
        },
        {
          key: 'scope',
          get: function get() {
            return ''.concat(componentId, '__').concat(this._instanceId)
          }
        },
        {
          key: 'theme',
          get: function get() {
            if (this._themeCache !== null) {
              return this._themeCache
            }

            const _getContext2 = getContext(this.context),
              immutable = _getContext2.immutable

            let theme = getThemeFromContext(this.context)

            if (this.props.theme && !isEmpty(this.props.theme)) {
              if (!theme) {
                theme = this.props.theme
              } else if (immutable) {
                /* #__PURE__ */

                /* #__PURE__ */
                _warn(
                  false,
                  '[themeable] Parent theme is immutable. Cannot apply theme: %O',
                  this.props.theme
                )
              } else {
                theme = isEmpty(theme) ? this.props.theme : {...theme, ...this.props.theme}
              }
            } // pass in the component theme as overrides

            this._themeCache = generateThemeForContextKey(null, theme)
            return this._themeCache
          }
        }
      ])

      return ThemeableComponent
    })(newless(ComposedComponent))

  ThemeableComponent.componentId = componentId
  ThemeableComponent.theme = contextKey
  ThemeableComponent.contextTypes = {
    ...ComposedComponent.contextTypes,
    ...ThemeContext.types
  }
  ThemeableComponent.propTypes = {
    ...ComposedComponent.propTypes,
    theme: PropTypes.object // eslint-disable-line react/forbid-prop-types
  }
  ThemeableComponent.generateTheme = generateThemeForContextKey
  return ThemeableComponent
})
/**
 * Utility to generate a theme for all themeable components that have been registered.
 * This theme can be applied using the [ApplyTheme](#ApplyTheme) component.
 *
 * @param {String} themeKey The theme to use (for global theme variables across components)
 * @param {Object} overrides theme variable overrides (usually for dynamic/user defined values)
 * @return {Object} A theme config to use with `<ApplyTheme />`
 */

themeable.generateTheme = generateTheme
export default themeable
export {themeable}
