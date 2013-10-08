if CANVAS_RAILS2

ActiveRecord::Base.class_eval do
  class << self
    # taken from fake_arel, and extended further to support combining of :select and :group
    def with_scope(method_scoping = {}, action = :merge, &block)
      method_scoping = {:find => method_scoping.proxy_options} if method_scoping.class == ActiveRecord::NamedScope::Scope
      method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)

      # Dup first and second level of hash (method and params).
      method_scoping = method_scoping.inject({}) do |hash, (method, params)|
        hash[method] = (params == true) ? params : params.dup
        hash
      end

      method_scoping.assert_valid_keys([ :find, :create ])

      if f = method_scoping[:find]
        f.assert_valid_keys(VALID_FIND_OPTIONS)
        set_readonly_option! f
      end

      # Merge scopings
      if [:merge, :reverse_merge].include?(action) && current_scoped_methods
        method_scoping = current_scoped_methods.inject(method_scoping) do |hash, (method, params)|
          case hash[method]
            when Hash
              if method == :find
                (hash[method].keys + params.keys).uniq.each do |key|
                  merge = hash[method][key] && params[key] # merge if both scopes have the same key
                  if key == :conditions && merge
                    if params[key].is_a?(Hash) && hash[method][key].is_a?(Hash)
                      hash[method][key] = merge_conditions(hash[method][key].deep_merge(params[key]))
                    else
                      hash[method][key] = merge_conditions(params[key], hash[method][key])
                    end
                  elsif key == :include && merge
                    hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                  elsif key == :joins && merge
                    hash[method][key] = merge_joins(params[key], hash[method][key])
                    # see https://rails.lighthouseapp.com/projects/8994/tickets/2810-with_scope-should-accept-and-use-order-option
                    # it works now in reverse order to comply with ActiveRecord 3
                  elsif [:order, :select, :group].include?(key) && merge && !default_scoping.any?{ |s| s[method].keys.include?(key) }
                    hash[method][key] = [hash[method][key], params[key]].select{|o| !o.blank?}.join(', ')
                  else
                    hash[method][key] = hash[method][key] || params[key]
                  end
                end
              else
                if action == :reverse_merge
                  hash[method] = hash[method].merge(params)
                else
                  hash[method] = params.merge(hash[method])
                end
              end
            else
              hash[method] = params
          end
          hash
        end
      end

      self.scoped_methods << method_scoping
      begin
        yield
      ensure
        self.scoped_methods.pop
      end
    end

    # returns a new scope, having removed the options mentioned
    # does *not* support extended scopes
    def except(*options)
      # include is renamed to includes in Rails 3
      includes = options.delete(:includes)
      options << :include if includes

      new_options = (scope(:find) || {}).reject { |k, v| options.include?(k) }
      with_exclusive_scope(:find => new_options) { scoped }
    end

    # returns a new scope, with just the order replaced
    # does *not* support extended scopes
    def reorder(*order)
      new_options = (scope(:find) || {}).dup
      new_options[:order] = order.flatten.join(',')
      with_exclusive_scope(:find =>new_options) { scoped }
    end

    def uniq(value = true)
      current_select = scope(:find, :select)
      if current_select.blank?
        return scoped unless value
        return select("DISTINCT #{quoted_table_name}.*")
      end

      match = current_select =~ /^\s*DISTINCT\s+(.+)/i
      if match && !value
        new_options = scope(:find).dup
        new_options[:select] = $1
        with_exclusive_scope(:find => new_options) { scoped }
      elsif !match && value
        new_options = scope(:find).dup
        new_options[:select] = "DISTINCT #{current_select}"
        with_exclusive_scope(:find => new_options) { scoped }
      else
        scoped
      end
    end

    def pluck(column)
      new_options = (scope(:find) || {}).dup
      new_options[:select] = "#{quoted_table_name}.#{column}"
      new_options.delete(:include)
      with_exclusive_scope(:find => new_options) { all.map(&column) }
    end

    # allow defining scopes Rails 3 style (scope, not named_scope)
    # scope is still a Rails 2 method, so we have to call the correct method
    # depending on the argument types
    def scope_with_named_scope(*args, &block)
      if args.length == 2
        case args[1]
        when String, Symbol
          scope_without_named_scope(*args)
        else
          named_scope *args, &block
        end
      else
        scope_without_named_scope(*args)
      end
    end
    alias_method_chain :scope, :named_scope
  end

  # support 0 arguments
  named_scope :lock, lambda { |*lock| lock = [true] if lock.empty?; {:lock => lock.first} }
end

ActiveRecord::NamedScope::ClassMethods.module_eval do
  # make all arguments optional, like Rails 3
  def scoped(scope = {}, &block)
    ActiveRecord::NamedScope::Scope.new(self, scope, &block)
  end
end

ActiveRecord::NamedScope::Scope.class_eval do
  # Scope delegates this to proxy_found because it's an array method; remove
  # the delegation and let it go through normal method_missing to the model
  remove_method :uniq

  # fake_arel doesn't quite work right here - somehow it's getting
  # Kernel#select. so just duplicate the select we want
  def select(value = Proc.new)
    if block_given?
      all.select {|*block_args| value.call(*block_args) }
    else
      self.scoped(:select => Array.wrap(value).join(','))
    end
  end

  # fake_arel does this in a really complicated way, trying to reproduce
  # with_scope's merging rules. It has bugs merging select clauses.
  # Instead, just take the easy way out and let with_scope do all
  # the hard work
  def unspin
    with_exclusive_scope { self.scope(:find) }
 end
end

ActiveRecord::Associations::AssociationCollection.class_eval do
  # AssociationCollection implements uniq for :uniq option, in its
  # own special way. re-implement, but as a scope if it's not an
  # internal use of it
  def uniq(records = true)
    if records.is_a?(Array)
      records.uniq
    else
      # do its thing to make a scope, going all the way back to the model
      scoped.uniq(records)
    end
  end

  # fake_arel doesn't quite work right here - somehow it's getting
  # Kernel#select. so just duplicate the select we want
  def select(value = Proc.new)
    if block_given?
      to_ary.select {|*block_args| value.call(*block_args) }
    else
      self.scoped(:select => Array.wrap(value).join(','))
    end
  end
end

class ActiveRecord::Generators
  include FakeRails3Generators
end

ActionView::Base.class_eval do
  [:content_tag, :content_tag_for, :field_set_tag,
   :fields_for, :form_for, :form_tag, :javascript_tag].each do |block_helper|
    define_method("#{block_helper}_with_nil_return") do |*args, &block|
      if block
        self.send("#{block_helper}_without_nil_return", *args, &block)
        nil
      else
        self.send("#{block_helper}_without_nil_return", *args)
      end
    end
    alias_method_chain block_helper, :nil_return
  end
end

ActiveSupport::SafeBuffer.class_eval do
  alias :append= :<<
end

class Class
  def self.class_attribute(*attrs)
    class_inheritable_accessor(*attrs)
  end
end

end
