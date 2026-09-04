# Appends a new property to a liquid object
module Jekyll
  module AddProp
    def addProp(input, key, value)
      input[key] = value
      return input
    end
  end
end

Liquid::Template.register_filter(Jekyll::AddProp)
