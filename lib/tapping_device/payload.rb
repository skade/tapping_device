class TappingDevice
  class Payload < Hash
    ATTRS = [:receiver, :method_name, :arguments, :return_value, :filepath, :line_number, :defined_class, :trace, :tp]

    ATTRS.each do |attr|
      define_method attr do
        self[attr]
      end
    end

    def self.init(hash)
      h = new
      hash.each do |k, v|
        h[k] = v
      end
      h
    end
  end
end
