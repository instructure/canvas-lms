/** @jsx React.DOM */
/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps')
  var _ = require('lodash')
  var interpolate = require('../util/i18n_interpolate')
  var convertCase = require('../util/convert_case')

  var omit = _.omit
  var underscore = convertCase.underscore

  var InterpolatedText = React.createClass({
    render: function() {
      var container, markup, tagAttrs, options
      if (!this.props.children) {
        return <div />
      }

      tagAttrs = {}
      container = <div>{this.props.children}</div>
      markup = React.renderComponentToStaticMarkup(container)
      options = omit(this.props, 'children')

      tagAttrs.dangerouslySetInnerHTML = {
        __html: interpolate(markup, underscore(options || {}))
      }

      return React.DOM.div(tagAttrs)
    }
  })

  var Text = React.createClass({
    getInitialState: function() {
      return {
        markup: undefined
      }
    },

    getDefaultProps: function() {
      return {
        phrase: null
      }
    },

    //>>excludeStart("production", pragmas.production);
    componentWillReceiveProps: function(nextProps) {
      var markup

      if (nextProps.phrase) {
        markup = React.renderComponentToStaticMarkup(InterpolatedText(nextProps))
        markup = markup.replace(/<\/?div>/g, '')

        this.setState({
          markup: markup
        })
      }
    },
    //>>excludeEnd("production");

    render: function() {
      return <div aria-role="article" dangerouslySetInnerHTML={{__html: this.state.markup}} />
    }
  })

  return Text
})
