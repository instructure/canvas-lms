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

import React from 'react'
import cx from 'classnames'

/**
 * @class Components.SightedUserContent
 *
 * A component that *tries* to hide itself from screen-readers, absolutely
 * expecting that you're providing a more accessible version of the resource
 * using something like a ScreenReaderContent component.
 *
 * Be warned that this does not totally prevent all screen-readers from
 * seeing this content in all modes. For example, VoiceOver in OS X will
 * still see this element when running in the "Say-All" mode and read it
 * along with the accessible version you're providing.
 *
 * > **Warning**
 * >
 * > Use of this component is discouraged unless there's no alternative!!!
 * >
 * > The only one case that justifies its use is when design provides a
 * > totally inaccessible version of a resource, and you're trying to
 * > accommodate the design (for sighted users,) and provide a genuine layer
 * > of accessibility (for others.)
 */
const SightedUserContent = ({tagName: Tag = 'span', ...props}) => {
  return (
    <Tag
      {...props}
      // HTML5 [hidden] works in many screen-readers and in some cases, like
      // VoiceOver's Say-All mode, is the only thing that works for skipping
      // content. However, this clearly has the downside of hiding the
      // content from sighted users as well, so we resort to CSS to get the
      // items back into display and we win-win.
      hidden={true}
      aria-hidden={true}
      role="presentation"
      className={cx('sighted-user-content', props.className)}
    >
      {props.children}
    </Tag>
  )
}

export default SightedUserContent
