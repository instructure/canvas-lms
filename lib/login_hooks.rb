# should be run before login/registration
class LoginHooks
  def self.on_login(&block)
    raise ArgumentError unless block.arity == 1
    @hooks ||= []
    @hooks << block
  end

  def self.run_hooks(request)
    (@hooks || []).each do |hook|
      hook.call(request)
    end
  end
end