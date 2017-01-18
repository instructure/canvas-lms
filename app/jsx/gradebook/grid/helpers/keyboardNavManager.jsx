define([
], function () {
  function KeyboardNavManager(dimensions) {
    this.boundaries =  {
      left: 0,
      right: dimensions.width - 1,
      top: 0,
      bottom: dimensions.height - 1
    };
  }

  KeyboardNavManager.prototype.makeMove = function(event, currentCellIndex) {
    var name = this.getKeyboardEventName(event);
    var newIndex;

    if (currentCellIndex === -1) {
      newIndex = 0;
    } else if (name === 'tab' || name === 'rightArrow') {
      newIndex = this.attemptMoveRight(currentCellIndex);
    } else if (name === 'shiftTab' || name === 'leftArrow') {
      newIndex = this.attemptMoveLeft(currentCellIndex);
    } else if (name === 'enter' || name === 'downArrow') {
      newIndex = this.attemptMoveDown(currentCellIndex);
    } else if (name === 'shiftEnter' || name === 'upArrow') {
      newIndex = this.attemptMoveUp(currentCellIndex);
    }

    return newIndex;
  };

  KeyboardNavManager.prototype.getKeyboardEventName = function(event) {
    var shiftKey = event.shiftKey ? 'shift' : 'noShift';
    var code = event.keyCode;
    var eventNames = {
      9:  { noShift: 'tab', shift: 'shiftTab' },
      13: { noShift: 'enter', shift: 'shiftEnter' },
      37: { noShift: 'leftArrow' },
      38: { noShift: 'upArrow' },
      39: { noShift: 'rightArrow' },
      40: { noShift: 'downArrow' }
    };

    return eventNames[code] && eventNames[code][shiftKey];
  };

  KeyboardNavManager.prototype.restrictedDirections = function(coords) {
    return {
      left: coords.x <= this.boundaries.left,
      right: coords.x >= this.boundaries.right,
      up: coords.y <= this.boundaries.top,
      down: coords.y >= this.boundaries.bottom
    };
  };

  KeyboardNavManager.prototype.indexToCoords = function(currentCellIndex) {
    var rowLength = this.boundaries.right + 1;
    var x = currentCellIndex % rowLength;
    var y = Math.floor(currentCellIndex / rowLength);
    this.invalidCellIndexCheck(currentCellIndex);
    return { x, y };
  };

  KeyboardNavManager.prototype.coordsToIndex = function(coords) {
    var rowLength = this.boundaries.right + 1;
    var yIndexVal = rowLength * coords.y;
    return coords.x + yIndexVal;
  };

  KeyboardNavManager.prototype.invalidCellIndexCheck = function(cellIndex) {
    var maxCoords = { x: this.boundaries.right, y: this.boundaries.bottom };
    var maxIndex = this.coordsToIndex(maxCoords);
    var message;
    if (cellIndex < 0 || cellIndex > maxIndex) {
      message = 'Invalid cell index of ' + cellIndex + ' provided. The cell ' +
      'index must be between 0 and ' + maxIndex + ', inclusive.';
      throw new Error(message);
    }
  };

  KeyboardNavManager.prototype.invalidMovementCheck = function(coords, direction) {
    var message;
    if (this.restrictedDirections(coords)[direction]) {
      message = 'Boundary restriction: cannot move ' + direction;
      throw new Error(message);
    }
  };

  KeyboardNavManager.prototype.moveLeft = function(coords) {
    this.invalidMovementCheck(coords, 'left');
    return { x: coords.x - 1, y: coords.y };
  };

  KeyboardNavManager.prototype.moveRight = function(coords) {
    this.invalidMovementCheck(coords, 'right');
    return { x: coords.x + 1, y: coords.y };
  };

  KeyboardNavManager.prototype.moveUp = function(coords) {
    this.invalidMovementCheck(coords, 'up');
    return { x: coords.x, y: coords.y - 1 };
  };

  KeyboardNavManager.prototype.moveDown = function(coords) {
    this.invalidMovementCheck(coords, 'down');
    return { x: coords.x, y: coords.y + 1 };
  };

  KeyboardNavManager.prototype.snapLeft = function(coords) {
    return { x: this.boundaries.left, y: coords.y };
  };

  KeyboardNavManager.prototype.snapRight = function(coords) {
    return { x: this.boundaries.right, y: coords.y };
  };

  KeyboardNavManager.prototype.snapTop = function(coords) {
    return { x: coords.x, y: this.boundaries.top };
  };

  KeyboardNavManager.prototype.snapBottom = function(coords) {
    return { x: coords.x, y: this.boundaries.bottom };
  };

  KeyboardNavManager.prototype.attemptMoveLeft = function(currentCellIndex) {
    var coords = this.indexToCoords(currentCellIndex);
    var restricted = this.restrictedDirections(coords);

    if (!restricted.left) {
      coords = this.moveLeft(coords);
    } else if (restricted.up) {
      coords = this.snapBottom(this.snapRight(coords));
    } else {
      coords = this.moveUp(this.snapRight(coords));
    }

    return this.coordsToIndex(coords);
  };

  KeyboardNavManager.prototype.attemptMoveRight = function(currentCellIndex) {
    var coords = this.indexToCoords(currentCellIndex);
    var restricted = this.restrictedDirections(coords);

    if (!restricted.right) {
      coords = this.moveRight(coords);
    } else if (restricted.down) {
      coords = this.snapTop(this.snapLeft(coords));
    } else {
      coords = this.moveDown(this.snapLeft(coords));
    }

    return this.coordsToIndex(coords);
  };

  KeyboardNavManager.prototype.attemptMoveUp = function(currentCellIndex) {
    var coords = this.indexToCoords(currentCellIndex);
    var restricted = this.restrictedDirections(coords);

    if (!restricted.up) {
      coords = this.moveUp(coords);
    } else if (restricted.left) {
      coords = this.snapRight(this.snapBottom(coords));
    } else {
      coords = this.moveLeft(this.snapBottom(coords));
    }

    return this.coordsToIndex(coords);
  };

  KeyboardNavManager.prototype.attemptMoveDown = function(currentCellIndex) {
    var coords = this.indexToCoords(currentCellIndex);
    var restricted = this.restrictedDirections(coords);

    if (!restricted.down) {
      coords = this.moveDown(coords);
    } else if (restricted.right) {
      coords = this.snapLeft(this.snapTop(coords));
    } else {
      coords = this.moveRight(this.snapTop(coords));
    }

    return this.coordsToIndex(coords);
  };

  return KeyboardNavManager;
});