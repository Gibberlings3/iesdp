module Jekyll
  module OffToHex
    def offset_to_hex(val)
      sprintf("0x%04x",val)    # ->  "0x006e"
    end
  end
end

Liquid::Template.register_filter(Jekyll::OffToHex)
