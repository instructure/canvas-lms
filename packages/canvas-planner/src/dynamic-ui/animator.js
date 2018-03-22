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

export class Animator {
  constructor (opts = {}) {
    Object.assign(this, {
        velocity: Velocity,
        document: document,
        window: window,
      },
      opts
    );
  }
  animationQueue = [];
  fixedElement = null;
  fixedElementsInitialPositionInViewport = null;

  focusElement (elt) {
    // focusing an element causes it to scroll into view, so do the focus first so it doesn't
    // override maintaining the viewport position.
    if (!elt) console.error(`${elt} passed to Animator#focusElement`);
    else this.queueAnimation(() => elt.focus(), 'unshift');
  }

  recordFixedElement (elt) {
    if (elt) {
      this.fixedElement = elt;
      this.fixedElementsInitialPositionInViewport = elt.getBoundingClientRect().top;
    }
  }

  // Based on this formula:
  // element's position in the viewport + the window's scroll position === the element's position in the document
  // so if we want the scroll position that will maintain the element in it's current viewport position,
  // window scroll position = element's current document position - element's initial viewport position
  maintainViewportPosition () {
    if (this.fixedElement == null) return;
    this.queueAnimation(() => {
      const fixedElementsNewPositionInViewport = this.fixedElement.getBoundingClientRect().top;
      const documentPositionInViewport = this.document.documentElement.getBoundingClientRect().top;
      const fixedElementsPositionInDocument = fixedElementsNewPositionInViewport - documentPositionInViewport;
      const newWindowScrollPosition = fixedElementsPositionInDocument - this.fixedElementsInitialPositionInViewport;
      this.window.scroll(0, newWindowScrollPosition);
    }, 'push');
  }

  scrollTo (elt, offset) {
    this.queueAnimation(() => {
      const viewportHeight = this.window.innerHeight;
      const rect = elt.getBoundingClientRect();
      if (rect.top < offset || rect.bottom > viewportHeight) {
        this.velocity(elt, 'scroll', {offset: -offset, duration: 1000, easing: 'ease-in-out'});
      }
    });
  }

  scrollToTop () {
    this.scrollTo(document.documentElement, 0);
  }

  queueAnimation (fn, pushType='push', ) {
    this.animationQueue[pushType](fn);
    this.window.requestAnimationFrame(this.runAnimationQueue);
  }

  isAboveScreen (elt, offset) {
    return elt.getBoundingClientRect().top < offset;
  }

  runAnimationQueue = () => {
    while (this.animationQueue.length) {
      const animationFn = this.animationQueue.shift();
      animationFn();
    }
  }
}
