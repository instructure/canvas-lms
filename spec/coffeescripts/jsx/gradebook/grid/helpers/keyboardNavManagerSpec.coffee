define [
  'jsx/gradebook/grid/helpers/keyboardNavManager'

], (KeyboardNavManager) ->
  module 'KeyboardNavManager#new',

  test 'returns an object with the appropriate boundaries', ->
    nav = new KeyboardNavManager({ width: 5, height: 8 })
    expectedBoundaries = { left: 0, right: 4, top: 0, bottom: 7 }
    propEqual nav.boundaries, expectedBoundaries

  module 'KeyboardNavManager#makeMove',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'returns 0 if a cellIndex of -1 is passed in', ->
    currentCellIndex = -1
    tabEvent = { keyCode: 9, shiftKey: false }
    newIndex = @nav.makeMove(tabEvent, currentCellIndex)
    deepEqual newIndex, 0

  test 'returns undefined if an unrecognized event is passed in', ->
    currentCellIndex = 3
    tabEvent = { keyCode: 19, shiftKey: false }
    newIndex = @nav.makeMove(tabEvent, currentCellIndex)
    deepEqual newIndex, undefined

  test 'calls attemptMoveRight if the tab key is pressed', ->
    currentCellIndex = 3
    tabKeyCode = 9
    fakeEvent = { keyCode: tabKeyCode, shiftKey: false }
    moveRightStub = @stub(@nav, 'attemptMoveRight')
    @nav.makeMove(fakeEvent, currentCellIndex)
    ok moveRightStub.calledOnce

  test 'calls attemptMoveRight if the right arrow is pressed', ->
    currentCellIndex = 3
    rightArrowKeyCode = 39
    fakeEvent = { keyCode: rightArrowKeyCode, shiftKey: false }
    moveRightStub = @stub(@nav, 'attemptMoveRight')
    @nav.makeMove(fakeEvent, currentCellIndex)
    ok moveRightStub.calledOnce

  test 'calls attemptMoveLeft if shift + tab is pressed', ->
    currentCellIndex = 3
    tabKeyCode = 9
    fakeEvent = { keyCode: tabKeyCode, shiftKey: true }
    moveLeftStub = @stub(@nav, 'attemptMoveLeft')
    @nav.makeMove(fakeEvent, currentCellIndex)
    ok moveLeftStub.calledOnce

  test 'calls attemptMoveLeft if the left arrow is pressed', ->
    currentCellIndex = 3
    leftArrowKeyCode = 37
    fakeEvent = { keyCode: leftArrowKeyCode, shiftKey: false }
    moveLeftStub = @stub(@nav, 'attemptMoveLeft')
    @nav.makeMove(fakeEvent, currentCellIndex)
    ok moveLeftStub.calledOnce

  test 'calls attemptMoveDown if enter is pressed', ->
    currentCellIndex = 3
    enterKeyCode = 13
    fakeEvent = { keyCode: enterKeyCode, shiftKey: false }
    moveDownStub = @stub(@nav, 'attemptMoveDown')
    @nav.makeMove(fakeEvent, currentCellIndex)
    ok moveDownStub.calledOnce

  test 'calls attemptMoveDown if the down arrow is pressed', ->
    currentCellIndex = 3
    downArrowKeyCode = 40
    fakeEvent = { keyCode: downArrowKeyCode, shiftKey: false }
    moveDownStub = @stub(@nav, 'attemptMoveDown')
    @nav.makeMove(fakeEvent, currentCellIndex)
    ok moveDownStub.calledOnce

  test 'calls attemptMoveUp if shift + enter is pressed', ->
    currentCellIndex = 3
    enterKeyCode = 13
    fakeEvent = { keyCode: enterKeyCode, shiftKey: true }
    moveUpStub = @stub(@nav, 'attemptMoveUp')
    @nav.makeMove(fakeEvent, currentCellIndex)
    ok moveUpStub.calledOnce

  test 'calls attemptMoveUp if the up arrow is pressed', ->
    currentCellIndex = 3
    upArrowKeyCode = 38
    fakeEvent = { keyCode: upArrowKeyCode, shiftKey: false }
    moveUpStub = @stub(@nav, 'attemptMoveUp')
    @nav.makeMove(fakeEvent, currentCellIndex)
    ok moveUpStub.calledOnce

  module 'KeyboardNavManager#getKeyboardEventName',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'recognizes and identifies "tab"', ->
    tabEvent = { keyCode: 9, shiftKey: false }
    expected = 'tab'
    deepEqual @nav.getKeyboardEventName(tabEvent), expected

  test 'recognizes and identifies "tab" + "shift"', ->
    tabEvent = { keyCode: 9, shiftKey: true }
    expected = 'shiftTab'
    deepEqual @nav.getKeyboardEventName(tabEvent), expected

  test 'recognizes and identifies "enter"', ->
    enterEvent = { keyCode: 13, shiftKey: false }
    expected = 'enter'
    deepEqual @nav.getKeyboardEventName(enterEvent), expected

  test 'recognizes and identifies "enter" + "shift"', ->
    enterEvent = { keyCode: 13, shiftKey: true }
    expected = 'shiftEnter'
    deepEqual @nav.getKeyboardEventName(enterEvent), expected

  test 'recognizes and identifies the left arrow key', ->
    arrowEvent = { keyCode: 37, shiftKey: false }
    deepEqual @nav.getKeyboardEventName(arrowEvent), 'leftArrow'

  test 'recognizes and identifies the up arrow key', ->
    arrowEvent = { keyCode: 38, shiftKey: false }
    deepEqual @nav.getKeyboardEventName(arrowEvent), 'upArrow'

  test 'recognizes and identifies the right arrow key', ->
    arrowEvent = { keyCode: 39, shiftKey: false }
    deepEqual @nav.getKeyboardEventName(arrowEvent), 'rightArrow'

  test 'recognizes and identifies the down arrow key', ->
    arrowEvent = { keyCode: 40, shiftKey: false }
    deepEqual @nav.getKeyboardEventName(arrowEvent), 'downArrow'

  test 'returns undefined for unrecognized keyCodes', ->
    unknownEvent = { keyCode: 1, shiftKey: false }
    deepEqual @nav.getKeyboardEventName(unknownEvent), undefined

  test 'returns undefined for recognized keyCodes with unrecognized "shift" key combinations', ->
    arrowWithShiftEvent = { keyCode: 37, shiftKey: true }
    deepEqual @nav.getKeyboardEventName(arrowWithShiftEvent), undefined

  module 'KeyboardNavManager#restrictedDirections',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'returns false for all directions if the current coordinates are not resticted by movement', ->
    coords = { x: 3, y: 3 }
    expected = { left: false, right: false, up: false, down: false }
    propEqual @nav.restrictedDirections(coords), expected

  test 'detects restriction of "left" movement', ->
    coords = { x: 0, y: 3 }
    expected = { left: true, right: false, up: false, down: false }
    propEqual @nav.restrictedDirections(coords), expected

  test 'detects restriction of "right" movement', ->
    coords = { x: 4, y: 3 }
    expected = { left: false, right: true, up: false, down: false }
    propEqual @nav.restrictedDirections(coords), expected

  test 'detects restriction of "up" movement', ->
    coords = { x: 3, y: 0 }
    expected = { left: false, right: false, up: true, down: false }
    propEqual @nav.restrictedDirections(coords), expected

  test 'detects restriction of "down" movement', ->
    coords = { x: 3, y: 7 }
    expected = { left: false, right: false, up: false, down: true }
    propEqual @nav.restrictedDirections(coords), expected

  test 'detects restriction of movement in top left corner', ->
    coords = { x: 0, y: 0 }
    expected = { left: true, right: false, up: true, down: false }
    propEqual @nav.restrictedDirections(coords), expected

  test 'detects restriction of movement in top right corner', ->
    coords = { x: 4, y: 0 }
    expected = { left: false, right: true, up: true, down: false }
    propEqual @nav.restrictedDirections(coords), expected

  test 'detects restriction of movement in bottom left corner', ->
    coords = { x: 0, y: 7 }
    expected = { left: true, right: false, up: false, down: true }
    propEqual @nav.restrictedDirections(coords), expected

  test 'detects restriction of movement in bottom right corner', ->
    coords = { x: 4, y: 7 }
    expected = { left: false, right: true, up: false, down: true }
    propEqual @nav.restrictedDirections(coords), expected

  module 'KeyboardNavManager#indexToCoords',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes an index and converts it to coordinates', ->
    index = 7
    expected = { x: 2, y: 1 }
    propEqual @nav.indexToCoords(index), expected

  module 'KeyboardNavManager#coordsToIndex',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes coordinates and converts them to a single index', ->
    coords = { x: 2, y: 1 }
    expected = 7
    propEqual @nav.coordsToIndex(coords), expected

  module 'KeyboardNavManager#moveLeft',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes coordinates and moves left one space', ->
    coords = { x: 2, y: 1 }
    expected = { x: 1, y: 1 }
    propEqual @nav.moveLeft(coords), expected

  test 'throws an exception if a left move is not possible due to boundary restrictions', ->
    coords = { x: 0, y: 1 }
    throws @nav.moveLeft.bind(@nav, coords)

  module 'KeyboardNavManager#moveRight',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes coordinates and moves right one space', ->
    coords = { x: 2, y: 1 }
    expected = { x: 3, y: 1 }
    propEqual @nav.moveRight(coords), expected

  test 'throws an exception if a right move is not possible due to boundary restrictions', ->
    coords = { x: 4, y: 1 }
    throws @nav.moveRight.bind(@nav, coords)

  module 'KeyboardNavManager#moveUp',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes coordinates and moves up one space', ->
    coords = { x: 2, y: 1 }
    expected = { x: 2, y: 0 }
    propEqual @nav.moveUp(coords), expected

  test 'throws an exception if a up move is not possible due to boundary restrictions', ->
    coords = { x: 2, y: 0 }
    throws @nav.moveUp.bind(@nav, coords)

  module 'KeyboardNavManager#moveDown',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes coordinates and moves down one space', ->
    coords = { x: 2, y: 1 }
    expected = { x: 2, y: 2 }
    propEqual @nav.moveDown(coords), expected

  test 'throws an exception if a down move is not possible due to boundary restrictions', ->
    coords = { x: 2, y: 7 }
    throws @nav.moveDown.bind(@nav, coords)

  module 'KeyboardNavManager#snapLeft',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes coordinates and changes the x coord to 0', ->
    coords = { x: 2, y: 3 }
    expected = { x: 0, y: 3 }
    propEqual @nav.snapLeft(coords), expected

  module 'KeyboardNavManager#snapRight',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes coordinates and changes the x coord to the width minus 1', ->
    coords = { x: 2, y: 3 }
    expected = { x: 4, y: 3 }
    propEqual @nav.snapRight(coords), expected

  module 'KeyboardNavManager#snapTop',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes coordinates and changes the y coord to 0', ->
    coords = { x: 2, y: 3 }
    expected = { x: 2, y: 0 }
    propEqual @nav.snapTop(coords), expected

  module 'KeyboardNavManager#snapBottom',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes coordinates and changes the y coord to height minus 1', ->
    coords = { x: 2, y: 3 }
    expected = { x: 2, y: 7 }
    propEqual @nav.snapBottom(coords), expected

  module 'KeyboardNavManager#attemptMoveLeft',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes a number representing a cell index and returns a number representing a cell index', ->
    index = @nav.coordsToIndex({ x: 2, y: 3 })
    deepEqual typeof @nav.attemptMoveLeft(index), 'number'

  test 'throws an error if an invalid cell index is provided (too small)', ->
    index = -1
    throws @nav.attemptMoveLeft.bind(@nav, index)

  test 'throws an error if an invalid cell index is provided (too large)', ->
    index = 40
    throws @nav.attemptMoveLeft.bind(@nav, index)

  test 'moves left one, if possible', ->
    index = @nav.coordsToIndex({ x: 2, y: 3 })
    expected = @nav.coordsToIndex({ x: 1, y: 3 })
    deepEqual @nav.attemptMoveLeft(index), expected

  test 'moves up one and snaps right if cannot move left, if possible', ->
    index = @nav.coordsToIndex({ x: 0, y: 3 })
    expected = @nav.coordsToIndex({ x: 4, y: 2 })
    deepEqual @nav.attemptMoveLeft(index), expected

  test 'snaps to the bottom right corner if cannot move left or up', ->
    index = @nav.coordsToIndex({ x: 0, y: 0 })
    expected = @nav.coordsToIndex({ x: 4, y: 7 })
    deepEqual @nav.attemptMoveLeft(index), expected

  module 'KeyboardNavManager#attemptMoveRight',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes a number representing a cell index and returns a number representing a cell index', ->
    index = @nav.coordsToIndex({ x: 2, y: 3 })
    deepEqual typeof @nav.attemptMoveRight(index), 'number'

  test 'throws an error if an invalid cell index is provided (too small)', ->
    index = -1
    throws @nav.attemptMoveRight.bind(@nav, index)

  test 'throws an error if an invalid cell index is provided (too large)', ->
    index = 40
    throws @nav.attemptMoveRight.bind(@nav, index)

  test 'moves right one, if possible', ->
    index = @nav.coordsToIndex({ x: 2, y: 3 })
    expected = @nav.coordsToIndex({ x: 3, y: 3 })
    deepEqual @nav.attemptMoveRight(index), expected

  test 'moves down one and snaps left if cannot move right, if possible', ->
    index = @nav.coordsToIndex({ x: 4, y: 3 })
    expected = @nav.coordsToIndex({ x: 0, y: 4 })
    deepEqual @nav.attemptMoveRight(index), expected

  test 'snaps to the top left corner if cannot move right or down', ->
    index = @nav.coordsToIndex({ x: 4, y: 7 })
    expected = @nav.coordsToIndex({ x: 0, y: 0 })
    deepEqual @nav.attemptMoveRight(index), expected

  module 'KeyboardNavManager#attemptMoveUp',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes a number representing a cell index and returns a number representing a cell index', ->
    index = @nav.coordsToIndex({ x: 2, y: 3 })
    deepEqual typeof @nav.attemptMoveUp(index), 'number'

  test 'throws an error if an invalid cell index is provided (too small)', ->
    index = -1
    throws @nav.attemptMoveUp.bind(@nav, index)

  test 'throws an error if an invalid cell index is provided (too large)', ->
    index = 40
    throws @nav.attemptMoveUp.bind(@nav, index)

  test 'moves up one, if possible', ->
    index = @nav.coordsToIndex({ x: 2, y: 3 })
    expected = @nav.coordsToIndex({ x: 2, y: 2 })
    deepEqual @nav.attemptMoveUp(index), expected

  test 'moves left one and snaps to the bottom if cannot move up, if possible', ->
    index = @nav.coordsToIndex({ x: 4, y: 0 })
    expected = @nav.coordsToIndex({ x: 3, y: 7 })
    deepEqual @nav.attemptMoveUp(index), expected

  test 'snaps to the bottom right corner if cannot move up or left', ->
    index = @nav.coordsToIndex({ x: 0, y: 0 })
    expected = @nav.coordsToIndex({ x: 4, y: 7 })
    deepEqual @nav.attemptMoveUp(index), expected

  module 'KeyboardNavManager#attemptMoveDown',
    setup: ->
      @nav = new KeyboardNavManager({ width: 5, height: 8 })

  test 'takes a number representing a cell index and returns a number representing a cell index', ->
    index = @nav.coordsToIndex({ x: 2, y: 3 })
    deepEqual typeof @nav.attemptMoveDown(index), 'number'

  test 'throws an error if an invalid cell index is provided (too small)', ->
    index = -1
    throws @nav.attemptMoveDown.bind(@nav, index)

  test 'throws an error if an invalid cell index is provided (too large)', ->
    index = 40
    throws @nav.attemptMoveDown.bind(@nav, index)

  test 'moves down one, if possible', ->
    index = @nav.coordsToIndex({ x: 2, y: 3 })
    expected = @nav.coordsToIndex({ x: 2, y: 4 })
    deepEqual @nav.attemptMoveDown(index), expected

  test 'moves right one and snaps to the top if cannot move down, if possible', ->
    index = @nav.coordsToIndex({ x: 2, y: 7 })
    expected = @nav.coordsToIndex({ x: 3, y: 0 })
    deepEqual @nav.attemptMoveDown(index), expected

  test 'snaps to the top left corner if cannot move down or right', ->
    index = @nav.coordsToIndex({ x: 4, y: 7 })
    expected = @nav.coordsToIndex({ x: 0, y: 0 })
    deepEqual @nav.attemptMoveDown(index), expected
