/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

/**
 * Preface: This is a horrible terrible function and should only be used
 *          in the most dire circumstances.  In fact, it probably shouldn't
 *          exist at all.
 *
 * This function will cause a given DOM node to be completely thrown away and
 * re-rendered.  This is helpful to screenreaders because JavaScripty stuff
 * doesn't work so well.  They generally read the page once and call it good.
 *
 *
 * *******PLEASE REMOVE THIS FUNCTION WHENEVER IT CAN BE DONE*******
 */
const forceScreenreaderToReparse = node => {
  // Save the scroll position since the thrash will cause the browser to scroll
  // to the top.
  const YscrollPosition = window.scrollY
  const XscrollPosition = window.scrollX

  // Thrash the DOM for the node we've been given.
  if (!node.style) {
    node.setAttribute('style', ' ')
  }
  const oldDisplay = node.style.display || ''
  node.style.display = 'none'
  // We just access this property to force recalculation of data and a redraw
  // eslint-disable-next-line babel/no-unused-expressions
  node.offsetHeight
  node.style.display = oldDisplay

  // Force the browser to scroll back to the original position.
  window.scroll(XscrollPosition, YscrollPosition)
}

export default forceScreenreaderToReparse
