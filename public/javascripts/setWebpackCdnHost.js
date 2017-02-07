// this is the first module loaded by webpack (in the vendor bundle). It tells it
// to load chunks from the CDN url configured in config/canvas_cdn.yml
__webpack_public_path__ = (window.ENV && window.ENV.ASSET_HOST || '') + require('../../frontend_build/webpackPublicPath')
