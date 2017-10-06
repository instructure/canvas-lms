/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import $ from 'jquery';
import MediaElementKeyActionHandler from 'jsx/mediaelement/MediaElementKeyActionHandler'

let handler;
let fakeMejs;
let fakePlayer;
let fakeMedia;
let fakeEvent;
let $target;
let clickHandler;
const KeyCodes = MediaElementKeyActionHandler.keyCodes;
const seekInterval = 5;
const jumpInterval = 10;

function initializeFakes () {
  $target = $('<div class"control-element">');
  fakeMejs = {
    MediaFeatures: {
      hasTrueNativeFullScreen: false,
      isFirefox: false
    }
  }
  fakeEvent = {
    target: $target[0],
    keyCode: KeyCodes.ENTER,
    preventDefault: sinon.stub()
  };
  fakeMedia = {
    currentTime: 0,
    duration: 100,
    paused: true,
    pause: sinon.stub(),
    play: sinon.stub(),
    setCurrentTime: sinon.stub(),
    setVolume: sinon.stub(),
    volume: 0.5
  };
  fakePlayer = {
    exitFullScreen: sinon.stub(),
    isFullScreen: false,
    media: {
      muted: false
    },
    options: {
      defaultSeekBackwardInterval: sinon.stub(),
      defaultSeekForwardInterval: sinon.stub(),
      defaultJumpBackwardInterval: sinon.stub(),
      defaultJumpForwardInterval: sinon.stub()
    },
    setMuted: sinon.stub()
  };
  fakePlayer.options.defaultSeekBackwardInterval.returns(seekInterval);
  fakePlayer.options.defaultSeekForwardInterval.returns(seekInterval);
  fakePlayer.options.defaultJumpBackwardInterval.returns(jumpInterval);
  fakePlayer.options.defaultJumpForwardInterval.returns(jumpInterval);
}

QUnit.module('MediaElementKeyActionHandler events for specified controls', {
  setup () {
    initializeFakes();
    handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  }
});

test('handles captions', () => {
  ok(handler.captionsHandler);
});
test('handles fullscreen', () => {
  ok(handler.fullscreenHandler);
});
test('handles play/pause', () => {
  ok(handler.playpauseHandler);
});
test('handles progress', () => {
  ok(handler.progressHandler);
});
test('handles source', () => {
  ok(handler.sourceHandler);
});
test('handles speed', () => {
  ok(handler.speedHandler);
});
test('handles volume', () => {
  ok(handler.volumeHandler);
});

QUnit.module('MediaElementKeyActionHandler handlerKey', {
  setup () {
    initializeFakes();
    handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  }
});

test('returns the matching key based on where the event occurred', () => {
  const finder = sinon.stub(handler, '_targetControl');
  finder.withArgs('.mejs-captions-button').returns(['found']);

  equal(handler.handlerKey(), 'captions');
});

test('return the player key if no controls were the target', () => {
  sinon.stub(handler, '_targetControl').returns([]);

  equal(handler.handlerKey(), 'player');
});

QUnit.module('MediaElementKeyActionHandler dispatch', {
  setup () {
    initializeFakes();
    handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  }
});

test('prevents default event behavior', () => {
  handler.dispatch();
  ok(fakeEvent.preventDefault.called);
});

QUnit.module('MediaElementKeyActionHandler captionsHandler', {
  setup () {
    initializeFakes();
    handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  }
});

test('returns undefined', () => {
  strictEqual(handler.captionsHandler(), undefined);
});

QUnit.module('MediaElementKeyActionHandler fullscreenHandler', {
  setup () {
    initializeFakes();
    clickHandler = sinon.stub($target[0], 'click');
  }
});

test('when SPACE is pressed, it simulates a click event', () => {
  fakeEvent.keyCode = KeyCodes.SPACE;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.fullscreenHandler();
  equal(clickHandler.called, true);
});

test('when SPACE is pressed in firefox, it does nothing', () => {
  fakeEvent.keyCode = KeyCodes.SPACE;
  fakeMejs.MediaFeatures.isFirefox = true;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.fullscreenHandler();
  equal(clickHandler.called, false);
});

test('when ENTER is pressed it simulates a click event', () => {
  fakeEvent.keyCode = KeyCodes.ENTER;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.fullscreenHandler();
  equal(clickHandler.called, true);
});

test('when ESC key pressed when fullscreened it exits fullscreen', () => {
  fakeEvent.keyCode = KeyCodes.ESC;
  fakePlayer.isFullScreen = true;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.fullscreenHandler();
  ok(fakePlayer.exitFullScreen.called);
});

test('other key pressed it does nothing', () => {
  fakeEvent.keyCode = KeyCodes.UP;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  strictEqual(handler.fullscreenHandler(), undefined);
});

QUnit.module('MediaElementKeyActionHandler playpauseHandler', {
  setup () {
    initializeFakes();
  }
});

test('when left key pressed it rewinds', () => {
  fakeEvent.keyCode = KeyCodes.LEFT;
  const previousTime = fakeMedia.duration / 2;
  fakeMedia.currentTime = previousTime;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(previousTime - seekInterval));
});

test('when left key near the beginning it rewinds to the beginning', () => {
  fakeEvent.keyCode = KeyCodes.LEFT;
  fakeMedia.currentTime = 1;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(0));
});

test('when right key pressed it forwards', () => {
  fakeEvent.keyCode = KeyCodes.RIGHT;
  const previousTime = fakeMedia.currentTime
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(previousTime + seekInterval));
});

test('when right key near the end it forwards to the end', () => {
  fakeEvent.keyCode = KeyCodes.RIGHT;
  fakeMedia.currentTime = (fakeMedia.duration - seekInterval) + 1;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(fakeMedia.duration));
});

test('when page up key pressed it forwards', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_UP;
  const previousTime = fakeMedia.currentTime
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(previousTime + jumpInterval));
});

test('when page up key near the end it forwards to the end', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_UP;
  fakeMedia.currentTime = (fakeMedia.duration - jumpInterval) + 1;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(fakeMedia.duration));
});

test('when page down key pressed it rewinds', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_DOWN;
  const previousTime = fakeMedia.duration / 2;
  fakeMedia.currentTime = previousTime;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(previousTime - jumpInterval));
});

test('when page down key near the beginning it rewinds to the beginning', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_DOWN;
  fakeMedia.currentTime = 1;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(0));
});

test('when space pressed when paused it triggers play', () => {
  fakeEvent.keyCode = KeyCodes.SPACE;
  fakeMedia.paused = true;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.play.called);
});

test('when space pressed when playing it triggers pause', () => {
  fakeEvent.keyCode = KeyCodes.SPACE;
  fakeMedia.paused = false;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.pause.called);
});

test('when space pressed in firefox it does nothing', () => {
  fakeEvent.keyCode = KeyCodes.SPACE;
  fakeMejs.MediaFeatures.isFirefox = true;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  strictEqual(handler.playpauseHandler(), undefined);
});

test('when enter pressed when paused it triggers play', () => {
  fakeEvent.keyCode = KeyCodes.ENTER;
  fakeMedia.paused = true;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.play.called);
});

test('when enter pressed when playing it triggers pause', () => {
  fakeEvent.keyCode = KeyCodes.ENTER;
  fakeMedia.paused = false;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.pause.called);
});

test('when other key pressed does nothing', () => {
  fakeEvent.keyCode = KeyCodes.ESC;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  strictEqual(handler.playpauseHandler(), undefined);
});

QUnit.module('MediaElementKeyActionHandler volumeHandler', {
  setup () {
    initializeFakes();
  }
});

test('when space pressed it mutes', () => {
  fakeEvent.keyCode = KeyCodes.SPACE;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.volumeHandler();
  ok(fakePlayer.setMuted.calledWith(true));
});

test('when enter pressed it mutes', () => {
  fakeEvent.keyCode = KeyCodes.ENTER;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.volumeHandler();
  ok(fakePlayer.setMuted.calledWith(true));
});

test('when left key pressed it sets volume lower', () => {
  fakeEvent.keyCode = KeyCodes.LEFT;
  const previousVolume = fakeMedia.volume;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.volumeHandler();
  ok(fakeMedia.setVolume.calledWith(previousVolume - 0.1));
});

test('when right key pressed it sets volume higher', () => {
  fakeEvent.keyCode = KeyCodes.RIGHT;
  const previousVolume = fakeMedia.volume;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.volumeHandler();
  ok(fakeMedia.setVolume.calledWith(previousVolume + 0.1));
});

test('when page down key pressed it sets volume lower', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_DOWN;
  const previousVolume = fakeMedia.volume;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.volumeHandler();
  ok(fakeMedia.setVolume.calledWith(previousVolume - 0.5));
});

test('when page up key pressed it sets volume higher', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_UP;
  const previousVolume = fakeMedia.volume;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.volumeHandler();
  ok(fakeMedia.setVolume.calledWith(previousVolume + 0.5));
});

test('when other key pressed it does nothing', () => {
  fakeEvent.keyCode = KeyCodes.ESQ;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  strictEqual(handler.volumeHandler(), undefined);
});

QUnit.module('MediaElementKeyActionHandler playerHandler', {
  setup () {
    initializeFakes();
  }
});

test('when left key pressed it rewinds', () => {
  fakeEvent.keyCode = KeyCodes.LEFT;
  const previousTime = fakeMedia.duration / 2;
  fakeMedia.currentTime = previousTime;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok(fakeMedia.setCurrentTime.calledWith(previousTime - seekInterval));
});

test('when left key near the beginning it rewinds to the beginning', () => {
  fakeEvent.keyCode = KeyCodes.LEFT;
  fakeMedia.currentTime = 1;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok(fakeMedia.setCurrentTime.calledWith(0));
});

test('when right key pressed it forwards', () => {
  fakeEvent.keyCode = KeyCodes.RIGHT;
  const previousTime = fakeMedia.currentTime
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok(fakeMedia.setCurrentTime.calledWith(previousTime + seekInterval));
});

test('when right key near the end it forwards to the end', () => {
  fakeEvent.keyCode = KeyCodes.RIGHT;
  fakeMedia.currentTime = (fakeMedia.duration - seekInterval) + 1;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok(fakeMedia.setCurrentTime.calledWith(fakeMedia.duration));
});

test('when page up key pressed it forwards', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_UP;
  const previousTime = fakeMedia.currentTime
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(previousTime + jumpInterval));
});

test('when page up key near the end it forwards to the end', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_UP;
  fakeMedia.currentTime = (fakeMedia.duration - jumpInterval) + 1;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(fakeMedia.duration));
});

test('when page down key pressed it rewinds', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_DOWN;
  const previousTime = fakeMedia.duration / 2;
  fakeMedia.currentTime = previousTime;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(previousTime - jumpInterval));
});

test('when page down key near the beginning it rewinds to the beginning', () => {
  fakeEvent.keyCode = KeyCodes.PAGE_DOWN;
  fakeMedia.currentTime = 1;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playpauseHandler();
  ok(fakeMedia.setCurrentTime.calledWith(0));
});

test('when f key is pressed it simulates a click for IE', () => {
  const $btnWrapper = $('<div class="mejs-fullscreen-button">');
  const $fullscreenBtn = $('<button></button>');
  $target.append($btnWrapper.append($fullscreenBtn));

  sinon.stub($fullscreenBtn[0], 'click');

  fakeEvent.keyCode = KeyCodes.F;
  fakeEvent.target = $target;

  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok($fullscreenBtn[0].click.called);
});

test('when page down key pressed it sets volume lower', () => {
  fakeEvent.keyCode = KeyCodes.DOWN;
  const previousVolume = fakeMedia.volume;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok(fakeMedia.setVolume.calledWith(previousVolume - 0.1));
});

test('when page up key pressed it sets volume higher', () => {
  fakeEvent.keyCode = KeyCodes.UP;
  const previousVolume = fakeMedia.volume;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok(fakeMedia.setVolume.calledWith(previousVolume + 0.1));
});

test('when enter pressed it sets volume to 0', () => {
  fakeEvent.keyCode = KeyCodes.M;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok(fakePlayer.setMuted.calledWith(true));
});

test('when space pressed when paused it triggers play', () => {
  fakeEvent.keyCode = KeyCodes.SPACE;
  fakeMedia.paused = true;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok(fakeMedia.play.called);
});

test('when space pressed when playing it triggers pause', () => {
  fakeEvent.keyCode = KeyCodes.SPACE;
  fakeMedia.paused = false;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  handler.playerHandler();
  ok(fakeMedia.pause.called);
});

test('when other key pressed it does nothing', () => {
  fakeEvent.keyCode = KeyCodes.ESQ;
  handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent);
  strictEqual(handler.playerHandler(), undefined);
});
