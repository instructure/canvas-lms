sinon.fakeServer.respond = (function () {
  var request,
      queue = this.queue || [],
      args = Array.prototype.slice.call(arguments),
      options = {};

  if (args.length > 0 && typeof args[0] == "object") {
    options = args.splice(0, 1)[0];
  }

  if (args.length > 0) this.respondWith.apply(this, args);

  if (options.cascade === false) {
    queue = this.queue.splice(0, queue.length);
  }

  while(request = queue.shift()) {
    this.processRequest(request);
  }
});
