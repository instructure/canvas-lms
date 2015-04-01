#
# Copyright (C) 2011 Instructure, Inc.
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
#

# @API Files
# @subtopic Folders
#
# @model Folder
#     {
#       "id": "Folder",
#       "description": "",
#       "properties": {
#         "context_type": {
#           "example": "Course",
#           "type": "string"
#         },
#         "context_id": {
#           "example": 1401,
#           "type": "integer"
#         },
#         "files_count": {
#           "example": 0,
#           "type": "integer"
#         },
#         "position": {
#           "example": 3,
#           "type": "integer"
#         },
#         "updated_at": {
#           "example": "2012-07-06T14:58:50Z",
#           "type": "datetime"
#         },
#         "folders_url": {
#           "example": "https://www.example.com/api/v1/folders/2937/folders",
#           "type": "string"
#         },
#         "files_url": {
#           "example": "https://www.example.com/api/v1/folders/2937/files",
#           "type": "string"
#         },
#         "full_name": {
#           "example": "course files/11folder",
#           "type": "string"
#         },
#         "lock_at": {
#           "example": "2012-07-06T14:58:50Z",
#           "type": "datetime"
#         },
#         "id": {
#           "example": 2937,
#           "type": "integer"
#         },
#         "folders_count": {
#           "example": 0,
#           "type": "integer"
#         },
#         "name": {
#           "example": "11folder",
#           "type": "string"
#         },
#         "parent_folder_id": {
#           "example": 2934,
#           "type": "integer"
#         },
#         "created_at": {
#           "example": "2012-07-06T14:58:50Z",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "type": "datetime"
#         },
#         "hidden": {
#           "example": false,
#           "type": "boolean"
#         },
#         "hidden_for_user": {
#           "example": false,
#           "type": "boolean"
#         },
#         "locked": {
#           "example": true,
#           "type": "boolean"
#         },
#         "locked_for_user": {
#           "example": false,
#           "type": "boolean"
#         }
#       }
#     }
#
class FoldersController < ApplicationController
  include Api::V1::Folders
  include Api::V1::Attachment
  include AttachmentHelper

  before_filter :require_context, :except => [:api_index, :show, :api_destroy, :update, :create, :create_file, :copy_folder, :copy_file]

  def index
    if authorized_action(@context, @current_user, :read)
      render :json => Folder.root_folders(@context).map{ |f| f.as_json(permissions: {user: @current_user, session: session}) }
    end
  end


  # @API List folders
  # @subtopic Folders
  # Returns the paginated list of folders in the folder.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/folders/<folder_id>/folders' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns [Folder]
  def api_index
    folder = Folder.find(params[:id])
    if authorized_action(folder, @current_user, :read_contents)
      can_manage_files = folder.context.grants_right?(@current_user, session, :manage_files)

      scope = folder.active_sub_folders
      unless can_manage_files
        scope = scope.not_hidden.not_locked
      end
      if params[:sort_by] == 'position'
        scope = scope.by_position
      else
        scope = scope.by_name
      end
      @folders = Api.paginate(scope, self, api_v1_list_folders_url(folder))
      render :json => folders_json(@folders, @current_user, session, :can_manage_files => can_manage_files)
    end
  end

  # @API List all folders
  # @subtopic Folders
  # Returns the paginated list of all folders for the given context. This will
  # be returned as a flat list containing all subfolders as well.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/folders' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns [Folder]
  def list_all_folders
    if authorized_action(@context, @current_user, :read)
      can_manage_files = @context.grants_right?(@current_user, session, :manage_files)

      url = named_context_url(@context, :api_v1_context_folders_url, include_host: true)

      scope = @context.active_folders
      unless can_manage_files
        scope = scope.not_hidden.not_locked
      end
      if params[:sort_by] == 'position'
        scope = scope.by_position
      else
        scope = scope.by_name
      end

      folders = Api.paginate(scope, self, url)
      render json: folders_json(folders, @current_user, session, :can_manage_files => can_manage_files)
    end
  end

  # @API Resolve path
  # @subtopic Folders
  # Given the full path to a folder, returns a list of all Folders in the path hierarchy,
  # starting at the root folder, and ending at the requested folder. The given path is
  # relative to the context's root folder and does not include the root folder's name
  # (e.g., "course files"). If an empty path is given, the context's root folder alone
  # is returned. Otherwise, if no folder exists with the given full path, a Not Found
  # error is returned.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/folders/by_path/foo/bar/baz' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns [Folder]
  def resolve_path
    if authorized_action(@context, @current_user, :read)
      can_manage_files = @context.grants_right?(@current_user, session, :manage_files)
      folders = Folder.resolve_path(@context, params[:full_path], can_manage_files)
      raise ActiveRecord::RecordNotFound if folders.blank?
      render json: folders_json(folders, @current_user, session, :can_manage_files => can_manage_files)
    end
  end

  # @API Get folder
  # @subtopic Folders
  # Returns the details for a folder
  #
  # You can get the root folder from a context by using 'root' as the :id.
  # For example, you could get the root folder for a course like:
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/courses/1337/folders/root' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/folders/<folder_id>' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns Folder
  def show
    if api_request?
      if params[:id] == 'root'
        require_context
        @folder = Folder.root_folders(@context).first
      else
        get_context
        if @context
          @folder = @context.folders.active.find(params[:id])
        else
          @folder = Folder.find(params[:id])
        end
      end
    else
      require_context
      @folder = @context.folders.find(params[:id])
    end
    raise ActiveRecord::RecordNotFound if @folder.deleted?
    if authorized_action(@folder, @current_user, :read_contents)
      if api_request?
        render :json => folder_json(@folder, @current_user, session)
      else
        respond_to do |format|
          format.html { redirect_to named_context_url(@context, :context_files_url, :folder_id => @folder.id) }
          can_manage_files = @context.grants_right?(@current_user, session, :manage_files)

          files = if can_manage_files
            @folder.active_file_attachments.by_position_then_display_name
          else
            @folder.visible_file_attachments.not_hidden.not_locked.by_position_then_display_name
          end
          files_options = {:permissions => {:user => @current_user}, :methods => [:currently_locked, :mime_class, :readable_size], :only => [:id, :comments, :content_type, :context_id, :context_type, :display_name, :folder_id, :position, :media_entry_id, :filename, :workflow_state]}
          folders_options = {:permissions => {:user => @current_user}, :methods => [:currently_locked, :mime_class], :only => [:id, :context_id, :context_type, :lock_at, :last_lock_at, :last_unlock_at, :name, :parent_folder_id, :position, :unlock_at]}
          sub_folders_scope = @folder.active_sub_folders
          unless can_manage_files
            sub_folders_scope = sub_folders_scope.not_hidden.not_locked
          end
          res = {
            :actual_folder => @folder.as_json(folders_options),
            :sub_folders => sub_folders_scope.by_position.map { |f| f.as_json(folders_options) },
            :files => files.map { |f|
              f.as_json(files_options).tap { |json|
                json['attachment'].merge! doc_preview_json(f, @current_user)
              }
            }
          }
          format.json { render :json => res }
        end
      end
    end
  end

  def download
    if authorized_action(@context, @current_user, :read)
      @folder = @context.folders.find(params[:folder_id])
      user_id = @current_user && @current_user.id

      # Destroy any previous zip downloads that might exist for this folder,
      # except the last one (cause we might be able to use it)
      folder_filename = "#{t :folder_filename, "folder"}.zip"

      @attachments = Attachment.where(context_id: @folder,
                                      context_type: @folder.class.to_s,
                                      display_name: folder_filename,
                                      user_id: user_id,
                                      workflow_state: ['to_be_zipped', 'zipping', 'zipped', 'unattached', 'errored']).
          where("file_state<>'deleted'").
          order(:created_at).to_a
      @attachment = @attachments.pop
      @attachments.each{|a| a.destroy! }
      last_date = (@folder.active_file_attachments.map(&:updated_at) + @folder.active_sub_folders.by_position.map(&:updated_at)).compact.max
      if @attachment && last_date && @attachment.created_at < last_date
        @attachment.destroy!
        @attachment = nil
      end

      if @attachment.nil?
        @attachment = @folder.file_attachments.build(:display_name => folder_filename)
        @attachment.user_id = user_id
        @attachment.workflow_state = 'to_be_zipped'
        @attachment.file_state = '0'
        @attachment.context = @folder
        @attachment.save!
        ContentZipper.send_later_enqueue_args(:process_attachment, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 }, @attachment, @current_user)
        render :json => @attachment
      else
        respond_to do |format|
          if @attachment.zipped?
            if Attachment.s3_storage?
              format.html { redirect_to @attachment.inline_url }
              format.zip { redirect_to @attachment.inline_url }
            else
              cancel_cache_buster
              format.html { send_file(@attachment.full_filename, :type => @attachment.content_type_with_encoding, :disposition => 'inline') }
              format.zip { send_file(@attachment.full_filename, :type => @attachment.content_type_with_encoding, :disposition => 'inline') }
            end
            format.json { render :json => @attachment.as_json(:methods => :readable_size) }
          else
            flash[:notice] = t :file_zip_in_process, "File zipping still in process..."
            format.html { redirect_to named_context_url(@context, :context_folder_url, @folder.id) }
            format.zip { redirect_to named_context_url(@context, :context_folder_url, @folder.id) }
            format.json { render :json => @attachment }
          end
        end
      end
    end
  end

  # @API Update folder
  # @subtopic Folders
  # Updates a folder
  #
  # @argument name [String]
  #   The new name of the folder
  #
  # @argument parent_folder_id [String]
  #   The id of the folder to move this folder into. The new folder must be in the same context as the original parent folder.
  #
  # @argument lock_at [DateTime]
  #   The datetime to lock the folder at
  #
  # @argument unlock_at [DateTime]
  #   The datetime to unlock the folder at
  #
  # @argument locked [Boolean]
  #   Flag the folder as locked
  #
  # @argument hidden [Boolean]
  #   Flag the folder as hidden
  #
  # @argument position [Integer]
  #   Set an explicit sort position for the folder
  #
  # @example_request
  #
  #   curl -XPUT 'https://<canvas>/api/v1/folders/<folder_id>' \
  #        -F 'name=<new_name>' \
  #        -F 'locked=true' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns Folder
  def update
    folder_params = process_folder_params(params, api_request?)
    if api_request?
      @folder = Folder.find(params[:id])
      @context = @folder.context
    else
      require_context
      @folder = @context.folders.find(params[:id])
    end
    if authorized_action(@folder, @current_user, :update)
      respond_to do |format|
        just_hide = folder_params.delete(:just_hide)
        if just_hide == '1'
          folder_params[:locked] = false
          folder_params[:hidden] = true
        end
        if parent_folder_id = folder_params.delete(:parent_folder_id)
          folder_params[:parent_folder] = @context.folders.active.find(parent_folder_id)
        end
        if @folder.update_attributes(folder_params)
          if !@folder.parent_folder_id || !@context.folders.where(id: @folder).first
            @folder.parent_folder = Folder.root_folders(@context).first
            @folder.save
          end
          flash[:notice] = t :event_updated, 'Event was successfully updated.'
          format.html { redirect_to named_context_url(@context, :context_files_url) }
          if api_request?
            format.json { render :json => folder_json(@folder, @current_user, session) }
          else
            format.json { render :json => @folder.as_json(:methods => [:currently_locked], :permissions => {:user => @current_user, :session => session}), :status => :ok }
          end
        else
          format.html { render :edit }
          format.json { render :json => @folder.errors, :status => :bad_request }
        end
      end
    end
  end

  # @API Create folder
  # @subtopic Folders
  # Creates a folder in the specified context
  #
  # @argument name [Required, String]
  #   The name of the folder
  #
  # @argument parent_folder_id [String]
  #   The id of the folder to store the file in. If this and parent_folder_path are sent an error will be returned. If neither is given, a default folder will be used.
  #
  # @argument parent_folder_path [String]
  #   The path of the folder to store the new folder in. The path separator is the forward slash `/`, never a back slash. The parent folder will be created if it does not already exist. This parameter only applies to new folders in a context that has folders, such as a user, a course, or a group. If this and parent_folder_id are sent an error will be returned. If neither is given, a default folder will be used.
  #
  # @argument lock_at [DateTime]
  #   The datetime to lock the folder at
  #
  # @argument unlock_at [DateTime]
  #   The datetime to unlock the folder at
  #
  # @argument locked [Boolean]
  #   Flag the folder as locked
  #
  # @argument hidden [Boolean]
  #   Flag the folder as hidden
  #
  # @argument position [Integer]
  #   Set an explicit sort position for the folder
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/folders/<folder_id>/folders' \
  #        -F 'name=<new_name>' \
  #        -F 'locked=true' \
  #        -H 'Authorization: Bearer <token>'
  #
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/folders' \
  #        -F 'name=<new_name>' \
  #        -F 'locked=true' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns Folder
  def create
    folder_params = process_folder_params(params, api_request?)
    source_folder_id = folder_params.delete(:source_folder_id)
    if folder_params[:folder_id]
      parent_folder = Folder.find(folder_params[:folder_id])
      @context = parent_folder.context
    else
      require_context
    end

    if (folder_params[:folder_id] && (folder_params[:parent_folder_path] || folder_params[:parent_folder_id])) ||
            (folder_params[:parent_folder_path] && folder_params[:parent_folder_id])
      render :json => {:message => t('only_one_folder', "Can't set folder path and folder id")}, :status => 400
      return
    elsif folder_params[:folder_id]
      folder_params.delete(:folder_id)
    elsif folder_params[:parent_folder_id]
      parent_folder = @context.folders.find(folder_params.delete(:parent_folder_id))
    elsif @context.respond_to?(:folders) && folder_params[:parent_folder_path].is_a?(String)
      root = Folder.root_folders(@context).first
      if authorized_action(root, @current_user, :create)
        parent_folder = Folder.assert_path(folder_params.delete(:parent_folder_path), @context)
      else
        return
      end
    end
    folder_params[:parent_folder] = parent_folder

    @folder = @context.folders.build(folder_params)
    if authorized_action(@folder, @current_user, :create)
      if !@folder.parent_folder_id || !@context.folders.where(id: @folder.parent_folder_id).first
        @folder.parent_folder_id = Folder.unfiled_folder(@context).id
      end
      if source_folder_id.present? && (source_folder = Folder.where(id: source_folder_id).first) && source_folder.grants_right?(@current_user, session, :read)
        @folder = source_folder.clone_for(@context, @folder, {:everything => true})
      end
      respond_to do |format|
        if @folder.save
          flash[:notice] = t :folder_created, 'Folder was successfully created.'
          format.html { redirect_to named_context_url(@context, :context_files_url) }
          if api_request?
            format.json { render :json => folder_json(@folder, @current_user, session) }
          else
            format.json { render :json => @folder.as_json(:permissions => {:user => @current_user, :session => session}) }
          end
        else
          format.html { render :new }
          format.json { render :json => @folder.errors }
        end
      end
    end
  end

  def process_folder_params(parameters, api_request)
    folder_params = (api_request ? parameters : parameters[:folder]) || {}
    folder_params.slice(:name, :parent_folder_id, :parent_folder_path, :folder_id,
                        :source_folder_id, :lock_at, :unlock_at, :locked,
                        :hidden, :context, :position, :just_hide)
  end
  private :process_folder_params

  def destroy
    @folder = Folder.find(params[:id])
    if authorized_action(@folder, @current_user, :delete)
      @folder.destroy
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_files_url) }# show.rhtml
        format.json { render :json => @folder }
      end
    end
  end

  # @API Delete folder
  # @subtopic Folders
  # Remove the specified folder. You can only delete empty folders unless you
  # set the 'force' flag
  #
  # @argument force [Boolean]
  #   Set to 'true' to allow deleting a non-empty folder
  #
  # @example_request
  #
  #   curl -XDELETE 'https://<canvas>/api/v1/folders/<folder_id>' \
  #        -H 'Authorization: Bearer <token>'
  def api_destroy
    @folder = Folder.find(params[:id])
    if authorized_action(@folder, @current_user, :delete)
      if @folder.root_folder?
        render :json => {:message => t('no_deleting_root', "Can't delete the root folder")}, :status => 400
      elsif @folder.has_contents? && params[:force] != 'true'
        render :json => {:message => t('no_deleting_folders_with_content', "Can't delete a folder with content")}, :status => 400
      else
        @context = @folder.context
        @folder.destroy
        render :json => folder_json(@folder, @current_user, session)
      end
    end
  end

  # @API Upload a file
  #
  # Upload a file to a folder.
  #
  # This API endpoint is the first step in uploading a file.
  # See the {file:file_uploads.html File Upload Documentation} for details on
  # the file upload workflow.
  #
  # Only those with the "Manage Files" permission on a course or group can
  # upload files to a folder in that course or group.
  def create_file
    @folder = Folder.find(params[:folder_id])
    params[:parent_folder_id] = @folder.id
    @context = @folder.context
    @attachment = Attachment.new(:context => @context)
    if authorized_action(@attachment, @current_user, :create)
      api_attachment_preflight(@context, request, :check_quota => true)
    end
  end

  # @API Copy a file
  #
  # Copy a file from elsewhere in Canvas into a folder.
  #
  # Copying a file across contexts (between courses and users) is permitted,
  # but the source and destination must belong to the same institution.
  #
  # @argument source_file_id [Required, String]
  #   The id of the source file
  #
  # @argument on_duplicate [Optional, String, "overwrite"|"rename"]
  #   What to do if a file with the same name already exists at the destination.
  #   If such a file exists and this parameter is not given, the call will fail.
  #
  #   "overwrite":: Replace an existing file with the same name
  #   "rename":: Add a qualifier to make the new filename unique
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/folders/123/copy_file' \
  #        -H 'Authorization: Bearer <token>'
  #        -F 'source_file_id=456'
  #
  # @returns File
  def copy_file
    unless params[:source_file_id].present?
      return render :json => {:message => "source_file_id must be provided"}, :status => :bad_request
    end
    @dest_folder = Folder.find(params[:dest_folder_id])
    @context = @dest_folder.context
    @source_file = Attachment.find(params[:source_file_id])
    unless @source_file.shard == @dest_folder.shard
      return render :json => {:message => "cannot copy across institutions"}, :status => :bad_request
    end
    if authorized_action(@source_file, @current_user, :download)
      @attachment = @context.attachments.build(folder: @dest_folder)
      if authorized_action(@attachment, @current_user, :create)
        on_duplicate = params[:on_duplicate].presence
        return render :json => {:message => "on_duplicate must be 'overwrite' or 'rename'"}, :status => :bad_request if on_duplicate && %w(overwrite rename).exclude?(on_duplicate)
        if on_duplicate.nil? && @dest_folder.active_file_attachments.where(display_name: @source_file.display_name).exists?
          return render :json => {:message => "file already exists; set on_duplicate to 'rename' or 'overwrite'"}, :status => :conflict
        end
        @attachment = @source_file.clone_for(@context, @attachment, force_copy: true)
        if @attachment.save
          # default to rename on race condition (if a file happened to be created after the check above, and on_duplicate was not given)
          @attachment.handle_duplicates(on_duplicate == 'overwrite' ? :overwrite : :rename)
          render :json => attachment_json(@attachment, @current_user, {}, { omit_verifier_in_app: true })
        else
          render :json => @attachment.errors
        end
      end
    end
  end

  # @API Copy a folder
  #
  # Copy a folder (and its contents) from elsewhere in Canvas into a folder.
  #
  # Copying a folder across contexts (between courses and users) is permitted,
  # but the source and destination must belong to the same institution.
  # If the source and destination folders are in the same context, the
  # source folder may not contain the destination folder. A folder will be
  # renamed at its destination if another folder with the same name already
  # exists.
  #
  # @argument source_folder_id [Required, String]
  #   The id of the source folder
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/folders/123/copy_folder' \
  #        -H 'Authorization: Bearer <token>'
  #        -F 'source_file_id=789'
  #
  # @returns Folder
  def copy_folder
    unless params[:source_folder_id].present?
      return render :json => {:message => "source_folder_id must be provided"}, :status => :bad_request
    end
    @dest_folder = Folder.find(params[:dest_folder_id])
    @context = @dest_folder.context
    @source_folder = Folder.find(params[:source_folder_id])
    unless @source_folder.shard == @dest_folder.shard
      return render :json => {:message => "cannot copy across institutions"}, :status => :bad_request
    end
    if @source_folder.context == @context && (@dest_folder.full_name + '/').start_with?(@source_folder.full_name + '/')
      return render :json => {:message => "source folder may not contain destination folder"}, :status => :bad_request
    end
    if authorized_action(@source_folder.context, @current_user, :manage_files)
      @folder = @context.folders.build(parent_folder: @dest_folder)
      if authorized_action(@folder, @current_user, :create)
        @folder = @source_folder.clone_for(@context, @folder, everything: true, force_copy: true)
        if @folder.save
          render :json => folder_json(@folder, @current_user, session)
        else
          render :json => @folder.errors
        end
      end
    end
  end
end
