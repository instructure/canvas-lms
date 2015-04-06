module Autoextend
  Extension = Struct.new(:module_name, :method, :block) do
    def extend(klass)
      if block
        block.call(klass)
      else
        klass.send(method, Object.const_get(module_name.to_s, false))
      end
    end
  end

  def self.extensions
    @extensions ||= Hash.new
  end

  MethodExtension = Struct.new(:target, :feature) do
    # based off ActiveSupport's alias_method_chain
    def extend(klass)
      return if klass.instance_variable_get(:@autoextending)
      begin
        klass.instance_variable_set(:@autoextending, true)

        # Strip out punctuation on predicates, bang or writer methods since
        # e.g. target?_without_feature is not a valid method name.
        aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1

        with_method = "#{aliased_target}_with_#{feature}#{punctuation}"
        without_method = "#{aliased_target}_without_#{feature}#{punctuation}"

        # make sure we're not inserting ourselves multiples times (could be
        # caused by someone else doing an alias_method_chain)
        return if klass.method_defined?(without_method)

        klass.send(:alias_method, without_method, target)
        klass.send(:alias_method, target, with_method)

        case
          when klass.public_method_defined?(without_method)
            klass.send(:public, target)
          when klass.protected_method_defined?(without_method)
            klass.send(:protected, target)
          when klass.private_method_defined?(without_method)
            klass.send(:private, target)
        end
      ensure
        klass.instance_variable_set(:@autoextending, false)
      end
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def singleton_method_added(method)
      singleton_autoextensions.fetch(method, []).each do |extension|
        extension.extend(self.singleton_class)
      end
      super
    end

    def method_added(method)
      autoextensions.fetch(method, []).each do |extension|
        extension.extend(self)
      end
      super
    end

    def autoextensions
      @autoextensions ||= Hash.new
    end

    def singleton_autoextensions
      @autoextensions ||= Hash.new
    end

    def autoextend_singleton(method, feature)
      extension = autoextend_method(method, feature, singleton_autoextensions)
      if singleton_class.method_defined?(method)
        extension.extend(singleton_class)
      end
    end

    def autoextend(method, feature)
      extension = autoextend_method(method, feature, autoextensions)
      if method_defined?(method)
        extension.extend(self)
      end
    end

    private
    def autoextend_method(method, feature, extensions)
      method_extensions = (extensions[method] ||= [])
      method_extensions << (extension = MethodExtension.new(method, feature))
      extension
    end
  end
end

module Autoextend::ObjectMethods
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def inherited(klass)
      return super unless klass.name
      Autoextend.extensions.fetch(klass.name.to_sym, []).each do |extension|
        extension.extend(klass)
      end
      super
    end
  end

  # Add a hook to automatically extend a class with a module,
  # or a block
  #
  #   autoextend_class(:User, :MyUserExtension)
  #
  #   autoextend_class(:User) do |klass|
  #     klass.send(:include, MyUserExtension)
  #   end
  #
  # If User is already defined, it will immediately prepend
  # the MyUserExtension module into it. It then sets up a hook
  # to automatically prepend User as soon as it _is_ defined.
  # Note that this hook happens before any methods have been
  # added to it, so you cannot directly modify anything you
  # expect to exist in the class.
  # Instead you should either use prepend with super, or
  # set up additional hooks to automatically modify methods
  # as they are added (if you use :include as your method)
  def autoextend_class(klass_name, module_name = nil, method = :prepend, &block)
    raise ArgumentError.new("block is required if module_name is not passed") if !module_name && !block
    raise ArgumentError.new("cannot pass both a module_name and a block") if module_name && block

    klass_extensions = Autoextend.extensions[klass_name.to_sym] ||= []
    klass_extensions << (extension = Autoextend::Extension.new(module_name, method, block))
    # immediately extend the class if it's already defined
    if (Object.const_defined?(klass_name.to_s, false))
      extension.extend(Object.const_get(klass_name.to_s, false))
    end
    nil
  end
end

Object.send(:include, Autoextend::ObjectMethods)
