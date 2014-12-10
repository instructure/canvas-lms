define(function(require) {
  var K = require('../constants');
  var ATTRIBUTES = [
    { name: 'id', required: true },
    { name: 'code', required: true },
    { name: 'context', required: false }
  ];

  var Notification = function(attrs) {
    ATTRIBUTES.forEach(function(attr) {
      if (attr.required && !attrs.hasOwnProperty(attr.name)) {
        throw new Error("Notification is missing a required attribute '" + attr.name + "'");
      }

      this[attr.name] = attrs[attr.name];
    }.bind(this));

    if (this.code === undefined) {
      throw new Error("You must register the notification code as a constant.");
    }

    return this;
  };

  Notification.prototype.toJSON = function() {
    return ATTRIBUTES.reduce(function(attributes, attr) {
      attributes[attr.name] = this[attr.name];
      return attributes;
    }.bind(this), {});
  };

  return Notification;
});