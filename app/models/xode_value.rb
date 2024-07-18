class XodeValue < ApplicationRecord

  def self.new_value(h)
    return XodeValue.where(id: 0).first_or_create if h.nil? or h == { 'value' => nil }
    return XodeValue.find(1) if h == { 'value' => 'REDACTED' }
    v2 = XodeValue.new
    h.each do |k, v|
      case k
      when 'source_id', 'docid'
        v2.send "#{k}=", v
      when 'beg', 'end'
        case v
        when Integer
          v2.send "#{k}i=", v
        when String
          v2.send "#{k}r=", v.to_f
        when BigDecimal, Float
          v2.send "#{k}r=", v
        end
      when 'value', 'text'
        if v.class == Array
          v2.send "#{k}=", v.join(',')
        else
          v2.send "#{k}=", v
        end
      when 'points'
        v2.value = v.map { |x| x.join(',') }.join(';')
      end
    end
    v2
  end

end
