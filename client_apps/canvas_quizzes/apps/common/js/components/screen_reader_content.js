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

  /**
   * @class Components.ScreenReaderContent
   * @alternateClassName ScreenReaderContent
   *
   * A component that is only "visible" to screen-reader ATs. Sighted users
   * will not see nor be able to interact with instances of this component.
   *
   * See Components.SightedUserContent for the "counterpart" of this component,
   * although with less reliability.
   *
   */
  var ScreenReaderContent = React.createClass({
    propTypes: {
      /**
       * @property {Boolean} [forceSentenceDelimiter=false]
       *
       * If you're passing in dynamic content and you're noticing that it's not
       * being read as a full sentence (e.g, some SRs are reading it along with
       * the next element), then you can try setting this property to true and
       * it will work a trick to make the SR pause after reading this element,
       * just as if it were a proper sentence.
       */
      forceSentenceDelimiter: React.PropTypes.bool
    },

    getDefaultProps: function() {
      return {
        tagName: 'span',
        forceSentenceDelimiter: false
      }
    },

    render: function() {
      var tag = React.DOM[this.props.tagName]
      var tagProps = {}
      var customChildren = []

      tagProps.className = 'screenreader-only'

      if (this.props.forceSentenceDelimiter) {
        customChildren.push(this.generateSentenceDelimiter())
      }

      if (customChildren.length) {
        // React disallows setting the @dangerouslySetInnerHTML prop and passing
        // children at the same time. So if the caller is attempting to pass
        // this prop and is also asking for enhancements that require custom
        // children such as @forceSentenceDelimiter then we cannot accomodate
        // the request and should notify them.
        //
        // The same effect could be achieved by setting that prop on a *child*
        // passed to the SRC component, e.g:
        //
        //     <ScreenReaderContent forceSentenceDelimiter>
        //       <span dangerouslySetInnerHTML={{__html: '<b>hi</b>'}} />
        //     </ScreenReaderContent>
        //
        //     // instead of:
        //
        //     <ScreenReaderContent
        //       forceSentenceDelimiter
        //       dangerouslySetInnerHTML={{__html: '<b>hi</b>'}} />
        if (this.props.dangerouslySetInnerHTML) {
          console.error(
            'You are attempting to set the dangerouslySetInnerHTML prop',
            'on a ScreenReaderContent component, which prevents it from enabling',
            'further accessibility enhancements.',

            'Try setting that property on a passed child instead.'
          )
        } else {
          tagProps.children = [this.props.children, customChildren]
        }
      } else {
        // no custom children, pass children as-is:
        tagProps.children = this.props.children
      }

      return this.transferPropsTo(tag(tagProps, tagProps.children))
    },

    generateSentenceDelimiter: function() {
      return <em role="presentation" aria-role="presentation" aria-hidden children=". " />
    }
  })

  return ScreenReaderContent
})
