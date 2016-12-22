class Profile < ActiveRecord::Base
  belongs_to :context, polymorphic: [:course], exhaustive: false
  belongs_to :root_account, :class_name => 'Account'

  serialize :data

  validates_presence_of :root_account
  validates_presence_of :context
  validates_length_of :title, :within => 0..255
  validates_length_of :path, :within => 0..255
  validates_format_of :path, :with => /\A[a-z0-9-]+\z/
  validates_uniqueness_of :path, :scope => :root_account_id
  validates_uniqueness_of :context_id, :scope => :context_type
  validates_inclusion_of :visibility, :in => %w{ public unlisted private }

  self.abstract_class = true
  self.table_name = 'profiles'

  def title=(title)
    write_attribute(:title, title)
    write_attribute(:path, infer_path) if path.nil?
    title
  end

  def infer_path
    return nil unless title
    path = base_path = title.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A\-+|\-+\z/, '')
    count = 0
    while profile = Profile.where(root_account_id: root_account_id, path: path).first
      break if profile.id == id
      path = "#{base_path}-#{count += 1}"
    end
    path
  end

  def data
    read_or_initialize_attribute(:data, {})
  end

  def data_before_type_cast # for validations and such
    @data_before_type_cast ||= data.dup
  end

  def self.data(field, options = {})
    options[:type] ||= :string
    define_method(field) {
      data.has_key?(field) ? data[field] : data[field] = options[:default]
    }
    define_method("#{field}=") { |value|
      data_before_type_cast[field] = value
      data[field] = sanitize_data(value, options)
    }
    define_method("#{field}_before_type_cast") {
      data_before_type_cast[field]
    }
  end

  def sanitize_data(value, options)
    return nil unless value.present?
    case options[:type]
      when :decimal,
           :float;   value.to_f
      when :int;     value.to_i
      else           value
    end
  end

  # some tricks to make it behave like STI with a type column
  def self.inherited(klass)
    super
    context_type = klass.name.sub(/Profile\z/, '')
    klass.class_eval { alias_method context_type.downcase.underscore, :context }
    klass.instance_eval { def table_name; "profiles"; end }
    klass.default_scope -> { where(:context_type => context_type) }
  end

  def self.columns_hash
    not_set = @columns_hash.nil?
    super
    if not_set
      def @columns_hash.include?(key)
        key == "type" || super
      end
    end
    @columns_hash
  end

  def self.instantiate(*args)
    record = args.first
    record["type"] = "#{record["context_type"]}Profile"
    super
  end

  module Association
    def self.prepended(klass)
      klass.has_one :profile, as: :context, inverse_of: :context
    end

    def profile
      super || begin
        profile = Object.const_get("#{self.class.name}Profile", false).new(context: self)
        profile.root_account = root_account
        profile.title = name
        profile.visibility = "private"
        profile
      end
    end
  end
end
