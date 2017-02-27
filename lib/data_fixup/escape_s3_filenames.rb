module DataFixup::EscapeS3Filenames
  def self.run
    return unless Attachment.s3_storage?

    Attachment.class_eval do
      def copy_and_rename_with_escaping
        old_filename = filename
        new_filename = URI.escape(old_filename, /[\[\]"]/)

        Rails.logger.info "copying #{self.id} #{old_filename} to #{new_filename}"
        begin
          # Copy, not rename. For several reasons. We can clean up later.
          Attachment.bucket.object(File.join(base_path, old_filename)).copy_to(File.join(base_path, new_filename),
          :acl => attachment_options[:s3_access])

          # We're not going to call filename= here, because it will escape it again. That's right - calling
          # attachment.filename = attachment.filename is not safe. That's sucky but it's already always been
          # that way and will not be addressed by this commit.
          write_attribute(:filename, new_filename)
          save!
        rescue => e
          Rails.logger.info "  copy failed with #{e}"
        end
      end
    end

    # A more efficient query could be done using a regular expression, but this should be db agnostic
    Attachment.active.where("filename LIKE '%[%' or filename like '%]%' or filename like '%\"%'").find_in_batches do |batch|
      batch.each do |attachment|
        # Be paranoid...
        next unless attachment.filename =~ /[\[\]"]/
        attachment.copy_and_rename_with_escaping
      end
    end
  end
end