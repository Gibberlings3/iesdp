# Simple hex conversion Liquid filter plugin
#
# Convert a decimal to its hex value.
#
# Examples:
#   {{ 7 | dec_to_hex }}
#   # => 0x7
#
#   {{ "17" | dec_to_hex }}
#   # => 0x11
#
#   {{ "0x12" | dec_to_hex }}
#   # => 0x12
#
#   {{ 0x12 | dec_to_hex }}
#   # => ERROR
#
# val - integer or string representing a number
#
# Returns the hexadecimal value of the input number
#

module Jekyll
  module DecToHex
    def dec_to_hex(val)
      sprintf("0x%X", val)
    end
  end
end

Liquid::Template.register_filter(Jekyll::DecToHex)
