module LuckySneaks
  module ActsAsUrl # :nodoc:
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods # :doc:
      # Creates a callback to automatically create an url-friendly representation
      # of the <tt>attribute</tt> argument. Example:
      #
      #   act_as_url :title
      #
      # will use the string contents of the <tt>title</tt> attribute
      # to create the permalink. <strong>Note:</strong> you can also use a non-database-backed
      # method to supply the string contents for the permalink. Just use that method's name
      # as the argument as you would an attribute.
      #
      # The default attribute <tt>acts_as_url</tt> uses to save the permalink is <tt>url</tt>
      # but this can be changed in the options hash. Available options are:
      #
      # <tt>:url_attribute</tt>:: The name of the attribute to use for storing the generated url string.
      #                           Default is <tt>:url</tt>
      # <tt>:scope</tt>:: The name of model attribute to scope unique urls to. There is no default here.
      # <tt>:only_when_blank</tt>:: If true, the url generation will only happen when <tt>:url_attribute</tt> is
      #                             blank. Default is false (meaning url generation will happen always)
      # <tt>:sync_url</tt>:: If set to true, the url field will be updated when changes are made to the
      #                      attribute it is based on. Default is false.
      def acts_as_url(attribute, options = {})
        cattr_reader :attribute_to_urlify
        cattr_reader :scope_for_url
        cattr_reader :url_attribute # The attribute on the DB
        cattr_reader :only_when_blank
        attr_writer :only_when_blank

        self.class_eval do
          def only_when_blank
            return @only_when_blank unless @only_when_blank.nil? # can override only_when_blank temporarily
            self.class.only_when_blank
          end
        end

        if options[:sync_url]
          before_validation :ensure_unique_url
        else
          before_validation(:ensure_unique_url, :on => :create)
        end

        class_variable_set(:@@attribute_to_urlify, attribute)
        class_variable_set(:@@scope_for_url, options[:scope])
        class_variable_set(:@@url_attribute, options[:url_attribute] || "url")
        class_variable_set(:@@only_when_blank, options[:only_when_blank] || false)
      end

      # Initialize the url fields for the records that need it. Designed for people who add
      # <tt>acts_as_url</tt> support once there's already development/production data they'd
      # like to keep around.
      #
      # Note: This method can get very expensive, very fast. If you're planning on using this
      # on a large selection, you will get much better results writing your own version with
      # using pagination.
      def initialize_urls
        where(self.url_attribute => nil).each do |instance|
          instance.send :ensure_unique_url
          instance.save
        end
      end
    end

    private
    def ensure_unique_url
      url_attribute = self.class.url_attribute
      base_url = self.send(url_attribute)
      base_url = self.send(self.class.attribute_to_urlify).to_s.to_url if base_url.blank? || !self.only_when_blank
      conditions = ["#{url_attribute} LIKE ?", base_url+'%']
      unless new_record?
        conditions.first << " and id != ?"
        conditions << id
      end
      if self.class.scope_for_url
        conditions.first << " and #{self.class.scope_for_url} = ?"
        conditions << send(self.class.scope_for_url)
      end
      url_owners = self.class.where(conditions).to_a
      if url_owners.size > 0
        n = 1
        while url_owners.detect { |u| u.send(url_attribute) == "#{base_url}-#{n}" }
          n = n.succ
        end
        write_attribute url_attribute, "#{base_url}-#{n}"
      else
        write_attribute url_attribute, base_url
      end
    end
  end
end
