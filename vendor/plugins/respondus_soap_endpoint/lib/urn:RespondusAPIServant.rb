require_dependency 'urn:RespondusAPI.rb'
require 'benchmark'

class RespondusAPIPort
  attr_reader :session, :user
  attr_accessor :rack_env

  protected

  class BadAuthError < Exception; end
  class CantReplaceError < Exception; end
  class OtherError < Exception
    attr_reader :errorStatus
    def initialize(errorStatus, msg = nil)
      super(msg)
      @errorStatus = errorStatus
    end
  end

  def load_session(context)
    @verifier = ActiveSupport::MessageVerifier.new(
      Canvas::Security.encryption_key,
      'SHA1')
    if context.blank?
      @session = {}
    else
      @session = @verifier.verify(context)
    end

    # verify that the session was created for this user
    if self.user
      if session['user_id']
        raise(ActiveSupport::MessageVerifier::InvalidSignature) unless self.user.id == session['user_id']
      else
        session['user_id'] = self.user.id
      end
    end
  end

  def dump_session
    raise("Must load session first") unless @verifier
    @verifier.generate(session)
  end

  def load_user(method, userName, password)
    return nil if %w(identifyServer).include?(method.to_s)
    domain_root_account = rack_env['canvas.domain_root_account'] || Account.default
    scope = domain_root_account.require_account_pseudonym? ?
      domain_root_account.pseudonyms :
      Pseudonym
    pseudonym = scope.find_by_unique_id(userName) || raise(BadAuthError)
    raise(BadAuthError) unless pseudonym.valid_arbitrary_credentials?(password)
    @user = pseudonym.user
  end

  # See the wrapping code at the bottom of this class.
  # We wrap these api calls with the code to load and dump the session to the
  # context parameter. individual api methods just need to return any response
  # params after the first three.
  def make_call(method, userName, password, context, *args)
    Rails.logger.debug "\nProcessing RespondusSoapApi##{method} (for #{rack_env['REMOTE_ADDR']} at #{Time.now}) [SOAP]"
    log_args = args.dup
    log_args.pop if %w(publishServerItem replaceServerItem appendServerItem).include?(method.to_s)
    Rails.logger.debug "Parameters: #{([userName, "[FILTERED]", context] + log_args).inspect}"
    load_user(method, userName, password)
    load_session(context)
    return_args = send("_#{method}", userName, password, context, *args) || []
    ["Success", '', dump_session] + return_args
  rescue Exception => ex
    case ex
    when NotImplementedError
      ["Function not implemented"]
    when BadAuthError
      ["Invalid credentials"]
    when ActiveSupport::MessageVerifier::InvalidSignature
      ["Invalid context"]
    when CantReplaceError
      ["Item cannot be replaced"]
    when OtherError
      [ex.errorStatus, '']
    else
      Rails.logger.error "Error in Respondus API call: #{ex.inspect}\n#{ex.backtrace.join("\n")}"
      ["Server failure"]
    end
  end

  def self.wrap_api_call(*methods)
    methods.each do |method|
      alias_method "_#{method}", method
      class_eval(<<-METHOD, __FILE__, __LINE__+1)
        def #{method}(userName, password, context, *args)
          ret = nil
          ms = [Benchmark.ms { ret = make_call(:#{method}, userName, password, context, *args) }, 0.01].max
          Rails.logger.debug "Completed in \#{ms}ms | \#{ret.first.inspect} [Respondus SOAP API]\\n"
          ret
        end
      METHOD
    end
  end

  public

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
    return [%{
Respondus Generic Server API
Contract version: 1
Implemented for: Canvas LMS}]
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
    # The validation happens in load_user
    []
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
    selection_state = session['selection_state'] || []

    list = NVPairList.new
    case itemType
    when "discovery"
      list.item << NVPair.new("contractVersion", "1.0")
      list.item << NVPair.new("quizAreas", "course")
      list.item << NVPair.new("quizSupport", "publish,replace,randomBlocks")
      list.item << NVPair.new("quizQuestions", "multipleChoice,multipleResponse,trueFalse,essay,matchingSimple,matchingComplex,fillInBlank")
      list.item << NVPair.new("quizSettings", "")
      list.item << NVPair.new("qdbAreas", "course")
      list.item << NVPair.new("qdbSupport", "publish,replace")
      list.item << NVPair.new("qdbQuestions", "multipleChoice,multipleResponse,trueFalse,essay,matchingSimple,matchingComplex,fillInBlank")
      list.item << NVPair.new("qdbSettings", "")
      list.item << NVPair.new("attachmentLinking", "resolve")
      list.item << NVPair.new("uploadTypes", "zipPackage")
    when "course"
      raise(OtherError, 'Item type incompatible with selection state') unless selection_state.empty?
      @user.cached_current_enrollments.select { |e| e.participating_admin? }.map(&:course).uniq.each do |course|
        list.item << NVPair.new(course.name, course.to_param)
      end
    when "quiz", "qdb"
      coll = get_scope(session, itemType)
      coll.each do |item|
        list.item << NVPair.new(item.title, item.to_param)
      end
    else
      raise OtherError, "Invalid item type"
    end
    raise(OtherError, "No items found") if list.item.empty?
    return [list]
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
    selection_state = session['selection_state'] ||= []
    if clearState == "true"
      selection_state.clear
    end
    if itemType == "none"
      return []
    end

    # call the unwrapped version of getServerItem
    list, _ = _getServerItems(userName, password, context, itemType)

    case itemType
    when "course", "content"
      if list.item.find { |i| i.value == itemID }
        selection_state << itemID
      else
        raise OtherError, "Invalid item identifier"
      end
    else
      raise OtherError, "Invalid item type"
    end

    return []
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
    do_import(nil, itemType, uploadType, fileName, fileData)
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
    raise NotImplementedError
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
    scope = get_scope(session, itemType)
    item = scope.find_by_id(itemID)
    raise(CantReplaceError) unless item
    do_import(item, itemType, uploadType, fileName, fileData)
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
    raise NotImplementedError
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
    raise NotImplementedError
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
    raise NotImplementedError
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
    raise NotImplementedError
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
    raise NotImplementedError
  end

  wrap_api_call :identifyServer, :validateAuth, :getServerItems,
    :selectServerItem, :publishServerItem, :deleteServerItem,
    :replaceServerItem, :retrieveServerItem, :appendServerItem,
    :getAttachmentLink, :uploadAttachment, :downloadAttachment

  protected

  def get_scope(session, itemType)
    selection_state = session['selection_state'] || []

    raise(OtherError, 'Item type incompatible with selection state') unless selection_state.size == 1
    # selection_state comes from the session, which is safe from user modification
    course = Course.find_by_id(selection_state.first)
    raise(OtherError, 'Item type incompatible with selection state') unless course

    case itemType
    when "quiz"; course.quizzes.active
    when "qdb"; course.assessment_question_banks.active
    end
  end

  ASSET_TYPES = {
    'quiz' => /^quiz_/,
    'qdb' => /^assessment_question_bank_/,
  }

  def do_import(item, itemType, uploadType, fileName, fileData)
    unless %w(quiz qdb).include?(itemType)
      raise OtherError, "Invalid item type"
    end
    if uploadType != 'zipPackage'
      raise OtherError, "Invalid upload type"
    end

    selection_state = session['selection_state'] || []
    course = Course.find_by_id(selection_state.first)
    raise(OtherError, 'Item type incompatible with selection state') unless course

    settings = { :migration_type => 'qti_exporter' }

    if item
      if !item.clear_for_replacement
        raise CantReplaceError
      end
      item.save!
      case itemType
      when 'quiz'
        settings[:quiz_id_to_update] = item.id
      end
    end

    migration = ContentMigration.new(:context => course,
                                     :user => user)
    migration.update_migration_settings(settings)
    if itemType == 'qdb'
      # skip creating the quiz, just import the questions into the bank
      migration.migration_ids_to_import = { :copy => { :quizzes => {} } }
    end
    migration.save!

    attachment = Attachment.new
    attachment.context = migration
    attachment.uploaded_data = StringIO.new(fileData)
    attachment.filename = "qti_import.zip"
    attachment.save!

    migration.attachment = attachment
    migration.export_content

    # This is a sad excuse for a notification system, but we're just going to
    # check the migration every couple seconds, see if it's done.
    timeout(5.minutes.to_i) do
      while %w[pre_processing exporting exported importing].include?(migration.workflow_state)
        sleep(Setting.get_cached('respondus_endpoint.polling_time', '2').to_f)
        ContentMigration.uncached { migration.reload }
      end
    end

    assets = migration.migration_settings[:imported_assets]
    a_type = ASSET_TYPES[itemType]
    asset = assets.find { |a| a =~ a_type }
    raise(OtherError, "Invalid file data") unless asset

    # asset is in the form "quiz_123"
    item_id = asset.split("_").last

    [ item_id ]
  end
end
