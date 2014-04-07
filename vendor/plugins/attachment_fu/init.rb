require 'tempfile'

Tempfile.class_eval do
  # overwrite so tempfiles use the extension of the basename.  important for rmagick and image science
  alias_method :make_tmpname_original, :make_tmpname
  def make_tmpname(basename, n)
    if basename.is_a?(String)
      ext = nil
      sprintf("%s%d-%d%s", basename.to_s.gsub(/\.\w+$/) { |s| ext = s; '' }, $$, n || 0, ext)
    else
      make_tmpname_original(basename, n)
    end
  end
end

require 'geometry'
ActiveRecord::Base.send(:extend, Technoweenie::AttachmentFu::ActMethods)
Technoweenie::AttachmentFu.tempfile_path = ATTACHMENT_FU_TEMPFILE_PATH if Object.const_defined?(:ATTACHMENT_FU_TEMPFILE_PATH)
begin
  FileUtils.mkdir_p Technoweenie::AttachmentFu.tempfile_path
rescue Errno::EACCES
  # don't have permission; still let the rest of the app boot
end

$:.unshift(File.dirname(__FILE__) + '/vendor')
