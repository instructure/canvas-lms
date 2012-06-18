Time.class_eval do
  if RUBY_VERSION < "1.9."
    def strftime_with_1_9_parity(string)
      string = string.gsub(/%(%|-?[a-zA-Z]|[369]N)/) do |match|
        case match
          when '%L', '%3N'; ("%.3f" % (to_f % 1))[2, 3]
          when '%6N'; ("%.6f" % (to_f % 1))[2, 6]
          when '%N', '%9N'; ("%.9f" % (to_f % 1))[2, 9]
          when '%P'; strftime_without_1_9_parity('%p').downcase
          when '%v'; '%e-%b-%Y'
          when '%-d'; strftime_without_1_9_parity('%d').sub(/^0+/, '')
          else match
        end
      end
      strftime_without_1_9_parity(string)
    end
    alias_method_chain :strftime, :'1_9_parity'
  end

  def utc_datetime
    timestamp = self.getutc
    DateTime.civil(timestamp.strftime("%Y").to_i, 
                   timestamp.strftime("%m").to_i,
                   timestamp.strftime("%d").to_i,
                   timestamp.strftime("%H").to_i, 
                   timestamp.strftime("%M").to_i)
  end
end

# Object#blank? calls respond_to?, which has to instantiate the time object
# by doing an expensive time zone calculation.  So just skip that.
class ActiveSupport::TimeWithZone
  def blank?
    false
  end

  def utc_datetime
    self.comparable_time.utc_datetime
  end
end
