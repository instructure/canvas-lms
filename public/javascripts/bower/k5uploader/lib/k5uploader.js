define([
  './uploader',
  './session_manager',
  './kaltura_session',
  './message_bus',
  './messenger',
  './entry_service',
  './uiconf_service',
  './k5_options'
], function(Uploader,
            SessionManager,
            KalturaSession,
            mBus,
            Messenger,
            EntryService,
            UiconfService,
            k5Options){

  function K5Uploader (options){
    // set up instance as an event dispatcher
    Messenger.decorate(this);

    k5Options.setOptions(options);
    this.buildDependencies();
    this.addListeners();
    this.session.setSession(options.kaltura_session);
    this.loadUiConf();
  }

  K5Uploader.prototype.destroy = function() {
    mBus.destroy();
    this.session = undefined;
    this.entryService = undefined;
    this.uiconfService = undefined;
  };

  K5Uploader.prototype.buildDependencies = function() {
    this.session = new KalturaSession();
    this.entryService = new EntryService();
    this.uiconfService = new UiconfService();
  };

  K5Uploader.prototype.addListeners = function() {
    mBus.addEventListener('UiConf.error', this.onUiConfError.bind(this));
    mBus.addEventListener('UiConf.complete', this.onUiConfComplete.bind(this));
    mBus.addEventListener('Uploader.error', this.onUploadError.bind(this));
    mBus.addEventListener('Uploader.success', this.onUploadSuccess.bind(this));
    mBus.addEventListener('Uploader.progress', this.onProgress.bind(this));

    mBus.addEventListener('Entry.success', this.onEntrySuccess.bind(this));
    mBus.addEventListener('Entry.fail', this.onEntryFail.bind(this));
  };

  K5Uploader.prototype.onSessionLoaded = function(data) {
    this.session = data;
    this.loadUiConf();
  };

  K5Uploader.prototype.loadUiConf = function() {
    this.uiconfService.load(this.session);
  };

  K5Uploader.prototype.onUiConfComplete = function(result) {
    this.uiconfig = result;
    this.dispatchEvent("K5.ready", {}, this);
  };

  K5Uploader.prototype.uploadFile = function(file) {
    this.file = file;
    if (!file) {
      return
    }
    if (this.uiconfig.acceptableFile(file, k5Options.allowedMediaTypes)) {
      this.uploader = new Uploader();
      this.uploader.send(this.session, file);
    } else {
      var details = {
        maxFileSize: this.uiconfig.maxFileSize,
        file: file,
        allowedMediaTypes: k5Options.allowedMediaTypes
      };
      this.dispatchEvent("K5.fileError", details, this);
    }
  };

  K5Uploader.prototype.onUploadSuccess = function(result) {
    // combine all needed data and add an entry to kaltura
    var allParams = [
      this.uiconfig.asEntryParams(this.file.name),
      this.session.asEntryParams(),
      result.asEntryParams(),
      k5Options.asEntryParams()
    ];
    this.entryService.addEntry(allParams);
  };

  // Delegate to publicly available K5 events
  K5Uploader.prototype.onProgress = function(e) {
    this.dispatchEvent('K5.progress', e, this);
  };

  K5Uploader.prototype.onUploadError = function(result) {
    this.dispatchEvent('K5.error', result, this);
  };

  K5Uploader.prototype.onEntrySuccess = function(data) {
    this.dispatchEvent('K5.complete', data, this);
  };

  K5Uploader.prototype.onEntryFail = function(data) {
    this.dispatchEvent('K5.error', data, this);
  };

  K5Uploader.prototype.onUiConfError = function(result) {
    this.dispatchEvent('K5.uiconfError', result, this);
  };

  return  K5Uploader;

});
