# If you set the serializer option "skip_lock_tests" to true, then this mixin
# will not add any of its fields.
module LockedSerializer
  include Canvas::LockExplanation
  extend Forwardable

  def_delegators :@controller, :course_context_modules_url,
    :course_context_module_prerequisites_needing_finishing_path

  def lock_info
    locked_for_hash
  end

  def lock_explanation
    super(lock_info, locked_for_json_type, context, include_js: false)
  end

  def locked_for_user
    !!locked_for_hash
  end

  private
  def locked_for_hash
    return @_locked_for_hash unless @_locked_for_hash.nil?
    @_locked_for_hash = (
      if scope && object.respond_to?(:locked_for?)
        context = object.try(:context)
        object.locked_for?(scope, check_policies: true, context: context)
      else
        false
      end
    )
  end

  def filter(keys)
    excluded = if serializer_option(:skip_lock_tests)
      [ :lock_info, :lock_explanation, :locked_for_user ]
    elsif !locked_for_hash
      [ :lock_info, :lock_explanation ]
    else
      []
    end

    keys - excluded
  end

end
