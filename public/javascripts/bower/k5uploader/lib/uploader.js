define([
  './message_bus',
  './upload_result',
  './kaltura_request_builder'
], function(mBus, UploadResult, KalturaRequestBuilder){

  function Uploader (){
    this.xhr = new XMLHttpRequest();
    this.uploadResult = new UploadResult();
  }

  Uploader.prototype.isAvailable = function() {
    return !!(this.xhr.upload)
  };

  Uploader.prototype.send = function(session, file) {
    var kRequest = new KalturaRequestBuilder();
    this.xhr = kRequest.buildRequest(session, file);
    this.addEventListeners();
    this.xhr.send(kRequest.createFormData());
  };


  Uploader.prototype.addEventListeners = function() {
    this.xhr.upload.addEventListener('progress', this.eventProxy.bind(this.xhr));
    this.xhr.upload.addEventListener('load', this.eventProxy.bind(this.xhr));
    this.xhr.upload.addEventListener('error', this.eventProxy.bind(this.xhr));
    this.xhr.upload.addEventListener('abort', this.eventProxy.bind(this.xhr));
    this.xhr.onload = this.onload.bind(this)
  };

  Uploader.prototype.onload = function(event) {
    this.uploadResult.parseXML(this.xhr.response);
    var resultStatus = (this.uploadResult.isError)? 'error' : 'success';
    mBus.dispatchEvent('Uploader.' + resultStatus , this.uploadResult);
  };

  Uploader.prototype.eventProxy = function(event) {
    var name = 'Uploader.' + event.type;
    mBus.dispatchEvent(name, event, this);
  };

  return Uploader

});
