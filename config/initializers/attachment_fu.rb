Technoweenie::AttachmentFu::InstanceMethods.module_eval do
  require 'rack'
  
  # Overriding this method to allow content_type to be detected when
  # swfupload submits images with content_type set to 'application/octet-stream'
  alias_method :original_uploaded_data=, :uploaded_data=
  def uploaded_data=(file_data)
    if self.is_a?(Attachment)
      return nil if file_data.nil? || (file_data.respond_to?(:size) && file_data.size == 0)
      # glean information from the file handle
      self.content_type = detect_mimetype(file_data) rescue 'unknown/unknown'
      self.filename     = file_data.original_filename if respond_to?(:filename) && file_data.respond_to?(:original_filename)
      file_from_path = true
      unless file_data.respond_to?(:path)
        file_data.rewind
        self.temp_data = file_data.read
        file_from_path = false
      else
        self.temp_paths.unshift file_data
      end
      # If we're overwriting an existing file, we need to take serious
      # precautions, since other Attachment records could be using this file.
      # We first remove any root references for this file, and then we generate
      # a new unique filename for this file so anybody children of this attachment
      # will still be able to get at the original.
      if !self.new_record?
        self.root_attachment = nil
        self.root_attachment_id = nil
        self.scribd_mime_type_id = nil
        self.scribd_user = nil
        self.submitted_to_scribd_at = nil
        self.workflow_state = nil
        self.scribd_doc = nil
        self.filename = filename.sub(/\A\d+_\d+__/, "")
        self.filename = "#{Time.now.to_i}_#{rand(999)}__#{self.filename}" if self.filename
      end
      read_bytes = false
      digest = Digest::MD5.new
      begin
        io = file_data
        if file_from_path
          io = File.open(self.temp_path, 'rb')
        end
        io.rewind
        io.each_line do |line| 
          digest.update(line)
          read_bytes = true
        end
      rescue => e
      end
      self.md5 = read_bytes ? digest.hexdigest : nil
      if self.md5 && ns = self.infer_namespace
        if existing_attachment = Attachment.find_all_by_md5_and_namespace(self.md5, ns).detect{|a| (self.new_record? || a.id != self.id) && !a.root_attachment_id && a.content_type == self.content_type }
          self.temp_path = nil if respond_to?(:temp_path=)
          self.temp_data = nil if respond_to?(:temp_data=)
          write_attribute(:filename, nil) if respond_to?(:filename=)
          self.root_attachment = existing_attachment
        end
      end
      file_data
    else
      original_uploaded_data=(file_data)
    end
  end
  
  # this is the original method
  # def uploaded_data=(file_data)
  #   if file_data.respond_to?(:content_type)
  #     return nil if file_data.size == 0
  #     self.content_type = file_data.content_type
  #     self.filename     = file_data.original_filename if respond_to?(:filename)
  #   else
  #     return nil if file_data.blank? || file_data['size'] == 0
  #     self.content_type = file_data['content_type']
  #     self.filename =  file_data['filename']
  #     file_data = file_data['tempfile']
  #   end
  #   if file_data.is_a?(StringIO)
  #     file_data.rewind
  #     set_temp_data file_data.read
  #   else
  #     self.temp_paths.unshift file_data
  #   end
  # end
  # 
  
  alias_method :original_save_attachment?, :save_attachment? 
  def save_attachment?
    if self.is_a?(Attachment)
      if self.root_attachment_id && self.new_record?
        return false
      end
      self.filename && File.file?(temp_path.to_s)
    else
      # do the default attachment_fu thing
      original_save_attachment?
    end
  end
  
  # def attachment_path_id
    # a = (self.respond_to?(:root_attachment) && self.root_attachment) || self
    # ((a.respond_to?(:parent_id) && a.parent_id) || a.id).to_s
  # end
  
  def detect_mimetype(file_data)
    if file_data && file_data.respond_to?(:content_type) && (!file_data.content_type || file_data.content_type.strip == "application/octet-stream")
      res = nil
      res = File.mime_type?(file_data.original_filename) if !res || res == 'unknown/unknown'
      res = File.mime_type?(file_data) if !res || res == 'unknown/unknown'
      res = "text/plain" if file_data.is_a?(StringIO) && res == 'unknown/unknown'
      # if res == 'unknown/unknown'
        # require 'mime/types'
        # res = MIME::Types.type_for(file_data.original_filename)[0].to_s
      # end
      res
      # return File.mime_typMIME::Types.type_for(file_data.original_filename)[0].to_s
    elsif file_data.respond_to?(:content_type)
      return file_data.content_type
    else
      'unknown/unknown'
    end
  end
end
