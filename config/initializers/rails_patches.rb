if Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR >= 1
  raise "This patch has been merged into rails 3.1, remove it from our repo"
else
  # bug submitted to rails: https://rails.lighthouseapp.com/projects/8994/tickets/5802-activerecordassociationsassociationcollectionload_target-doesnt-respect-protected-attributes#ticket-5802-1
  # This fix has been merged into rails trunk and will be in the rails 3.1 release.
  class ActiveRecord::Associations::AssociationCollection
    def load_target
      if !@owner.new_record? || foreign_key_present
        begin
          if !loaded?
            if @target.is_a?(Array) && @target.any?
              @target = find_target.map do |f|
                i = @target.index(f)
                if i
                  @target.delete_at(i).tap do |t|
                    keys = ["id"] + t.changes.keys + (f.attribute_names - t.attribute_names)
                    f.attributes.except(*keys).each do |k,v|
                      t.write_attribute(k, v)
                    end
                  end
                else
                  f
                end
              end + @target
            else
              @target = find_target
            end
          end
        rescue ActiveRecord::RecordNotFound
          reset
        end
      end

      loaded if target
      target
    end
  end

  # https://github.com/rails/rails/commit/0e17cf17ebeb70490d7c7cd25c6bf8f9401e44b3
  # In master, should be in the next 3.1 release
  ERB::Util.module_eval do
    def html_escape(s)
      s = s.to_s
      if s.html_safe?
        s
      else
        s.gsub(/[&"><]/n) { |special| ERB::Util::HTML_ESCAPE[special] }.html_safe
      end
    end
    remove_method(:h)
    alias h html_escape

    module_function :h
    module_function :html_escape
  end
end
