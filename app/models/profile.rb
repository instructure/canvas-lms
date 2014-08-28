class Profile < ActiveRecord::Base
  belongs_to :context, :polymorphic => true
  belongs_to :root_account, :class_name => 'Account'

  attr_accessible :context, :root_account, :title, :path, :description, :visibility, :position

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
    while profile = Profile.find_by_root_account_id_and_path(root_account_id, path)
      break if profile.id == id
      path = "#{base_path}-#{count += 1}"
    end
    path
  end

  def data
    read_attribute(:data) || write_attribute(:data, {})
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
    klass.default_scope :conditions => ["context_type = ?", context_type]
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

  def self.instantiate(record)
    record["type"] = "#{record["context_type"]}Profile"
    super
  end

  module Association
    def self.included(klass)
      klass.has_one :profile, :as => :context
      klass.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def profile_with_correct_class
          profile_without_correct_class || begin
            profile = #{klass.to_s}Profile.new(:context => self)
            profile.root_account = root_account
            profile.title = name
            profile.visibility = "private"
            profile
          end
        end
        alias_method_chain :profile, :correct_class
      CODE
    end
  end
end
