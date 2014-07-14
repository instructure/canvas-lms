define(
  ["ember-data","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var Model = __dependency1__.Model;
    var attr = __dependency1__.attr;

    var Course = Model.extend({
      name: attr(),

      folder: DS.belongsTo('folder', {async:true}),
      conclude: function() {
        // DELETE to url with {event: 'conclude'}
        // TODO: how?
        //this.destroyRecord({event: 'conclude'});
      }
    });

    __exports__["default"] = Course;
  });