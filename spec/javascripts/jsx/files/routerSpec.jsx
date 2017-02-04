define([
  'jsx/files/router',
], (router) => {

  // No op for next().
  const fakeNext = () => {};

  QUnit.module('Files Client-side Router');

  test('getFolderSplat returns the proper splat on ctx given uri characters', () => {
    const fakeCtx = {
      pathname: '/folder/this#could+be bad? maybe'
    };

    router.getFolderSplat(fakeCtx, fakeNext);

    equal(fakeCtx.splat, 'this%23could%2Bbe%20bad%3F%20maybe', 'splat is correctly encoded');

  });

  test('getFolderSplat returns the proper splat on ctx with multiple levels', () => {
    const fakeCtx = {
      pathname: '/folder/this#could+be bad? maybe/another?bad folder/something else'
    };

    router.getFolderSplat(fakeCtx, fakeNext);

    equal(fakeCtx.splat, 'this%23could%2Bbe%20bad%3F%20maybe/another%3Fbad%20folder/something%20else', 'splat is correctly encoded');

  });

});