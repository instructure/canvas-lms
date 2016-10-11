module Factories
  def custom_role(base, name, opts={})
    account = opts[:account] || @account
    role = account.roles.where(name: name).first_or_initialize
    role.base_role_type = base
    role.save!
    role
  end

  def custom_student_role(name, opts={})
    custom_role('StudentEnrollment', name, opts)
  end

  def custom_teacher_role(name, opts={})
    custom_role('TeacherEnrollment', name, opts)
  end

  def custom_ta_role(name, opts={})
    custom_role('TaEnrollment', name, opts)
  end

  def custom_designer_role(name, opts={})
    custom_role('DesignerEnrollment', name, opts)
  end

  def custom_observer_role(name, opts={})
    custom_role('ObserverEnrollment', name, opts)
  end

  def custom_account_role(name, opts={})
    custom_role(Role::DEFAULT_ACCOUNT_TYPE, name, opts)
  end

  def student_role
    Role.get_built_in_role("StudentEnrollment")
  end

  def teacher_role
    Role.get_built_in_role("TeacherEnrollment")
  end

  def ta_role
    Role.get_built_in_role("TaEnrollment")
  end

  def designer_role
    Role.get_built_in_role("DesignerEnrollment")
  end

  def observer_role
    Role.get_built_in_role("ObserverEnrollment")
  end

  def admin_role
    Role.get_built_in_role("AccountAdmin")
  end
end
