define([
  'bower/reflux/dist/reflux',
  'jquery',
  '../actions/keyboardNavigationActions',
], function (Reflux, $, KeyboardNavigationActions) {

  var KeyboardNavigationStore = Reflux.createStore({
    listenables: [KeyboardNavigationActions],

    getInitialState() {
      this.currentCellIndex = -1;
      return this.currentCellIndex;
    },

    getCellCount() {
      return $('.gradebook-cell').size();
    },

    getColumnCount() {
      return $('.fixedDataTableCell_columnResizerContainer').size();
    },

    onNext() {
      if (this.currentCellIndex + 1 < this.getCellCount()) {
        this.currentCellIndex += 1;
        this.trigger(this.currentCellIndex);
      }
    },

    onPrevious() {
      if (this.currentCellIndex - 1 >= 0) {
        this.currentCellIndex -= 1;
        this.trigger(this.currentCellIndex);
      }
    },

    onUp() {
      var columnCount = this.getColumnCount();
      if (this.currentCellIndex - columnCount >= 0) {
        this.currentCellIndex -= columnCount;
        this.trigger(this.currentCellIndex);
      }
    },

    onDown() {
      var columnCount = this.getColumnCount(),
          cellCount   = this.getCellCount();

      if ((this.currentCellIndex + columnCount) < cellCount) {
        this.currentCellIndex += columnCount;
        this.trigger(this.currentCellIndex);
      }
    },

    onSetActiveCell(cellIndex) {
      this.currentCellIndex = cellIndex;
      this.trigger(this.currentCellIndex);
    }
  });

  return KeyboardNavigationStore;
});
