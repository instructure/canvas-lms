define([
  'bower/reflux/dist/reflux',
  'underscore',
  'jsx/gradebook/grid/actions/customColumnsActions'
], function (Reflux, _, CustomColumnsActions) {
  var CustomColumnsStore = Reflux.createStore({
    listenables: [CustomColumnsActions],

    init() {
      this.state = {
        teacherNotes: null
      };
    },

    getInitialState() {
      if(this.state === undefined) {
        this.init();
      }

      return this.state;
    },

    onLoadTeacherNotesCompleted(teacherNotes) {
      var notes = _.isUndefined(teacherNotes) ? [] : teacherNotes;
      this.state.teacherNotes = notes;
      this.trigger(this.state);
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
