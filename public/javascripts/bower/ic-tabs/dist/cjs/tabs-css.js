"use strict";
var Ember = require("ember")["default"] || require("ember");
exports["default"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  


  data.buffer.push("ic-tabs,\nic-tab-list,\nic-tab-panel {\n  display: block\n}\n\nic-tab-list {\n  border-bottom: 1px solid #aaa;\n}\n\nic-tab {\n  display: inline-block;\n  padding: 6px 12px;\n  border: 1px solid transparent;\n  border-top-left-radius: 3px;\n  border-top-right-radius: 3px;\n  cursor: pointer;\n  margin-bottom: -1px;\n  position: relative;\n}\n\nic-tab[selected] {\n  border-color: #aaa;\n  border-bottom-color: #fff;\n}\n\nic-tab:focus {\n  box-shadow: 0 10px 0 0 #fff,\n              0 0 5px hsl(208, 99%, 50%);\n  border-color: hsl(208, 99%, 50%);\n  border-bottom-color: #fff;\n  outline: none;\n}\n\nic-tab:focus:before,\nic-tab:focus:after {\n  content: '';\n  position: absolute;\n  bottom: -6px;\n  width: 5px;\n  height: 5px;\n  background: #fff;\n}\n\nic-tab:focus:before {\n  left: -4px;\n}\n\nic-tab:focus:after {\n  right: -4px;\n}\n\n");
  
});