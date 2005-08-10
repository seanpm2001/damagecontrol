require_dependency 'sparklines'
# TODO: shouldn't be necessary, but sometimes we get errors...!!??
require_dependency 'build'
require_dependency 'project'
require_dependency 'damagecontrol'

class ApplicationController < ActionController::Base
  SPARKLINE_COUNT = 20

  before_filter :load_projects
  helper :sparklines
  
  def deserialize_to_array(hash)
    result = []
    hash.each do |class_name, values|
      result << deserialize(class_name, values)
    end
    result
  end

  # Deserialises an object from a Hash holding attribute values. 
  # Special rules:
  # * "true" and "false" strings are turned into booleans.
  # * Array values are eval'ed to classes and new'ed.
  # * Hash values are turned into a new Hash by combining its
  #   :keys and :values entries (This is handier to POST from forms).
  def deserialize(class_name, attributes)
    object = eval(class_name).new
    attributes.each do |attr_name, attr_value|
      setter = "#{attr_name}=".to_sym
      if(attr_value == "true")
        attr_value = true
      end
      if(attr_value == "false")
        attr_value = false
      end
      if(attr_value.is_a?(Array))
        attr_value = instantiate_array(attr_value)
      end
      if(attr_value.is_a?(Hash))
        # TODO: Find a more elegant way
        keys = attr_value[:keys]
        values = attr_value[:values]
        attr_value = {}
        keys.each_with_index do |key, i|
          attr_value[key] = values[i]
        end
      end
      object.__send__(setter, attr_value)
    end
    object
  end

protected
  
  def load_builds_for_sparkline(project)
    @builds = project.builds(nil, nil, SPARKLINE_COUNT)
  end

private

  def instantiate_array(array)
    result = array.collect do |cls_name| 
      eval(cls_name).new
    end
  end

  # Loads all projects so that the right column can be populated properly
  def load_projects
    @projects = Project.find(:all)
  end
end
