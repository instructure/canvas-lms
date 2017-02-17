module Autoextend
  Extension = Struct.new(:const_name, :module, :method, :block, :singleton, :after_load, :optional, :used) do
    def extend(const, source: nil)
      return if after_load && source == :inherited
      self.used = true

      target = singleton ? const.singleton_class : const
      if block
        block.call(target)
      else
        mod = if self.module.is_a?(Module)
                self.module
              else
                Object.const_get(self.module.to_s, false)
              end
        real_method = method
        # if we're hooking a module, and that module was included/prepended into
        # another module/class, we also get called on that class, so that the
        # extension can also be included into it. It won't otherwise have the
        # extension, because the extension target didn't have it when it was
        # included in the class
        if [:included, :prepended].include?(source) && const.name != const_name
          real_method = :include
        end
        target.send(real_method, mod)
      end
    end
  end
  private_constant :Extension

  class << self
    def const_added(const, source:)
      const_name = const.is_a?(String) ? const : const.name
      return [] unless const_name
      extensions_hash.fetch(const_name.to_sym, []).each do |extension|
        if const == const_name
          const = Object.const_get(const_name, false)
        end
        extension.extend(const, source: source)
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
    # expect to exist in the class. If you want to do that, you can
    # specify `after_load: true`, but this will only be compatible with
    # classes loaded via ActiveSupport's autoloading.
    #
    # Instead you should either use prepend with super, or
    # set up additional hooks to automatically modify methods
    # as they are added (if you use :include as your method)
    #
    # You can make an extension optional, which is for information only,
    # so that if you have a spec that checks if all extensions were used
    # it can ignore optional extensions.
    def hook(const_name,
      module_name = nil,
      method: :include,
      singleton: false,
      after_load: false,
      optional: false,
      &block)
      raise ArgumentError, "block is required if module_name is not passed" if !module_name && !block
      raise ArgumentError, "cannot pass both a module_name and a block" if module_name && block

      extension = Extension.new(const_name, module_name, method, block, singleton, after_load, optional)

      const_extensions = extensions_hash[const_name.to_sym] ||= []
      const_extensions << extension

      # immediately extend the class if it's already defined
      if Object.const_defined?(const_name.to_s, false)
        extension.extend(Object.const_get(const_name.to_s, false))
      end
      nil
    end

    def extensions
      extensions_hash.values.flatten
    end

    private

    def extensions_hash
      @extensions ||= {}
    end
  end
end

module Autoextend::ClassMethods
  def inherited(klass)
    Autoextend.const_added(klass, source: :inherited)
    super
  end
end

# Note: Autoextend can't detect a module being defined,
# only when it gets included into a class.
module Autoextend::ModuleMethods
  def prepended(klass)
    Autoextend.const_added(self, source: :prepended).each do |extension|
      extension.extend(klass, source: :prepended)
    end
    super
  end

  def included(klass)
    Autoextend.const_added(self, source: :included).each do |extension|
      extension.extend(klass, source: :included)
    end
    super
  end
end

module Autoextend::ActiveSupport
  module Dependencies
    def notify_autoextend_of_new_constant(constant)
      Autoextend.const_added(constant, source: :'ActiveSupport::Dependencies')
      # check for nested constants
      constant.constants(false).each do |child|
        child_const = constant.const_get(child, false)
        next unless child_const.is_a?(Module)
        notify_autoextend_of_new_constant(child_const)
      end
    end

    def new_constants_in(*_descs)
      super.each do |constant_name|
        constant = Object.const_get(constant_name, false)
        next unless constant.is_a?(Module)
        notify_autoextend_of_new_constant(constant)
      end
    end

    # override this method to always track constants, even if we're requiring
    # instead of loading dependencies (i.e. eager_loading).
    # yes, this adds a minimal amount of overhead to booting in production
    # mode, but it's within a standard deviation of without it
    def require_or_load(file_name, _const_path = nil)
      return super if ActiveSupport::Dependencies.load?

      const_paths = loadable_constants_for_path(file_name)
      parent_paths = const_paths.collect { |const_path| const_path[/.*(?=::)/] || ::Object }
      result = nil
      ::ActiveSupport::Dependencies.new_constants_in(*parent_paths) { result = super }
      result
    end
  end
end

# if ActiveSupport exists, hook in to allow us to get notifications from
# all autoloaded constants
Autoextend.hook(:"ActiveSupport::Dependencies",
                Autoextend::ActiveSupport::Dependencies,
                method: :prepend)
Autoextend.hook(:"ActiveSupport::Dependencies",
                Autoextend::ActiveSupport::Dependencies,
                method: :prepend,
                singleton: true)

Module.prepend(Autoextend::ModuleMethods)
Class.prepend(Autoextend::ClassMethods)
