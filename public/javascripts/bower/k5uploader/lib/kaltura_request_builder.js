import signatureBuilder from "./signature_builder";
import urlParams from "./url_params";
import k5Options from "./k5_options";


function KalturaRequestBuilder (){
  this.settings,
  this.file;
  this.xhr;
}

KalturaRequestBuilder.id = 1;

KalturaRequestBuilder.prototype.createRequest = function() {
  var xhr = new XMLHttpRequest();
  xhr.open("POST", this.createUrl());
  xhr.responseType = 'xml'
  return xhr;
};

KalturaRequestBuilder.prototype.createFormData = function() {
  var formData = new FormData();
  formData.append('Filename', this.file.name);
  formData.append('Filedata', this.file);
  formData.append('Upload', 'Submit Query');
  return formData;
};

KalturaRequestBuilder.prototype.createFileId = function() {
  KalturaRequestBuilder.id += 1;
  return Date.now().toString() + KalturaRequestBuilder.id.toString();
};

// flash uploader sends these as GET query params
// and file data as POST
KalturaRequestBuilder.prototype.createUrl = function() {
  var config = this.settings.getSession();
  config.filename = this.createFileId();
  config.kalsig = this.createSignature();
  return k5Options.uploadUrl + urlParams(config);
};

KalturaRequestBuilder.prototype.createSignature = function() {
  return signatureBuilder(this.settings.getSession());
};

KalturaRequestBuilder.prototype.buildRequest = function(settings, file) {
  this.settings = settings;
  this.file = file;
  return this.createRequest();
};


KalturaRequestBuilder.prototype.getFile = function() {
  return this.file;
};

KalturaRequestBuilder.prototype.getSettings = function() {
  return this.settings;
};

export default KalturaRequestBuilder;
