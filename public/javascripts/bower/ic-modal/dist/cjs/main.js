"use strict";
var ModalComponent = require("./modal")["default"] || require("./modal");
var ModalFormComponent = require("./modal-form")["default"] || require("./modal-form");
var ModalTriggerComponent = require("./modal-trigger")["default"] || require("./modal-trigger");
var ModalTitleComponent = require("./modal-title")["default"] || require("./modal-title");
var modalCss = require("./templates/modal-css")["default"] || require("./templates/modal-css");
var modalTemplate = require("./templates/modal")["default"] || require("./templates/modal");
var Application = require("ember").Application;
require("./tabbable-selector");
Application.initializer({
  name: 'ic-modal',
  initialize: function(container) {
    container.register('component:ic-modal', ModalComponent);
    container.register('component:ic-modal-form', ModalFormComponent);
    container.register('component:ic-modal-trigger', ModalTriggerComponent);
    container.register('component:ic-modal-title', ModalTitleComponent);
    container.register('template:components/ic-modal-css', modalCss);
    container.register('template:components/ic-modal-form-css', modalCss);
    container.register('template:components/ic-modal', modalTemplate);
    container.register('template:components/ic-modal-form', modalTemplate);
  }
});

exports.ModalComponent = ModalComponent;
exports.ModalFormComponent = ModalFormComponent;
exports.ModalTriggerComponent = ModalTriggerComponent;
exports.ModalTitleComponent = ModalTitleComponent;
exports.modalCss = modalCss;