##
# Allows for basic seralizing of objects
module Serializable
  def serialize
    object = {}
    instance_variables.map do |variable|
      object[variable] = instance_variable_get variable
    end

    Marshal.dump object
  end

  def unserialize(msg)
    object = Marshal.load msg
    object.each_pair do |key, value|
      instance_variable_set key, value
    end
  end
end
