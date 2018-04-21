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

import $ from 'jquery'
import { findKey } from 'lodash'

const KeyCodes = {
  ENTER: 13,
  ESC: 27,
  SPACE: 32,
  LEFT: 37,
  UP: 38,
  RIGHT: 39,
  DOWN: 40,
  PAGE_UP: 33,
  PAGE_DOWN: 34,
  M: 77,
  F: 70,
  // Google TV
  G_REWIND: 227,
  G_FORWARD: 228,
};

const controlSelectors = {
  captions: '.mejs-captions-button',
  fullscreen: '.mejs-fullscreen-button',
  playpause: '.mejs-playpause-button',
  progress: '.mejs-time-rail',
  source: '.mejs-sourcechooser-button',
  speed: '.mejs-speed-button',
  volume: '.mejs-volume-button'
};

// helper to find the index of the first checked option
function focusPosition (optionElements, checkedFunction) {
  const checkedOption = optionElements.filter(checkedFunction).first();
  const focusPos = optionElements.index(checkedOption);
  return focusPos < 0 ? 0 : focusPos;
}

function MediaElementKeyActionHandler (mejs, player, media, event) {
  this.player = player;
  this.media = media;
  this.event = event;
  this.keyCode = event.keyCode;
  this.isFullScreen = (mejs.MediaFeatures.hasTrueNativeFullScreen && mejs.MediaFeatures.isFullScreen()) || player.isFullScreen;
  this.isFirefox = mejs.MediaFeatures.isFirefox;
}

MediaElementKeyActionHandler.keyCodes = KeyCodes;

MediaElementKeyActionHandler.prototype._targetControl = function (selector) {
  return $(this.event.target).closest(selector);
};

MediaElementKeyActionHandler.prototype.handlerKey = function () {
  const self = this;

  // Check whether one of the controls was the event target
  const target = findKey(controlSelectors, selector => self._targetControl(selector).length);

  // If none of the controls were the target, then let the player handle it
  return target || 'player';
};

MediaElementKeyActionHandler.prototype.dispatch = function () {
  this.event.preventDefault();
  const handler = `${this.handlerKey()}Handler`;
  this[handler]();
};

MediaElementKeyActionHandler.prototype.captionsHandler = function () {
  let newFocusPosition;
  const { player, event } = this;
  const srcOptions = $(player.captionsButton).find('.mejs-captions-selector input[type=radio]');
  const currentlyFocused = focusPosition(srcOptions, (i, el) => (el.value === 'none' && player.selectedTrack == null) ||
      (player.selectedTrack && el.value === player.selectedTrack.srclang));

  switch (this.keyCode) {
    case KeyCodes.DOWN:
      newFocusPosition = Math.min(currentlyFocused + 1, srcOptions.length - 1);
      srcOptions.slice(newFocusPosition).first().focus().click();
      break;

    case KeyCodes.UP:
      newFocusPosition = Math.max(currentlyFocused - 1, 0);
      srcOptions.slice(newFocusPosition).first().focus().click();
      break;

    case KeyCodes.ENTER:
      if (event.target.tagName.toLowerCase() === 'a') {
        $(event.target)[0].click();
      }
      break;

    default:

  }
};

MediaElementKeyActionHandler.prototype.fullscreenHandler = function () {
  const { player, event } = this;

  switch (this.keyCode) {
    case KeyCodes.SPACE:
      // SPACE sends the click event in firefox, which is already bound to in the plugin.
      if (this.isFirefox) {
        break;
      }
      /* falls through */
    case KeyCodes.ENTER:
      // IE seems to treat the request for fullscreen differently based on the
      // event type. So instead of calling the function as a keypress handler,
      // we simulate a click.
      $(event.target)[0].click();
      break;

    case KeyCodes.ESC:
      if (this.isFullScreen) {
        player.exitFullScreen();
      }
      break;

    default:

  }
};

MediaElementKeyActionHandler.prototype.playpauseHandler = function () {
  const { player, media } = this;
  let newTime;

  switch (this.keyCode) {
    case KeyCodes.LEFT:
    case KeyCodes.DOWN:
    case KeyCodes.G_REWIND:
      newTime = Math.max(media.currentTime - player.options.defaultSeekBackwardInterval(media), 0);
      media.setCurrentTime(newTime);
      break;

    case KeyCodes.RIGHT:
    case KeyCodes.UP:
    case KeyCodes.G_FORWARD:
      newTime = Math.min(media.currentTime + player.options.defaultSeekForwardInterval(media), media.duration);
      media.setCurrentTime(newTime);
      break;

    case KeyCodes.PAGE_DOWN:
      newTime = Math.max(media.currentTime - player.options.defaultJumpBackwardInterval(media), 0);
      media.setCurrentTime(newTime);
      break;

    case KeyCodes.PAGE_UP:
      newTime = Math.min(media.currentTime + player.options.defaultJumpForwardInterval(media), media.duration);
      media.setCurrentTime(newTime);
      break;

    case KeyCodes.SPACE:
      // SPACE sends the click event in firefox, which is already bound to in the plugin.
      if (this.isFirefox) {
        break;
      }
      /* falls through */
    case KeyCodes.ENTER:
      if (media.paused) {
        media.play();
      } else {
        media.pause();
      }
      break;

    default:

  }
};

MediaElementKeyActionHandler.prototype.progressHandler = function () {};

MediaElementKeyActionHandler.prototype.sourceHandler = function () {
  let newFocusPosition;
  const { player } = this;
  const srcOptions = $(player.sourcechooserButton).find('.mejs-sourcechooser-selector input[type=radio]');
  const currentlyFocused = focusPosition(srcOptions, (i, el) => el.value === player.media.src);

  switch (this.keyCode) {
    case KeyCodes.DOWN:
      newFocusPosition = Math.min(currentlyFocused + 1, srcOptions.length - 1);
      srcOptions.slice(newFocusPosition).first().focus().click();
      break;

    case KeyCodes.UP:
      newFocusPosition = Math.max(currentlyFocused - 1, 0);
      srcOptions.slice(newFocusPosition).first().focus().click();
      break;

    default:

  }
};

MediaElementKeyActionHandler.prototype.speedHandler = function () {
  let newFocusPosition;
  const { player } = this;
  const srcOptions = $(player.speedButton).find('.mejs-speed-selector input[type=radio]');
  const currentlyFocused = focusPosition(srcOptions, (i, el) => parseFloat(el.value) === player.media.playbackRate);

  switch (this.keyCode) {
    case KeyCodes.DOWN:
      newFocusPosition = Math.min(currentlyFocused + 1, srcOptions.length - 1);
      srcOptions.slice(newFocusPosition).first().focus().click();
      break;

    case KeyCodes.UP:
      newFocusPosition = Math.max(currentlyFocused - 1, 0);
      srcOptions.slice(newFocusPosition).first().focus().click();
      break;

    default:

  }
};

MediaElementKeyActionHandler.prototype.volumeHandler = function () {
  const { player, media } = this;
  let volume;

  switch (this.keyCode) {
    case KeyCodes.SPACE:
      // SPACE sends the click event in firefox, which is already bound to in the plugin.
      if (this.isFirefox) {
        break;
      }
      /* falls through */
    case KeyCodes.ENTER:
      player.setMuted(!player.media.muted);
      break;

    case KeyCodes.LEFT: // DOWN is handled by the plugin
      volume = Math.max(0, media.volume - 0.1);
      media.setVolume(volume);
      break;

    case KeyCodes.RIGHT: // UP is handled by the plugin
      volume = Math.min(media.volume + 0.1, 1);
      media.setVolume(volume);
      break;

    case KeyCodes.PAGE_DOWN:
      volume = Math.max(0, media.volume - 0.5);
      media.setVolume(volume);
      break;

    case KeyCodes.PAGE_UP:
      volume = Math.min(media.volume + 0.5, 1);
      media.setVolume(volume);
      break;

    default:

  }
};

MediaElementKeyActionHandler.prototype.playerHandler = function () {
  const { player, media, event } = this;
  let newTime;
  let volume;

  switch (this.keyCode) {
    case KeyCodes.LEFT:
    case KeyCodes.G_REWIND:
      newTime = Math.max(media.currentTime - player.options.defaultSeekBackwardInterval(media), 0);
      media.setCurrentTime(newTime);
      break;

    case KeyCodes.RIGHT:
    case KeyCodes.G_FORWARD:
      newTime = Math.min(media.currentTime + player.options.defaultSeekForwardInterval(media), media.duration);
      media.setCurrentTime(newTime);
      break;

    case KeyCodes.PAGE_DOWN:
      newTime = Math.max(media.currentTime - player.options.defaultJumpBackwardInterval(media), 0);
      media.setCurrentTime(newTime);
      break;

    case KeyCodes.PAGE_UP:
      newTime = Math.min(media.currentTime + player.options.defaultJumpForwardInterval(media), media.duration);
      media.setCurrentTime(newTime);
      break;

    case KeyCodes.F:
      // IE seems to treat the request for fullscreen differently based on the
      // event type. So instead of calling the function as a keypress handler,
      // we simulate a click on the fullscreen button.
      $(event.target).find('.mejs-fullscreen-button > button')[0].click();
      break;

    case KeyCodes.UP:
      volume = media.volume;
      media.setVolume(Math.min(volume + 0.1, 1));
      break;

    case KeyCodes.DOWN:
      volume = media.volume;
      media.setVolume(Math.max(0, volume - 0.1));
      break;

    case KeyCodes.M:
      player.setMuted(!player.media.muted);
      break;

    case KeyCodes.SPACE:
      // SPACE sends the click event in firefox, which is already bound to in the plugin.
      if (this.isFirefox) {
        break;
      }
      /* falls through */
    case KeyCodes.ENTER:
      if (media.paused) {
        media.play();
      } else {
        media.pause();
      }
      break;

    default:

  }
};

export default MediaElementKeyActionHandler
