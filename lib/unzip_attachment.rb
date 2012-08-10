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

# This is used to take a zipped file, unzip it, add directories to a
# context, and attach the files in the correct directories.
class UnzipAttachment
  THINGS_TO_IGNORE_REGEX  = /^(__MACOSX|thumbs\.db|\.DS_Store)$/

  class << self
    def process(opts={})
      @ua = new(opts)
      @ua.process
      @ua
    end
  end

  attr_reader :context, :filename, :root_folders, :context_files_folder
  attr_accessor :progress_proc

  # for backwards compatibility
  def course
    self.context
  end
  def course_files_folder
    self.context_files_folder
  end

  def initialize(opts={})
    @context = opts[:course] || opts[:context]
    @filename = opts[:filename]
    # opts[:callback] is for backwards-compatibility, it's just a progress proc
    # that doesn't expect any argument giving it the percent progress
    @progress_proc = opts[:callback]
    @context_files_folder = opts[:root_directory] || Folder.root_folders(@context).first
    @valid_paths = opts[:valid_paths]
    @logger ||= opts[:logger]
    @rename_files = !!opts[:rename_files]
    @migration_id_map = opts[:migration_id_map] || {}

    raise ArgumentError, "Must provide a context." unless self.context && self.context.is_a_context?
    raise ArgumentError, "Must provide a filename." unless self.filename
    raise ArgumentError, "Must provide a context files folder." unless self.context_files_folder
  end

  def update_progress(pct)
    return unless @progress_proc
    if @progress_proc.arity == 0
      # for backwards compatibility with callback procs that expect no arguments
      @progress_proc.call()
    else
      @progress_proc.call(pct)
    end
  end

  def logger
    @logger ||= Rails.logger
  end

  # For all files in a zip file,
  # 1) create a folder in the context like the one in the zip file, if necessary
  # 2) create a unique filename to store the file
  # 3) extract the file into the unique filename
  # 4) attach the file to the context, in the appropriate folder, with a decent display name
  #
  # E.g.,
  # the zipfile has some_entry/some_file.txt
  # the context will have root_folder/some_entry added to its folder structure
  # the filesystem will get an empty file called something like:
  # /tmp/some_file.txt20091012-16997-383kbv-0
  # the contents of some_entry/some_file.txt in the zip file will be extracted to
  # /tmp/some_file.txt20091012-16997-383kbv-0
  # The context will get the contents of this file added to a new attachment called 'Some file.txt'
  # added to the root_folder/some_entry folder in the database
  # Tempfile will unlink its new file as soon as f is garbage collected.
  def process
    cnt = 0
    Attachment.skip_touch_context(true)
    Attachment.skip_scribd_submits(true)
    FileInContext.queue_files_to_delete(true)
    paths = []
    Zip::ZipFile.open(self.filename).each do |entry|
      cnt += 1
      paths << entry.name
    end
    cnt = 1 if cnt == 0
    idx = 0
    @attachments = []
    last_position = @context.attachments.active.map(&:position).compact.last || 0
    path_positions = {}
    id_positions = {}
    paths.sort.each_with_index{|p, idx| path_positions[p] = idx + last_position }
    Zip::ZipFile.open(self.filename).each do |entry|
      idx += 1
      next if entry.directory?
      next if entry.name =~ THINGS_TO_IGNORE_REGEX
      next if @valid_paths && !@valid_paths.include?(entry.name)

      list = File.split(@context_files_folder.full_name) rescue []
      list.shift if list[0] == '.'
      zip_list = File.split(entry.name)
      zip_list.shift if zip_list[0] == '.'
      filename = zip_list.pop
      list += zip_list
      folder_name = list.join('/')
      folder = Folder.assert_path(folder_name, @context)
      pct = idx.to_f / cnt.to_f
      update_progress(pct)
      # Hyphenate the path.  So, /some/file/path becomes some-file-path
      # Since Tempfile guarantees that the names are unique, we don't
      # have to worry about what this name actually is.
      f = Tempfile.new(filename)
      path = f.path
      
      begin
        entry.extract(path) { true }
        # This is where the attachment actually happens.  See file_in_context.rb
        attachment = nil
        begin
          attachment = FileInContext.attach(self.context, path, display_name(entry.name), folder, File.split(entry.name).last, @rename_files)
        rescue
          attachment = FileInContext.attach(self.context, path, display_name(entry.name), folder, File.split(entry.name).last, @rename_files)
        end
        id_positions[attachment.id] = path_positions[entry.name]
        if migration_id = @migration_id_map[entry.name]
          attachment.update_attribute(:migration_id, migration_id)
        end
        @attachments << attachment if attachment
      rescue => e
        @logger.warn "Couldn't unzip archived file #{path}: #{e.message}" if @logger
      ensure
        f.close
      end
    end
    updates = []
    id_positions.each do |id, position|
      updates << "WHEN id=#{id} THEN #{position}" if id && position
    end
    Attachment.connection.execute("UPDATE attachments SET position=CASE #{updates.join(" ")} ELSE position END WHERE id IN (#{id_positions.keys.join(",")})") unless updates.empty?
    Attachment.skip_touch_context(false)
    Attachment.skip_scribd_submits(false)
    FileInContext.queue_files_to_delete(false)
    FileInContext.destroy_queued_files
    scribdable_attachments = @attachments.select {|a| a.scribdable? }
    unless scribdable_attachments.blank?
      Attachment.send_later_enqueue_args(:submit_to_scribd, { :strand => 'scribd', :max_attempts => 1 }, scribdable_attachments.map(&:id))
    end
    @context.touch
    update_progress(1.0)
  end

  protected

    # Creates a title-ized name from a path.
    # So, display_name(/tmp/foo/bar_baz) generates 'Bar baz'
    def display_name(path)
      display_name = File.split(path).last
    end

    # Finds the folder in the database, creating the path if necessary
    def infer_folder(path)
      list = path.split('/')
      current = (@root_directory ||= folders.root_directory)
      # For every directory in the path...
      # (-2 means all entries but the last, which should be a filename)
      list[0..-2].each do |dir|
        if new_dir = current.sub_folders.find_by_name(dir)
          current = new_dir
        else
          current = assert_folder(current, dir)
        end
      end
      current
    end

    # Actually creates the folder in the database.
    def assert_folder(root, dir)
      folder = Folder.new(:parent_folder_id => root.id, :name => dir)
      folder.context = self.context
      folder.save!
      folder
    end

    # A cached list of folders that we know about.
    # Used by infer_folder to know whether to create a folder or not.
    def folders(reset=false)
      @folders = nil if reset
      return @folders if @folders
      root_folders = Folder.root_folders(self.context)
      @folders = OpenStruct.new(:root_directory => self.context_files_folder)
    end
end
