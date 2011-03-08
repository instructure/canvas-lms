require_dependency 'urn:RespondusAPI.rb'

class RespondusAPIPort
  # SYNOPSIS
  #   IdentifyServer(userName, password, context)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   identification  C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  def identifyServer(userName, password, context)
    p [userName, password, context]
    return "Success", nil, nil, <<-INFO
Respondus Generic Server API
Contract version: 1
Implemented for: Canvas LMS
INFO
  end

  # SYNOPSIS
  #   ValidateAuth(userName, password, context, institution)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   institution     C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  def validateAuth(userName, password, context, institution)
    p [userName, password, context, institution]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   GetServerItems(userName, password, context, itemType)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemList        NVPairList - {urn:RespondusAPI}NVPairList
  #
  def getServerItems(userName, password, context, itemType)
    p [userName, password, context, itemType]
    list = NVPairList.new
    list << NVPair.new('a', 'b')
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   SelectServerItem(userName, password, context, itemType, itemID, clearState)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemID          C_String - {http://www.w3.org/2001/XMLSchema}string
  #   clearState      C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  def selectServerItem(userName, password, context, itemType, itemID, clearState)
    p [userName, password, context, itemType, itemID, clearState]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   PublishServerItem(userName, password, context, itemType, itemName, uploadType, fileName, fileData)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   uploadType      C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileData        Base64Binary - {http://www.w3.org/2001/XMLSchema}base64Binary
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemID          C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  def publishServerItem(userName, password, context, itemType, itemName, uploadType, fileName, fileData)
    p [userName, password, context, itemType, itemName, uploadType, fileName, fileData]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   DeleteServerItem(userName, password, context, itemType, itemID)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemID          C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  def deleteServerItem(userName, password, context, itemType, itemID)
    p [userName, password, context, itemType, itemID]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   ReplaceServerItem(userName, password, context, itemType, itemID, uploadType, fileName, fileData)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemID          C_String - {http://www.w3.org/2001/XMLSchema}string
  #   uploadType      C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileData        Base64Binary - {http://www.w3.org/2001/XMLSchema}base64Binary
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  def replaceServerItem(userName, password, context, itemType, itemID, uploadType, fileName, fileData)
    p [userName, password, context, itemType, itemID, uploadType, fileName, fileData]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   RetrieveServerItem(userName, password, context, itemType, itemID, retrievalType, options, downloadType)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemID          C_String - {http://www.w3.org/2001/XMLSchema}string
  #   retrievalType   C_String - {http://www.w3.org/2001/XMLSchema}string
  #   options         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   downloadType    C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileData        Base64Binary - {http://www.w3.org/2001/XMLSchema}base64Binary
  #
  def retrieveServerItem(userName, password, context, itemType, itemID, retrievalType, options, downloadType)
    p [userName, password, context, itemType, itemID, retrievalType, options, downloadType]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   AppendServerItem(userName, password, context, itemType, itemID, uploadType, fileName, fileData)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemID          C_String - {http://www.w3.org/2001/XMLSchema}string
  #   uploadType      C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileData        Base64Binary - {http://www.w3.org/2001/XMLSchema}base64Binary
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  def appendServerItem(userName, password, context, itemType, itemID, uploadType, fileName, fileData)
    p [userName, password, context, itemType, itemID, uploadType, fileName, fileData]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   GetAttachmentLink(userName, password, context, itemType, itemID, fileName, uploadType)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemID          C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   uploadType      C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   linkPath        C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  def getAttachmentLink(userName, password, context, itemType, itemID, fileName, uploadType)
    p [userName, password, context, itemType, itemID, fileName, uploadType]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   UploadAttachment(userName, password, context, itemType, itemID, fileName, fileData, overwrite)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemID          C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileData        Base64Binary - {http://www.w3.org/2001/XMLSchema}base64Binary
  #   overwrite       C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  def uploadAttachment(userName, password, context, itemType, itemID, fileName, fileData, overwrite)
    p [userName, password, context, itemType, itemID, fileName, fileData, overwrite]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   DownloadAttachment(userName, password, context, itemType, itemID, linkPath)
  #
  # ARGS
  #   userName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   password        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemType        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   itemID          C_String - {http://www.w3.org/2001/XMLSchema}string
  #   linkPath        C_String - {http://www.w3.org/2001/XMLSchema}string
  #
  # RETURNS
  #   errorStatus     C_String - {http://www.w3.org/2001/XMLSchema}string
  #   serverStatus    C_String - {http://www.w3.org/2001/XMLSchema}string
  #   context         C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileName        C_String - {http://www.w3.org/2001/XMLSchema}string
  #   fileData        Base64Binary - {http://www.w3.org/2001/XMLSchema}base64Binary
  #
  def downloadAttachment(userName, password, context, itemType, itemID, linkPath)
    p [userName, password, context, itemType, itemID, linkPath]
    raise NotImplementedError.new
  end
end

