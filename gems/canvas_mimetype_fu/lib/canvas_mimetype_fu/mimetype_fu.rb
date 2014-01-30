class File

  def self.mime_type?(file)
     # INSTRUCTURE: added condition, file.class can also be Tempfile
     if file.class == File || file.class == Tempfile
       unless RUBY_PLATFORM.include? 'mswin32'
        # INSTRUCTURE: added double-quotes around the file path to prevent error on file paths with spaces in them
         mime = `file --mime -br "#{file.path}"`.strip
       else
         mime = extensions[File.extname(file.path).gsub('.','').downcase] rescue nil
       end
     elsif file.class == String
       mime = extensions[(file[file.rindex('.')+1, file.size]).downcase] rescue nil
     elsif file.respond_to?(:string)
       temp = File.open(Dir.tmpdir + '/upload_file.' + Process.pid.to_s, "wb")
       temp << file.string
       temp.close
       # INSTRUCTURE: added double-quotes around the file path to prevent error on file paths with spaces in them
       mime = `file --mime -br "#{temp.path}"`.strip
       mime = mime.gsub(/^.*: */,"")
       mime = mime.gsub(/;.*$/,"")
       mime = mime.gsub(/,.*$/,"")
       File.delete(temp.path)
     end

    mime = mime && mime.split(";").first
    mime = nil unless mime_types[mime]
     
     if mime
       return mime
     else
       'unknown/unknown'
     end
   end

   def self.mime_types
    extensions.invert
   end

  private
  
  def self.extensions
    ::MimetypeFu::EXTENSIONS
  end
  
end
