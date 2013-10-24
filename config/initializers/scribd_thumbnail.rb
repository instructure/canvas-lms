require 'uri'
require 'open-uri'

ScribdAPI.initialize

module Scribd
  class Document
    
    # thumbnail.get
    # This method retrieves a URL to the thumbnail of a document, in a given size, and for any page in that document. Note that docs.getSettings and docs.getList also retrieve thumbnail URLs in default size - this method is really for resizing those. IMPORTANT - it is possible that at some time in the future, Scribd will redesign its image system, invalidating these URLs. So if you cache them, please have an update strategy in place so that you can update them if neceessary.
    # 
    # Parameters
    # integer doc_id   (required) The ID of the document. It must be a public document, or one that your account controls.
    # integer width  (optional) Width in px of the desired image. If not included, will use the default thumb size.
    # integer height   (optional) Height in px of the desired image. If not included, will use the default thumb size.
    # integer page   (optional) Page to generate a thumbnail of. Defaults to 1.
    # string  api_key  (required) API key assigned to your account.
    # string  api_sig  (optional) MD5 hash of the active request and your secret key. This is an optional security measure. See the signing documentation for more info.
    # string  session_key  (optional) A session key for a signed in user. If this parameter is provided, your application will carry out actions on behalf of the signed in user corresponding to the session key. Otherwise, your application will carry out actions on behalf of the user account associated with the API account. See the authentication documentation for more information
    # string  my_user_id   (optional) This parameter is intended for sites with their own user authentication system. You can create phantom Scribd accounts that correspond to your users by simply passing the unique identifier you use to identify your own user accounts to my_user_id. If you pass this parameter to an API method, the API will act as if it were executed by the phantom user corresponding to my_user_id. See the authentication documentation for more information.
    # Sample return XML
    #     <?xml version="1.0" encoding="UTF-8"?>
    #     <rsp stat="ok">
    #       <thumbnail_url>http://imgv2-2.scribdassets.com/img/word_document/1/111x142/ff94c77a69/1277782307</thumbnail_url>
    #     </rsp>
    # Result explanation
    # string  thumbnail_url  URL to thumbnail
    # Error codes
    # 401 Unauthorized
    # 500 Internal Server Error. Scribd has been notified about this problem.
    # 601 Required parameter missing
    # 611 Insufficient permissions to access this document
    # 612 Document could not be found
    # 655 Must pass either both width and height, or neither (for default size)
    # 656 Invalid parameter value for width or height
    # 657 Invalid page value
    def thumbnail(options = {})
      params = {:doc_id => self.id}
      [:width, :height, :page].each do |param|
        params[param] = options[param] if options.has_key? param 
      end
      response = API.instance.send_request('thumbnail.get', params)
      response.elements['/rsp/thumbnail_url'].text      
    end
  end
end
