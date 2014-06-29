define([], function(){

  function FileFilter (params){
    this.extensions = this.parseExtensions(params.extensions);
    this.id = params.id;
    this.description = params.description;
    this.entryType = params.entryType;
    this.mediaType = params.mediaType;
    this.type = params.type;
  }

  FileFilter.prototype.parseExtensions = function(extString) {
    return extString.split(';').map(function(ext){
      return ext.substring(2);
    });
  };

  FileFilter.prototype.includesExtension = function(extension) {
    return this.extensions.indexOf(extension.toLowerCase()) !== -1;
  };

  FileFilter.prototype.toParams = function() {
    var params = {
      entry1_type: this.entryType,
      entry1_mediaType: this.mediaType,
    };

    return params;
  };

  return  FileFilter;

});
