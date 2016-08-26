define([
  'react',
  'jsx/shared/FlickrImage'
], (React, FlickrImage) => {

  const TestUtils = React.addons.TestUtils;

  module('FlickrImage View');

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