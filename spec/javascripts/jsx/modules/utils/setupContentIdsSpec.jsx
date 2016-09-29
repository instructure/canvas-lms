define([
  'jquery',
  'jsx/modules/utils/setupContentIds'
], ($, setupContentIds) => {

  module('Modules Utilities: setupContentIds');

  test('It puts the proper attribute values in place when called', () => {
    const fakeModuleHtml = `<div>
      <div class="header">
        <span id="place1" aria-controls="context_module_content_"></span>
        <span id="place2" aria-controls="context_module_content_"></span>
      </div>
      <div class="content" id="context_module_content_"></div>
    </div>`;

    const $fakeModule = $(fakeModuleHtml);
    setupContentIds($fakeModule, 42);

    equal($fakeModule.find('#context_module_content_42').length, 1, 'finds the proper id');
    equal($fakeModule.find('#place1').attr('aria-controls'), 'context_module_content_42', 'sets the aria-controls of the first header element');
    equal($fakeModule.find('#place2').attr('aria-controls'), 'context_module_content_42', 'sets the aria-controls of the second header element');

  });
});
