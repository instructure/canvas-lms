/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import classNames from 'classnames'
import PropTypes from 'prop-types'
import React, {useLayoutEffect, useRef, useContext} from 'react'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import theme from '@instructure/canvas-theme'

export function Highlight({...props}) {
  const highlightRef = useRef()
  const urlParams = new URLSearchParams(window.location.search)
  const isPersistEnabled = urlParams.get('persist') === '1'
  const className = isPersistEnabled ? 'highlight-discussion' : 'highlight-fadeout'
  const {focusSelector, setFocusSelector} = useContext(DiscussionManagerUtilityContext)

  const triggerFocus = element => {
    let eventType = "onfocusin" in element ? "focusin" : "focus";
    let bubbles = "onfocusin" in element;
    let event;

    if ("createEvent" in document) {
        event = document.createEvent("Event");
        event.initEvent(eventType, bubbles, true);
    }
    else if ("Event" in window) {
        event = new Event(eventType, { bubbles: bubbles, cancelable: true });
    }

    element.focus();
    element.dispatchEvent(event);
  }

  useLayoutEffect(() => {
    if (props.isHighlighted && highlightRef.current) {
      setTimeout(() => {
        highlightRef.current?.scrollIntoView({behavior: 'smooth', block: 'center'})
        if (focusSelector) {
          const speedGraderDiv = highlightRef.current?.querySelector('#speedgrader-navigator')
          triggerFocus(speedGraderDiv)
          highlightRef.current?.querySelector(focusSelector).focus({preventScroll: true})
          setFocusSelector('')
        } else {
          highlightRef.current?.querySelector('button').focus({preventScroll: true})
        }
      }, 0)
    }
  }, [props.isHighlighted, highlightRef])

  return (
    <div
      style={{
        borderRadius: theme.variables.borders.radiusLarge,
      }}
      className={classNames({[className]: props.isHighlighted})}
      data-testid={props.isHighlighted ? 'isHighlighted' : 'notHighlighted'}
      ref={highlightRef}
    >
      {props.children}
    </div>
  )
}

Highlight.propTypes = {
  /**
   * Boolean to define if the Highlight is highlighted.
   */
  isHighlighted: PropTypes.bool,
  children: PropTypes.node,
}

Highlight.defaultProps = {
  isHighlighted: false,
}

export default Highlight
