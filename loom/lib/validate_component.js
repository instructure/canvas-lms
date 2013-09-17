var msg = require('loom/lib/message');

module.exports = function(name) {
  console.log(name);
  if (name.indexOf('-') < 0) {
    msg.error("Components must have a '-' character");
  }
};

