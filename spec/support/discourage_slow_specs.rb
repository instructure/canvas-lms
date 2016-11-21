# monkey patches to discourage people writing horribly slow specs

Course.prepend(Module.new {
  def enroll_user(*)
    Course.enroll_user_call_count += 1
    max_calls = 10
    return super if Course.enroll_user_call_count <= max_calls
    raise "`enroll_user` is slow; if your spec needs more than #{max_calls} enrolled users you should use `create_users_in_course` instead"
  end
})
Course.singleton_class.class_eval do
  attr_accessor :enroll_user_call_count
end

