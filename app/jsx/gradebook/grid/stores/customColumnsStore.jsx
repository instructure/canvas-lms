define([
  'bower/reflux/dist/reflux',
  'underscore',
  'jsx/gradebook/grid/actions/customColumnsActions'
], function (Reflux, _, CustomColumnsActions) {
  var CustomColumnsStore = Reflux.createStore({
    listenables: [CustomColumnsActions],

    init() {
      this.state = {
        teacherNotes: null,
        customColumns: {
          data: [],
          columnData: {}
        }
      };
    },

    getInitialState() {
      if(this.state === undefined) {
        this.init();
      }

      return this.state;
    },

    customColumns(data) {
      return _.isUndefined(data) ? [] : _.reject(data, column => column.hidden || column.teacher_notes);
    },

    onLoadCompleted(data) {
      this.state.customColumns.data = this.customColumns(data);
      this.trigger(this.state);
    },

    onLoadTeacherNotesCompleted(teacherNotes) {
      var notes = _.isUndefined(teacherNotes) ? [] : teacherNotes;
      this.state.teacherNotes = notes;
      this.trigger(this.state);
    },

    onLoadColumnDataCompleted(data, columnId) {
      if (this.state.customColumns.columnData[columnId] === undefined) {
        this.state.customColumns.columnData[columnId] = {};
      }

      _.each(data, function(columnDatum) {
        this.state.customColumns.columnData[columnId][columnDatum.user_id] = columnDatum;
      }.bind(this));

    },

    getColumnDatum(columnId, userId) {
      var columnData, columnDatum;

      columnData = this.state.customColumns.columnData[columnId];
      if (columnData !== undefined) {
        columnDatum = columnData[userId];
        return columnDatum;
      }

      return undefined;
    },

    onUpdateTeacherNote(noteData) {
      var teacherNotes = this.state.teacherNotes,
        existingNote = _.find(teacherNotes, note => note.user_id === noteData.user_id);
      if (existingNote) {
        existingNote.content = noteData.content;
      } else {
        teacherNotes.push(noteData);
      }
      this.trigger(this.state);
    }
  });

  return CustomColumnsStore;
});
