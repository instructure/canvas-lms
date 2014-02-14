define([], function(){
  function UiConfig (params){
    this.fileFilters = [];
    this.maxUploads = params.maxUploads;
    this.maxFileSize = params.maxFileSize;
    this.maxTotalSize = params.maxTotalSize;
  }

  UiConfig.prototype.addFileFilter = function(fileFilter) {
    this.fileFilters.push(fileFilter);
  };

  UiConfig.prototype.filterFor = function(fileName) {
    var filter,
        f;
    var extension = fileName.split('.').pop();
    for(var i=0, len = this.fileFilters.length; i<len; i++) {
      f = this.fileFilters[i];
      if (f.includesExtension(extension)) {
        filter = f;
        break;
      }
    }
    return filter;
  };

  UiConfig.prototype.asEntryParams = function(fileName) {
    var currentFilter = this.filterFor(fileName);
    return currentFilter.toParams();
  };

  UiConfig.prototype.acceptableFileSize = function(fileSize) {
    return (this.maxFileSize * 1024 * 1024) > fileSize
  };

  UiConfig.prototype.acceptableFileType = function(fileName, types) {
    var currentFilter = this.filterFor(fileName);
    if (!currentFilter) {
      return false;
    }
    return types.indexOf(currentFilter.id) !== -1
  };

  UiConfig.prototype.acceptableFile = function(file, types) {
    var type = this.acceptableFileType(file.name, types);
    var size = this.acceptableFileSize(file.size);
    return type && size;
  };

  return UiConfig

});
