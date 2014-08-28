define(
  ["./modal","./modal-form","./modal-trigger","./modal-title","./templates/modal-css","./templates/modal","ember","./tabbable-selector","exports"],
  function(__dependency1__, __dependency2__, __dependency3__, __dependency4__, __dependency5__, __dependency6__, __dependency7__, __dependency8__, __exports__) {
    "use strict";
    var ModalComponent = __dependency1__["default"] || __dependency1__;
    var ModalFormComponent = __dependency2__["default"] || __dependency2__;
    var ModalTriggerComponent = __dependency3__["default"] || __dependency3__;
    var ModalTitleComponent = __dependency4__["default"] || __dependency4__;
    var modalCss = __dependency5__["default"] || __dependency5__;
    var modalTemplate = __dependency6__["default"] || __dependency6__;
    var Application = __dependency7__.Application;

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

    __exports__.ModalComponent = ModalComponent;
    __exports__.ModalFormComponent = ModalFormComponent;
    __exports__.ModalTriggerComponent = ModalTriggerComponent;
    __exports__.ModalTitleComponent = ModalTitleComponent;
    __exports__.modalCss = modalCss;
  });