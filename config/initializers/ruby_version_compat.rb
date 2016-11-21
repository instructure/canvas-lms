# This makes it so all parameters get converted to UTF-8 before they hit your
# app.  If someone sends invalid UTF-8 to your server, raise an exception.
class ActionController::InvalidByteSequenceErrorFromParams < Encoding::InvalidByteSequenceError; end
class ActionController::Base
  def force_utf8_params
    traverse = lambda do |object, block|
      if object.kind_of?(Hash)
        object.each_value { |o| traverse.call(o, block) }
      elsif object.kind_of?(Array)
        object.each { |o| traverse.call(o, block) }
      else
        block.call(object)
      end
      object
    end
    force_encoding = lambda do |o|
      if o.respond_to?(:force_encoding)
        o.force_encoding(Encoding::UTF_8)
        raise ActionController::InvalidByteSequenceErrorFromParams unless o.valid_encoding?
      end
      if o.respond_to?(:original_filename) && o.original_filename
        o.original_filename.force_encoding(Encoding::UTF_8)
        raise ActionController::InvalidByteSequenceErrorFromParams unless o.original_filename.valid_encoding?
      end
    end
    traverse.call(params, force_encoding)
    path_str = request.path.to_s
    if path_str.respond_to?(:force_encoding)
      path_str.force_encoding(Encoding::UTF_8)
      raise ActionController::InvalidByteSequenceErrorFromParams unless path_str.valid_encoding?
    end
  end
  before_filter :force_utf8_params
end

module ActiveRecord::Coders
  Utf8SafeYAMLColumn = YAMLColumn
end
