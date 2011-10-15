if RUBY_VERSION < "1.9."
  Time.class_eval do
    def strftime_with_1_9_parity(string)
      string = string.gsub(/%[369]?N|%./) do |match|
        case match
          when '%L', '%3N'; ("%.3f" % (to_f % 1))[2, 3]
          when '%6N'; ("%.6f" % (to_f % 1))[2, 6]
          when '%N', '%9N'; ("%.9f" % (to_f % 1))[2, 9]
          when '%P'; strftime_without_1_9_parity('%p').downcase
          when '%v'; '%e-%b-%Y'
          else match
        end
      end
      strftime_without_1_9_parity(string)
    end
    alias_method_chain :strftime, :'1_9_parity'
  end
end

# Object#blank? calls respond_to?, which has to instantiate the time object
# by doing an expensive time zone calculation.  So just skip that.
class ActiveSupport::TimeWithZone
  def blank?
    false
  end
end
