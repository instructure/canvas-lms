define([
  'bower/reflux/dist/reflux',
  'underscore',
  'jquery',
  'jsx/gradebook/grid/actions/keyboardNavigationActions',
  'jsx/gradebook/grid/helpers/keyboardNavManager'
], function (Reflux, _, $, KeyboardNavigationActions, KeyboardNavigationManager) {

  var KeyboardNavigationStore = Reflux.createStore({
    listenables: [KeyboardNavigationActions],

    init() {
      this.state = {
        currentCellIndex: -1,
        currentColumnIndex: -1,
        currentRowIndex: -1
      };
    },

    getInitialState() {
      if(this.state === undefined) {
        this.init();
      }

      return this.state;
    },

    rowCount(columnCount) {
      var cellCount;
      if (columnCount === 0) return 0;
      cellCount = $('.gradebook-cell').size();
      return cellCount / columnCount;
    },

    columnCount() {
      return $('.fixedDataTableCellLayout_columnResizerContainer').size();
    },

    onConstructKeyboardNavManager() {
      var columnCount = this.columnCount();
      var rowCount = this.rowCount(columnCount);
      var dimensions = { width: columnCount, height: rowCount };
      this.navManager = new KeyboardNavigationManager(dimensions);
    },

    onHandleKeyboardEvent(event) {
      var newIndex = this.navManager.makeMove(event, this.state.currentCellIndex);
      if (_.isNumber(newIndex)) this.onSetActiveCell(newIndex);
    },

    onSetActiveCell(cellIndex) {
      var coords = this.navManager.indexToCoords(cellIndex);

      this.state.currentCellIndex = cellIndex;
      this.state.currentColumnIndex = coords.x;
      this.state.currentRowIndex = coords.y;
      this.trigger(this.state);
    }
  });

  return KeyboardNavigationStore;
});
