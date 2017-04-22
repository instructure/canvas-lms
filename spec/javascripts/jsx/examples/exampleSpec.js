define([
  'spec/jsx/examples/exampleSpecHelper'
], function (exampleSpecHelper) {
  QUnit.module('Example JSX Spec');

  test('this is true', function () {
    equal(exampleSpecHelper.text, 'Example Text');
  });
});
