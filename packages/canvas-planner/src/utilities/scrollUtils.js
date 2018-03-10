/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import Velocity from 'velocity-animate';

export function animateSlideDown (elt) {
  Velocity(elt, 'slideDown');
}

function handleScrollUpAttempt (cb, e) {
  e.preventDefault();
  cb();
}

function handleWindowWheel (cb, wind, e) {
  if (wind.pageYOffset === 0 && e.deltaY < 0) {
    handleScrollUpAttempt(cb, e);
  }
}

function handleWindowScrollKey (cb, wind, e) {
  if (wind.pageYOffset === 0 &&
      (e.key === 'PageUp' || e.key === 'ArrowUp' || e.key === 'Up')) {
    handleScrollUpAttempt(cb, e);
  }
}

// User drags a finger down the screen to scroll up.
// When she gets to the top, and keeps on pulling down, call the callback
let ongoingTouch = null;
function handleTouchStart (e) {
  if (ongoingTouch === null) {
    ongoingTouch = e.changedTouches[0];
  }
}
function handleWindowTouchMove (cb, wind, e) {
  if (wind.pageYOffset === 0 && ongoingTouch) {
    const thisTouch = e.changedTouches[ongoingTouch.identifier];
    if (thisTouch) {
      if (thisTouch.screenY - ongoingTouch.screenY > 3) {
        cb();
      }
    }
  }
}
function handleTouchEnd (e) {
  ongoingTouch = null;
}

export function registerScrollEvents (scrollIntoPastCb, wind = window) {
  const boundWindowWheel = handleWindowWheel.bind(undefined, scrollIntoPastCb, wind);
  wind.addEventListener('wheel', boundWindowWheel);

  const boundScrollKey = handleWindowScrollKey.bind(undefined, scrollIntoPastCb, wind);
  wind.addEventListener('keydown', boundScrollKey);

  wind.addEventListener('touchstart', handleTouchStart);
  wind.addEventListener('touchend', handleTouchEnd);
  const boundTouchMove = handleWindowTouchMove.bind(undefined, scrollIntoPastCb, wind);
  wind.addEventListener('touchmove', boundTouchMove);
}
