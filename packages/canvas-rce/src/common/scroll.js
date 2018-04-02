/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import scrollIntoView from "scroll-into-view";

export default {
  // scrolling in react is kinda messed up. it would
  // make sense to scroll after getting "componentDidUpdate'
  // after exposing new DOM objects, but "componentDidUpdate"
  // get's called after the virtual DOM flushes it's updates
  // to the real DOM. it doesn't get called after the real
  // DOM has actually updated the page, so getting accurate
  // scroll and window size information in "componenetDidUpdate"
  // is not reliable, so we need a delay.
  // there also is no uniform event in javascript yet that will
  // notify of scoll window changes. firefox has "overflow",
  // chrome has "overflowchanged", and ie has nothing.
  // so i need to introduce a delay to give the DOM time to render.
  // the underlying scrollIntoView module will also perform a
  // requestAnimationFrame() (through module raf), but that delay
  // wasn't enough for what we needed here.
  // see the below stackoverflow for more info
  // http://stackoverflow.com/questions/26556436/react-after-render-code
  INTERIM_DELAY: 100,
  scrollIntoViewWDelay(target, config) {
    setTimeout(() => {
      scrollIntoView.scrollIntoView(target, config);
    }, this.INTERIM_DELAY);
  }
};
