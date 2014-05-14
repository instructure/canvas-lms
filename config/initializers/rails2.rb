if CANVAS_RAILS2

ActiveRecord::Base.class_eval do
  class << self
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

    # allow validate to recognize the Rails 3 style on: action modifiers,
    # translating those calls into validate_on_action calls.
    def validate_with_rails3_compatibility(*methods, &block)
      options = methods.extract_options! || {}
      callback =
        case validation_method(options[:on])
        when :validate_on_create then :validate_on_create
        when :validate_on_update then :validate_on_update
        else :validate_without_rails3_compatibility
        end
      methods << block if block_given?
      methods << options unless options.empty?
      send(callback, *methods)
    end
    alias_method_chain :validate, :rails3_compatibility

    # allow before_validation to recognize the Rails 3 style on: action
    # modifiers, translating those calls into before_validation_on_action
    # calls.
    def before_validation_with_rails3_compatibility(*methods, &block)
      options = methods.extract_options! || {}
      callback =
        case validation_method(options[:on])
        when :validate_on_create then :before_validation_on_create
        when :validate_on_update then :before_validation_on_update
        else :before_validation_without_rails3_compatibility
        end
      methods << block if block_given?
      methods << options unless options.empty?
      send(callback, *methods)
    end
    alias_method_chain :before_validation, :rails3_compatibility

    def quote_bound_value_with_relations(value)
      if ActiveRecord::Associations::AssociationCollection === value
        with_exclusive_scope do
          value = value.scoped
        end
      end
      if ActiveRecord::NamedScope::Scope === value
        with_exclusive_scope do
          unless value.scope(:find, :select)
            value = value.select("#{value.quoted_table_name}.#{value.primary_key}")
          end
          return value.to_sql
        end
      end
      quote_bound_value_without_relations(value)
    end
    alias_method_chain :quote_bound_value, :relations
  end

  def save_with_rails3_options(options = true)
    if options == { validate: false }
      options = false
    end
    save_without_rails3_options(options)
  end
  alias_method_chain :save, :rails3_options

  public :assign_attributes
  def assign_attributes_with_rails3_options(new_attributes, options = {})
    if options[:without_protection]
      self.send(:attributes=, new_attributes, false)
    else
      assign_attributes_without_rails3_options(new_attributes)
    end
  end
  alias_method_chain :assign_attributes, :rails3_options
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
    scope = proxy_scope
    scope = scope.proxy_scope while (ActiveRecord::NamedScope::Scope === scope)
    scope.send(:with_exclusive_scope) { self.scope(:find) }
 end

  def is_a?(klass)
    # no, it's not a freaking Hash, and don't instantiate a gazillion things to find that out
    super || klass >= Array
  end

  remove_method :respond_to_missing?
#  def respond_to_missing?(method, include_super)
#    return super if [:marshal_dump, :_dump, 'marshal_dump', '_dump'].include?(method)
#    super || @proxy_scope.respond_to_missing?(method, include_super)
#  end

#  def respond_to?(method, include_private = false)
#    return super if [:marshal_dump, :_dump, 'marshal_dump', '_dump'].include?(method)
#    super || @proxy_scope.respond_to?(method, include_private)
#  end

  alias :klass :proxy_scope
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
   :fields_for, :form_for, :form_tag, :javascript_tag, :link_to].each do |block_helper|
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

# let Rails.env= work like it does in rails3
Rails.module_eval do
  def self.env=(environment)
    @_env = ActiveSupport::StringInquirer.new(environment)
  end
end

class ActiveRecord::Base
  class DynamicFinderTypeError < Exception; end
  class << self
    def construct_attributes_from_arguments_with_type_cast(attribute_names, arguments)
      log_dynamic_finder_nil_arguments(attribute_names) if current_scoped_methods.nil? && arguments.flatten.compact.empty?
      construct_attributes_from_arguments_without_type_cast(attribute_names, arguments)
    end
    alias_method_chain :construct_attributes_from_arguments, :type_cast

    def log_dynamic_finder_nil_arguments(attribute_names)
      error = "No non-nil arguments passed to #{self.base_class}.find_by_#{attribute_names.join('_and_')}"
      raise DynamicFinderTypeError, error if Canvas.dynamic_finder_nil_arguments_error == :raise
      logger.debug "WARNING: " + error
    end
  end
end

# patch adapted from https://rails.lighthouseapp.com/projects/8994/tickets/4887-has_many-through-belongs_to-association-bug
# this isn't getting fixed in rails 2.3.x, and we need it. otherwise the following sorts of things
# will generate sql errors:
#  Course.new.default_wiki_wiki_pages.scoped(:limit => 10)
#  Group.new.active_default_wiki_wiki_pages.size
ActiveRecord::Associations::HasManyThroughAssociation.class_eval do
  def construct_scope_with_has_many_fix
    if target_reflection_has_associated_record?
      construct_scope_without_has_many_fix
    else
      {:find => {:conditions => "1 != 1"}}
    end
  end
  alias_method_chain :construct_scope, :has_many_fix
end

# in ruby 2.0, respond_to? returns false for protected methods; Rails 2 doesn't know this,
# so replace this method with that knowledge
ActiveRecord::Callbacks.class_eval do
  def callback(method)
    result = run_callbacks(method) { |result, object| false == result }

    if result != false && respond_to_without_attributes?(method, true)
      result = send(method)
    end

    notify(method)

    return result
  end
end

# ditto
ActiveRecord::AutosaveAssociation.class_eval do
  def save_collection_association(reflection)
    if association = association_instance_get(reflection.name)
      autosave = reflection.options[:autosave]

      if records = associated_records_to_validate_or_save(association, @new_record_before_save, autosave)
        records.each do |record|
          next if record.destroyed?

          if autosave && record.marked_for_destruction?
            association.destroy(record)
          elsif autosave != false && (@new_record_before_save || record.new_record?)
            if autosave
              saved = association.send(:insert_record, record, false, false)
            else
              association.send(:insert_record, record)
            end
          elsif autosave
            saved = record.save(:validate => false)
          end

          raise ActiveRecord::Rollback if saved == false
        end
      end

      # reconstruct the SQL queries now that we know the owner's id
      association.__send__(:construct_sql) if association.respond_to?(:construct_sql, true)
    end
  end
end

  ActiveRecord::NamedScope::Scope.class_eval do
    def where_values
      Array(scope(:find, :conditions))
    end

    def select_values
      Array(scope(:find, :select))
    end

    def group_values
      Array(scope(:find, :group))
    end

    def order_values
      Array(scope(:find, :order))
    end

    def shard_value
      scope(:find, :shard)
    end
  end
end
