# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require "respondus_soap_endpoint/urn_RespondusAPI"
require "benchmark"

module RespondusSoapEndpoint
  class RespondusAPIPort
    attr_reader :session, :user
    attr_accessor :rack_env

    OAUTH_TOKEN_USERNAME = "oauth_access_token"

    def request
      # we want an actual rails request because it has logic to determine the
      # remote_ip through proxies and such
      @request ||= ActionDispatch::Request.new(rack_env)
    end

    # sweet little authlogic adapter so we can play nice with authlogic
    class AuthlogicAdapter < Authlogic::ControllerAdapters::AbstractAdapter
      def authenticate_with_http_basic
        false
      end

      def params
        {}
      end

      def cookies
        {}
      end

      def cookie_domain
        "respondus (n/a)"
      end
    end

    protected

    class BadAuthError < RuntimeError; end

    class NeedDelegatedAuthError < RuntimeError; end

    class CantReplaceError < RuntimeError; end

    class OtherError < RuntimeError
      attr_reader :errorStatus

      def initialize(errorStatus, msg = nil)
        super(msg)
        @errorStatus = errorStatus
      end
    end

    def load_session(context)
      @verifier = ActiveSupport::MessageVerifier.new(
        Canvas::Security.encryption_key,
        digest: "SHA1"
      )
      @session = if context.blank?
                   {}
                 else
                   @verifier.verify(context)
                 end

      # verify that the session was created for this user
      if user
        if session["user_id"]
          raise(ActiveSupport::MessageVerifier::InvalidSignature) unless user.id == session["user_id"]
        else
          session["user_id"] = user.id
        end
      end
    end

    def dump_session
      raise("Must load session first") unless @verifier

      @verifier.generate(session)
    end

    def load_user_with_oauth(token)
      token = AccessToken.authenticate(token)
      unless token.try(:user)
        raise(BadAuthError)
      end

      token.used!
      @user = token.user
    end

    def load_user(method, userName, password)
      return nil if %w[identifyServer].include?(method.to_s)

      domain_root_account = rack_env["canvas.domain_root_account"] || Account.default
      if userName == OAUTH_TOKEN_USERNAME
        # password is the oauth token
        return load_user_with_oauth(password)
      end

      Authlogic::Session::Base.controller = AuthlogicAdapter.new(self)
      domain_root_account.pseudonyms.scoping do
        pseudonym_session = PseudonymSession.new(unique_id: userName, password:)
        pseudonym_session.remote_ip = request.remote_ip
        # don't actually want to create a session, so call `valid?` rather than `save`
        if pseudonym_session.valid?
          pseudonym = pseudonym_session.attempted_record
          @user = pseudonym.login_assertions_for_user
        elsif domain_root_account.delegated_authentication?
          raise(NeedDelegatedAuthError)
        else
          raise(BadAuthError)
        end
      end
    end

    # See the wrapping code at the bottom of this class.
    # We wrap these api calls with the code to load and dump the session to the
    # context parameter. individual api methods just need to return any response
    # params after the first three.
    def make_call(method, *args)
      # nil values come in from soap4r as Soap::Mapping::Object objects,
      # all other arguments are strings
      args = args.map { |a| a.is_a?(String) ? a : nil }
      userName, password, context, *args = args
      Rails.logger.debug "\nProcessing RespondusSoapApi##{method} (for #{rack_env["REMOTE_ADDR"]} at #{Time.now}) [SOAP]"
      log_args = args.dup
      log_args.pop if %w[publishServerItem replaceServerItem appendServerItem].include?(method.to_s)
      Rails.logger.debug "Parameters: #{([userName, "[FILTERED]", context] + log_args).inspect}"
      load_user(method, userName, password)
      load_session(context)
      return_args = send(:"_#{method}", userName, password, context, *args) || []
      ["Success", "", dump_session] + return_args
    rescue => e
      case e
      when NotImplementedError
        ["Function not implemented"]
      when BadAuthError
        ["Invalid credentials"]
      when NeedDelegatedAuthError
        ["Access token required"]
      when ActiveSupport::MessageVerifier::InvalidSignature
        ["Invalid context"]
      when CantReplaceError
        ["Item cannot be replaced"]
      when OtherError
        [e.errorStatus, ""]
      else
        Rails.logger.error "Error in Respondus API call: #{e.inspect}\n#{e.backtrace.join("\n")}"
        ["Server failure"]
      end
    end

    class << self
      protected

      def wrap_api_call(*methods)
        methods.each do |method|
          alias_method :"_#{method}", method
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{method}(userName, password, context, *args)
              ret = nil
              ms = [Benchmark.ms { ret = make_call(:#{method}, userName, password, context, *args) }, 0.01].max
              Rails.logger.debug "Completed in \#{ms}ms | \#{ret.first.inspect} [Respondus SOAP API]\\n"
              ret
            end
          RUBY
        end
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
    def identifyServer(_userName, _password, _context)
      [%(
Respondus Generic Server API
Contract version: 1
Implemented for: Canvas LMS)]
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
    def validateAuth(_userName, _password, _context, _institution)
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
    def getServerItems(_userName, _password, _context, itemType)
      selection_state = session["selection_state"] || []

      list = NVPairList.new
      case itemType
      when "discovery"
        list.item << NVPair.new("contractVersion", "1.0")
        list.item << NVPair.new("quizAreas", "course")
        list.item << NVPair.new("quizSupport", "publish,replace,randomBlocks")
        list.item << NVPair.new("quizQuestions", "multipleChoice,multipleResponse,trueFalse,essay,matchingSimple,matchingComplex,fillInBlank")
        list.item << NVPair.new("quizSettings", "publish")
        list.item << NVPair.new("qdbAreas", "course")
        list.item << NVPair.new("qdbSupport", "publish,replace")
        list.item << NVPair.new("qdbQuestions", "multipleChoice,multipleResponse,trueFalse,essay,matchingSimple,matchingComplex,fillInBlank")
        list.item << NVPair.new("qdbSettings", "")
        list.item << NVPair.new("attachmentLinking", "resolve")
        list.item << NVPair.new("uploadTypes", "zipPackage")
      when "course"
        raise(OtherError, "Item type incompatible with selection state") unless selection_state.empty?

        @user.cached_currentish_enrollments(preload_courses: true).select(&:participating_admin?).map(&:course).uniq.each do |course|
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
      raise(OtherError, "No items found") if list.item.empty? && !["quiz", "qdb"].include?(itemType)

      [list]
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
      selection_state = session["selection_state"] ||= []
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

      []
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
    def publishServerItem(_userName, _password, _context, itemType, _itemName, uploadType, fileName, fileData)
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
    def replaceServerItem(_userName, _password, _context, itemType, itemID, uploadType, fileName, fileData)
      scope = get_scope(session, itemType)
      item = scope.where(id: itemID).first
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

    wrap_api_call :identifyServer,
                  :validateAuth,
                  :getServerItems,
                  :selectServerItem,
                  :publishServerItem,
                  :deleteServerItem,
                  :replaceServerItem,
                  :retrieveServerItem,
                  :appendServerItem,
                  :getAttachmentLink,
                  :uploadAttachment,
                  :downloadAttachment

    protected

    def get_scope(session, itemType)
      selection_state = session["selection_state"] || []

      raise(OtherError, "Item type incompatible with selection state") unless selection_state.size == 1

      # selection_state comes from the session, which is safe from user modification
      course = Course.where(id: selection_state.first).first
      raise(OtherError, "Item type incompatible with selection state") unless course

      case itemType
      when "quiz" then course.quizzes.active
      when "qdb" then course.assessment_question_banks.active
      end
    end

    ASSET_TYPES = {
      "quiz" => /^quizzes:quiz_/,
      "qdb" => /^assessment_question_bank_/,
    }.freeze

    ATTACHMENT_FOLDER_NAME = "imported qti files"

    def do_import(item, itemType, uploadType, _fileName, fileData)
      if fileData == "\x0" && session["pending_migration_id"]
        return poll_for_completion
      end

      unless %w[quiz qdb].include?(itemType)
        raise OtherError, "Invalid item type"
      end
      if uploadType != "zipPackage"
        raise OtherError, "Invalid upload type"
      end

      selection_state = session["selection_state"] || []
      course = Course.where(id: selection_state.first).first
      raise(OtherError, "Item type incompatible with selection state") unless course

      # Make sure that the image import folder is hidden by default
      Folder.assert_path(ATTACHMENT_FOLDER_NAME, course) do |folder|
        folder.hidden = true
      end

      settings = {
        migration_type: "qti_converter",
        apply_respondus_settings_file: (itemType != "qdb"),
        skip_import_notification: true,
        files_import_allow_rename: true,
        files_import_root_path: ATTACHMENT_FOLDER_NAME,
        flavor: Qti::Flavors::RESPONDUS
      }

      if item
        unless item.clear_for_replacement
          raise CantReplaceError
        end

        item.save!
        case itemType
        when "quiz"
          settings[:quiz_id_to_update] = item.id
        end
      end

      migration = ContentMigration.new(context: course,
                                       user:)
      migration.update_migration_settings(settings)
      if itemType == "qdb"
        # skip creating the quiz, just import the questions into the bank
        migration.migration_ids_to_import = { copy: { all_quizzes: false, all_assessment_question_banks: true } }
      end
      migration.save!

      attachment = Attachment.new
      attachment.context = migration
      attachment.uploaded_data = StringIO.new(fileData)
      attachment.filename = "qti_import.zip"
      attachment.save!

      migration.attachment = attachment
      migration.save!
      migration.export_content

      session["pending_migration_id"] = migration.id
      session["pending_migration_itemType"] = itemType

      poll_for_completion
    end

    def poll_for_completion
      migration = ContentMigration.uncached { ContentMigration.find(session["pending_migration_id"]) }

      unless migration.complete?
        return ["pending"]
      end

      assets = migration.migration_settings[:imported_assets] || []
      a_type = ASSET_TYPES[session["pending_migration_itemType"]]
      asset = assets.find { |a| a =~ a_type }
      raise(OtherError, "Invalid file data") unless asset

      # asset is in the form "quiz_123"
      item_id = asset.split("_").last

      [item_id]
    end
  end
end
