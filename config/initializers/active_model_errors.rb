module ActiveModel
  module BetterErrors
    # This is backwards compatible with what our existing javascript expects to get
    # back as a json error response.
    # In theory once we've gotten rid of all legacy non-API AJAX calls, and
    # finished standardizing our API JSON responses, this can be removed. That will
    # take a long time though.
    class InstructureHashReporter < HashReporter
      def to_hash
        error_hash = collection.to_hash.inject({}) do |hash, (attribute, error_message_set)|
          hash[attribute] = error_message_set.map do |error_message|
            format_error_message(attribute, error_message)
          end
          hash
        end
        { errors: error_hash }
      end

      def format_error_message(attribute, error_message)
        {
          attribute: attribute,
          type: error_message.type || error_message.message || "invalid",
          message: error_message.message || error_message.type || "invalid",
        }
      end
    end

    # This is backwards compatible with rails built-in "human error message"
    # formatting, to maintain previous behavior. By default BetterErrors uses a
    # new formatting.
    class InstructureFormatter < Formatter
      def format_message
        return message if message && type.nil?

        keys = i18n_keys
        key  = keys.shift

        options = {
          :default => keys,
          :model => base.class.name.humanize,
          :attribute => base.class.human_attribute_name(attribute),
          :value => value
        }.merge(self.options)
        options[:default] ||= keys

        # the send here is to avoid rake i18n:check complaining about passing a non-string-literal to I18n.t
        result = catch(:exception) do
          I18n.send(:translate, key, options)
        end
        if result.is_a?(I18n::MissingTranslation)
          # fallback on activerecord.errors scope if translation is missing for rails 3
          result = I18n.send(:translate, key, options.merge(:scope => [:activerecord, :errors], :throw => false))
        end
        result
      end

      protected

      def type
        error_message.type || :invalid
      end

      def value
        return if attribute == :base
        base.send :read_attribute, attribute
      end

      def options
        super().merge(scope: [:errors], throw: true)
      end

      def i18n_keys
        self_and_descendants = ([base.class] + base.class.descendants)
        keys = self_and_descendants.map do |klass|
          [ :"models.#{klass.name.underscore}.attributes.#{attribute}.#{type}",
            :"models.#{klass.name.underscore}.#{type}" ]
        end.flatten

        keys << options.delete(:default)
        keys << message if message.is_a?(String)
        keys << :"messages.#{type}"
        keys << type unless type == message
        keys.compact!
        keys.flatten!
        keys
      end
    end

    class InstructureHumanMessageReporter < HumanMessageReporter
      def full_message(attribute, message)
        return message if attribute == :base
        str = attribute.to_s.gsub('.', '_').humanize
        str = base.class.human_attribute_name(attribute, default: str)

        keys = [
          :'full_messages.format',
          '%{attribute} %{message}'
        ]

        I18n.send(:t,
               keys.shift,
               default: keys,
               attribute: str,
               message: message)
      end
    end

    module AutosaveAssociation
      def _ensure_no_duplicate_errors
        errors.error_collection.keys.each do |attribute|
          errors[attribute].uniq!
        end
      end
    end
  end
end

# This is what sets the above reporter class as both the .to_hash and .to_json
# responder for ActiveRecord::Errors objects (which with the better_errors gem
# installed, is actually replaced by the ActiveModel::BetterErrors::Errors class)
ActiveModel::BetterErrors.set_reporter :hash, ActiveModel::BetterErrors::InstructureHashReporter
ActiveModel::BetterErrors.set_reporter :message, ActiveModel::BetterErrors::InstructureHumanMessageReporter
ActiveModel::BetterErrors.formatter = ActiveModel::BetterErrors::InstructureFormatter
# We default to the InstructureHashReporter rather than the ApiReporter for
# backwards compatibility with all the existing Canvas code that expects the
# old format. The ApiReporter is specifically activated by the API error
# response code.

# make better errors compatible with Rails 5
ActiveRecord::Base.include(ActiveModel::BetterErrors::AutosaveAssociation) unless CANVAS_RAILS4_2
