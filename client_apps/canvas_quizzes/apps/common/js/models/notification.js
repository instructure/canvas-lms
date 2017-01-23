define((require) => {
  const K = require('../constants');
  const ATTRIBUTES = [
    { name: 'id', required: true },
    { name: 'code', required: true },
    { name: 'context', required: false }
  ];

  /**
   * @class Models.Notification
   */
  const Notification = function (attrs) {
    ATTRIBUTES.forEach((attr) => {
      if (attr.required && !attrs.hasOwnProperty(attr.name)) {
        throw new Error(`Notification is missing a required attribute '${attr.name}'`);
      }

      this[attr.name] = attrs[attr.name];
    });

    if (this.code === undefined) {
      throw new Error('You must register the notification code as a constant.');
    }

    return this;
  };

  Notification.prototype.toJSON = function () {
    return ATTRIBUTES.reduce((attributes, attr) => {
      attributes[attr.name] = this[attr.name];
      return attributes;
    }, {});
  };

  return Notification;
});
