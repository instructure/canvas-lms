define([
  'react',
  'react-addons-test-utils',
  'jsx/shared/FlickrImage'
], (React, TestUtils, FlickrImage) => {

  QUnit.module('FlickrImage View');

  test('it renders', () => {
    const flickrImage = TestUtils.renderIntoDocument(
      <FlickrImage />
    );
    ok(flickrImage);
  });

  test('it calls selectImage when clicked', () => {
    let called = false;
    const selectImage = (flickrUrl) => called = true;

    const flickrImage = TestUtils.renderIntoDocument(
      <FlickrImage url={'http://imageUrl'} selectImage={selectImage} />
    );
    
    TestUtils.Simulate.click(flickrImage.refs.flickrImage);

    ok(called, 'selectImage was called');
  });

});