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
    @_locked_for_hash ||= (
      return nil unless scope && object.respond_to?(:locked_for?)
      context = object.try(:context)
      object.locked_for?(scope, check_policies: true, context: context)
    )
  end

  def filter(keys)
    locked_for_hash ? keys : keys - [:lock_info, :lock_explanation]
  end

end
