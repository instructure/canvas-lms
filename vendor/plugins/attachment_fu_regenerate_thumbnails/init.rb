# this is based on http://blog.ninthyard.com/2008/09/changing-attachmentfu-thumbnail-sizes.html
Technoweenie::AttachmentFu::InstanceMethods.module_eval do
  def create_thumbnail_size(target_size)
    actual_size = self.attachment_options[:thumbnails][target_size]
    raise "this class doesn't have a thubnail size for #{target_size}" if actual_size.nil?
    begin
      tmp = self.create_temp_file
      res = self.create_or_update_thumbnail(tmp, target_size.to_s, actual_size)
    rescue AWS::S3::Errors::NoSuchKey => e
      logger.warn("error when trying to make thumbnail for attachment_id: #{self.id} (the image probably doesn't exist on s3) error details: #{e.inspect}")
    ensure
      tmp.unlink if tmp
    end
    
    res
  end
end
