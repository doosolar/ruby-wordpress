# Encoding: UTF-8

require 'php_serialize'

class WordPress::Options < WordPress::Base
  def [](key)
    v = nil
    @conn.query("SELECT `option_value` FROM `#{@tbl[:options]}` WHERE `option_name`='#{@conn.escape key}' LIMIT 1").each do |row|
      v = row[:option_value]
    end
    # Apply out-filters
    if v
      if v[0, 1] == 'a' and v[-1, 1] == '}'
        # PHP-serialized array
        v = PHP.unserialize v
      end
    end
    v
  end

  def []=(key, value)
    # Apply in-filters

    if value.kind_of?(Hash) or value.kind_of?(Array)
      value = PHP.serialize value
    end

    old_value = self[key]

    if !value.nil? and !old_value.nil? and value != old_value
      # Update operation.
      @conn.query("UPDATE `#{@tbl[:options]}` SET `option_value`='#{@conn.escape value}' WHERE `option_name`='#{@conn.escape key}'")
    elsif value.nil? and !old_value.nil?
      # New value nil, old value not. Delete operation.
      @conn.query("DELETE FROM `#{@tbl[:options]}` WHERE `option_name`='#{@conn.escape key}'")
    elsif !value.nil? and old_value.nil?
      # New value non-nil, old value nil. Insert operation.
      @conn.query("INSERT INTO `#{@tbl[:options]}` (`option_name`, `option_value`, `autoload`) VALUES ('#{@conn.escape key}', '#{@conn.escape value.to_s}', 'no')")
    end
    value
  end
end
