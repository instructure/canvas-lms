"use strict";
var Ember = require("ember")["default"] || require("ember");
exports["default"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  


  data.buffer.push("ic-modal-screen,\nic-modal,\nic-modal-main,\nic-modal-title {\n  display: block;\n}\n\nic-modal,\n.ic-modal-form {\n  display: none;\n  -webkit-overflow-scrolling: touch;\n  position: fixed;\n  bottom: 0;\n  left: 0;\n  right: 0;\n  top: 0;\n  overflow: auto;\n  background-color: hsla(0, 0%, 100%, .90);\n  padding: 10px;\n}\n\nic-modal[is-open],\n.ic-modal-form[is-open] {\n  display: block;\n}\n\nic-modal-main {\n  position: relative;\n  margin: 40px auto;\n  max-width: 800px;\n  padding: 20px;\n  border-radius: 4px;\n  background: #fff;\n  border: 1px solid hsl(0, 0%, 70%);\n}\n\nic-modal-title {\n  margin: 0 -20px 20px -20px;\n  padding: 0 20px 20px 20px;\n  border-bottom: 1px solid hsl(0, 0%, 90%);\n}\n\n.ic-modal-trigger.ic-modal-close {\n  position: absolute;\n  right: 10px;\n  top: 10px;\n  background: none;\n  border: none;\n  color: inherit;\n  font-size: 18px;\n  padding: 6px;\n}\n\n.ic-modal-trigger.ic-modal-close:focus {\n  outline: none;\n  text-shadow: 0 0 6px hsl(208, 47%, 60%),\n    0 0 2px hsl(208, 47%, 60%),\n    0 0 2px hsl(208, 47%, 60%),\n    0 0 1px hsl(208, 47%, 60%);\n}\n\n");
  
});