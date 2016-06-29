define([
  'react',
  'react-dom',
  'react-modal',
  'jsx/files/FilePreview',
  'compiled/models/Folder',
  'compiled/models/File',
  'compiled/collections/FilesCollection',
  'compiled/collections/FoldersCollection'
], (React, ReactDOM, ReactModal, FilePreview, Folder, File, FilesCollection, FoldersCollection) => {
  const TestUtils = React.addons.TestUtils;

  let filesCollection = {};
  let folderCollection = {};
  let file1 = {};
  let file2 = {};
  let file3 = {};
  let currentFolder = {};

  module('File Preview Rendering', {
    setup () {
      // Initialize a few things to view in the preview.
      filesCollection = new FilesCollection();
      file1 = new File({
        id: '1',
        cid: 'c1',
        name:'Test File.file1',
        'content-type': 'unknown/unknown',
        size: 1000000,
        created_at: (new Date()).toISOString(),
        updated_at: (new Date()).toISOString()
        },
        {preflightUrl: ''}
      );
      file2 = new File({
        id: '2',
        cid: 'c2',
        name:'Test File.file2',
        'content-type': 'unknown/unknown',
        size: 1000000,
        created_at: (new Date()).toISOString(),
        updated_at: (new Date()).toISOString()
        },
        {preflightUrl: ''}
      );
      file3 = new File({
        id: '3',
        cid: 'c3',
        name:'Test File.file3',
        'content-type': 'unknown/unknown',
        size: 1000000,
        created_at: (new Date()).toISOString(),
        updated_at: (new Date()).toISOString(),
        url: 'test/test/test.png'
        },
        {preflightUrl: ''}
      );

      filesCollection.add(file1);
      filesCollection.add(file2);
      filesCollection.add(file3);
      currentFolder = new Folder();
      currentFolder.files = filesCollection;

      ReactModal.setAppElement(document.getElementById('fixtures'));
    },
    teardown () {
      let filesCollection = {};
      let folderCollection = {};
      let file1 = {};
      let file2 = {};
      let file3 = {};
      let currentFolder = {};
    }
  });

  test('clicking the info button should render out the info panel', () => {
    const component = TestUtils.renderIntoDocument(
      <FilePreview
        isOpen={true}
        query={{
          preview: '1'
        }}
        currentFolder={currentFolder}
      />
    );

    const modalPortal = component.refs.modal.portal;
    const infoBtn = TestUtils.findRenderedDOMComponentWithClass(modalPortal, 'ef-file-preview-header-info');
    TestUtils.Simulate.click(infoBtn);
    ok(component.state.showInfoPanel, 'info panel displayed state is updated');
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode);
  });

  test('clicking the info button after the panel has been opened should hide the info panel', () => {
    const component = TestUtils.renderIntoDocument(
      <FilePreview
        isOpen={true}
        query={{
          preview: '1'
        }}
        currentFolder={currentFolder}
      />
    );

    const modalPortal = component.refs.modal.portal;
    const infoBtn = TestUtils.findRenderedDOMComponentWithClass(modalPortal, 'ef-file-preview-header-info');
    TestUtils.Simulate.click(infoBtn);
    ok(component.state.showInfoPanel, 'info panel displayed state is updated to be open');
    TestUtils.Simulate.click(infoBtn);
    ok(!component.state.showInfoPanel, 'info panel displayed state is updated to false');
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode);
  });

  test('clicking the info button after the panel has been opened should hide the info panel', () => {
    const component = TestUtils.renderIntoDocument(
      <FilePreview
        isOpen={true}
        query={{
          preview: '1'
        }}
        currentFolder={currentFolder}
      />
    );

    const modalPortal = component.refs.modal.portal;
    const infoBtn = TestUtils.findRenderedDOMComponentWithClass(modalPortal, 'ef-file-preview-header-info');
    TestUtils.Simulate.click(infoBtn);
    ok(component.state.showInfoPanel, 'info panel displayed state is updated to be open');
    TestUtils.Simulate.click(infoBtn);
    ok(!component.state.showInfoPanel, 'info panel displayed state is updated to false');
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode);
  });

  test('opening the preview for one file should show navigation buttons for the previous and next files in the current folder', () => {
    const component = TestUtils.renderIntoDocument(
      <FilePreview
        isOpen={true}
        query={{
          preview: '2'
        }}
        currentFolder={currentFolder}
      />
    );

    const modalPortal = component.refs.modal.portal;
    const arrows = TestUtils.scryRenderedDOMComponentsWithClass(modalPortal, 'ef-file-preview-container-arrow-link');

    equal(arrows.length, 2, 'there are two arrows shown');

    ok(arrows[0].href.match("preview=1"), 'The left arrow link has an incorrect href (`preview` query string does not exist or points to the wrong id)');
    ok(arrows[1].href.match("preview=3"), 'The right arrow link has an incorrect href (`preview` query string does not exist or points to the wrong id)');
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode);
  });

  test('download button should be rendered on the file preview', () => {
    const component = TestUtils.renderIntoDocument(
      <FilePreview
        isOpen={true}
        query={{
          preview: '3'
        }}
        currentFolder={currentFolder}
      />
    );

    const modalPortal = component.refs.modal.portal;
    const downloadBtn = TestUtils.findRenderedDOMComponentWithClass(modalPortal, 'ef-file-preview-header-download');
    ok(downloadBtn, 'download button renders');
    ok(downloadBtn.href.includes(file3.get('url')), 'the download button url is correct');
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode);
  });

  test('clicking the close button calls closePreview with the correct url', () => {
    let closePreviewCalled = false

    const component = TestUtils.renderIntoDocument(
      <FilePreview
        isOpen={true}
        query={{
          preview: '3',
          search_term: 'web',
          sort: 'size',
          order: 'desc'
        }}
        collection={filesCollection}
        closePreview={(url) => {
          closePreviewCalled = true;
          ok(url.includes('sort=size'));
          ok(url.includes('order=desc'));
          ok(url.includes('search_term=web'));
        }}
      />
    );

    const modalPortal = component.refs.modal.portal;
    const closeButton = TestUtils.findRenderedDOMComponentWithClass(modalPortal, 'ef-file-preview-header-close');
    ok(closeButton);
    TestUtils.Simulate.click(closeButton);
    ok(closePreviewCalled);
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode);
  });
});
