define(['./xml_parser'], function(XmlParser){

  function UploadResult (){
    this.xml = undefined;
    this.isError = true;
    this.token = undefined;
    this.filename = '';
    this.fileId = -1;
    this.xmlParser = new XmlParser();
  }

  UploadResult.prototype.parseXML = function(xml) {
    var $xml = this.xmlParser.parseXML(xml);
    this.isError = this.xmlParser.isError;
    if (!this.xmlParser.isError) {
      this.pullData();
    }
  };

  UploadResult.prototype.pullData = function() {
    var $resultOk = this.xmlParser.find('result_ok');
    this.token = this.xmlParser.nodeText('token', $resultOk, true);
    this.fileId = this.xmlParser.nodeText('filename', $resultOk, true);
    this.filename = this.xmlParser.nodeText('origFilename', $resultOk);
  };

  UploadResult.prototype.asEntryParams = function() {
    return {
      entry1_name: this.filename,
      entry1_filename: this.fileId,
      entry1_realFilename: this.filename
    }
  };

  return UploadResult

});
