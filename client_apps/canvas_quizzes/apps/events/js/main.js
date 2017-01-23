define((require) => {
  const config = require('./config');
  const delegate = require('./core/delegate');
  const exports = {};

  exports.configure = delegate.configure;
  exports.mount = delegate.mount;
  exports.isMounted = delegate.isMounted;
  exports.update = delegate.update;
  exports.reload = delegate.reload;
  exports.unmount = delegate.unmount;
  exports.config = config;

  return exports;
});
