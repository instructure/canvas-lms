"use strict";
var Model = require("ember-data").Model;
var attr = require("ember-data").attr;

var Course = Model.extend({
  name: attr(),

  folder: DS.belongsTo('folder', {async:true}),
  conclude: function() {
    // DELETE to url with {event: 'conclude'}
    // TODO: how?
    //this.destroyRecord({event: 'conclude'});
  }
});

exports["default"] = Course;