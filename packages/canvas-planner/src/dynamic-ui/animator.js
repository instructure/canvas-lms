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

  // Get the window registered with this animator. Mostly for testing.
  getWindow () {
    return this.window;
  }

  focusElement (elt) {
    // focusing an element causes it to scroll into view, so do the focus first so it doesn't
    // override maintaining the viewport position.
    if (!elt) console.error(`${elt} passed to Animator#focusElement`);
    else this.queueAnimation(() => {
      (typeof elt.focus === 'function') && elt.focus()
    }, 'unshift');
  }

  elementPositionMemo (elt) {
    return {
      element: elt,
      rect: elt.getBoundingClientRect(),
    };
  }

  // Based on this formula:
  // element's position in the viewport + the window's scroll position === the element's position in the document
  // so if we want the scroll position that will maintain the element in it's current viewport position,
  // window scroll position = element's current document position - element's initial viewport position
  maintainViewportPositionFromMemo (elt, memo) {
    this.queueAnimation(() => {
      const fixedElementsInitialPositionInViewport = memo.rect.top;
      const fixedElementsNewPositionInViewport = elt.getBoundingClientRect().top;
      const documentPositionInViewport = this.document.documentElement.getBoundingClientRect().top;
      const fixedElementsPositionInDocument = fixedElementsNewPositionInViewport - documentPositionInViewport;
      const newWindowScrollPosition = fixedElementsPositionInDocument - fixedElementsInitialPositionInViewport;
      this.window.scroll(0, newWindowScrollPosition);
    }, 'push');
  }

  // scroll the top of elt offset pixels from the top of the screen
  forceScrollTo (elt, offset, onComplete) {
    this.queueAnimation(() => {
       this.velocity(elt, 'scroll', {offset: -offset, duration: 1000, easing: 'ease-in-out', complete: onComplete});
    });
  }

  // scroll the top of elt offset pixels from the top of the screen, but only if it's not currently in view
  scrollTo (elt, offset, onComplete) {
    this.queueAnimation(() => {
      if (this.isOffScreen(elt, offset)) {
        this.velocity(elt, 'scroll', {offset: -offset, duration: 1000, easing: 'ease-in-out', complete: onComplete});
      } else {
        // even though we didn't need to run the animation, execute the onComplete callback
        onComplete && onComplete();
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

  isBelowScreen (elt) {
    // clientHeight is rounded to an integer, while the rect is a more precise
    // float. Add some padding so we err on the side of loading too much.
    // Also, Canvas's footer makes the document always at least as tall as
    // the viewport.
    const doc = this.window.document.documentElement;
    return elt.getBoundingClientRect().bottom + 2 > doc.clientHeight;
  }

  isOnScreen (elt, offset) {
    return !this.isOffScreen(elt, offset);
  }

  isOffScreen (elt, offset) {
     return this.isAboveScreen(elt, offset) || this.isBelowScreen(elt);
   }

  runAnimationQueue = () => {
    while (this.animationQueue.length) {
      const animationFn = this.animationQueue.shift();
      animationFn();
    }
  }
}
