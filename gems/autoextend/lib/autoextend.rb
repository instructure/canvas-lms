module Autoextend
  Extension = Struct.new(:module_name, :method, :block, :singleton) do
    def extend(const, from_included: false)
      target = singleton ? const.singleton_class : const
      if block
        block.call(target)
      else
        mod = if module_name.is_a?(Module)
                module_name
              else
                Object.const_get(module_name.to_s, false)
              end
        target.send(from_included ? :include : method, mod)
      end
    end
  end
  private_constant :Extension

  def self.const_added(const)
    return [] unless const.name
    extensions.fetch(const.name.to_sym, []).each do |extension|
      extension.extend(const)
    end
  end

  # Add a hook to automatically extend a class or module with a module,
  # or by calling a block, when it is extended (module or class)
  # or defined (class only).
  #
  #   Autoextend.hook(:User, :MyUserExtension)
  #
  #   Autoextend.hook(:User, :"MyUserExtension::ClassMethods", singleton: true)
  #
  #   Autoextend.hook(:User) do |klass|
  #     klass.send(:include, MyUserExtension)
  #   end
  #
  # If User is already defined, it will immediately include
  # the MyUserExtension module into it. It then sets up a hook
  # to automatically include in User if it becomes defined again
  # (like from ActiveSupport reloading).
  #
  # Note that this hook happens before any methods have been
  # added to it, so you cannot directly modify anything you
  # expect to exist in the class.
  #
  # Instead you should either use prepend with super, or
  # set up additional hooks to automatically modify methods
  # as they are added (if you use :include as your method)
  def self.hook(const_name, module_name = nil, method: :include, singleton: false, &block)
    raise ArgumentError, "block is required if module_name is not passed" if !module_name && !block
    raise ArgumentError, "cannot pass both a module_name and a block" if module_name && block

    extension = Extension.new(module_name, method, block, singleton)

    const_extensions = extensions[const_name.to_sym] ||= []
    const_extensions << extension

    # immediately extend the class if it's already defined
    if Object.const_defined?(const_name.to_s, false)
      extension.extend(Object.const_get(const_name.to_s, false))
    end
    nil
  end

  private

  def self.extensions
    @extensions ||= {}
  end
end

module Autoextend::ClassMethods
  def inherited(klass)
    Autoextend.const_added(klass)
    super
  end
end

# Note: Autoextend can't detect a module being defined,
# only when it gets included into a class.
module Autoextend::ModuleMethods
  def prepended(klass)
    Autoextend.const_added(self).each do |extension|
      extension.extend(klass, from_included: true)
    end
    super
  end

  def included(klass)
    Autoextend.const_added(self).each do |extension|
      extension.extend(klass, from_included: true)
    end
    super
  end
end

Module.prepend(Autoextend::ModuleMethods)
Class.prepend(Autoextend::ClassMethods)
