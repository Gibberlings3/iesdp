# frozen_string_literal: true

# A successful Jekyll build can still omit documentation or render incorrect
# offsets. Compare the generated output with the source data to catch those
# regressions when changing the toolchain, plugins, or templates.
require "date"
require "json"
require "pathname"
require "rexml/document"
require "yaml"

source = Pathname.new(__dir__).parent
destination = Pathname.new(ARGV.fetch(0, "_site")).expand_path
abort "Build the site first: #{destination} does not exist" unless destination.directory?

def check(condition, message)
  abort "FAIL: #{message}" unless condition
end

def read_yaml(path)
  YAML.safe_load_file(path, permitted_classes: [Date, Time], aliases: true)
end

def read_page(destination, path)
  file = destination.join(path.delete_prefix("/"))
  check(file.file?, "Missing #{path}")
  text = file.read(encoding: "UTF-8")
  check(text.valid_encoding?, "#{path}: invalid UTF-8 bytes")
  text
end

check(JSON::VERSION == Gem.loaded_specs.fetch("json").version.to_s, "Loaded JSON differs from the bundled version; check RUBYLIB")
check(REXML::VERSION == Gem.loaded_specs.fetch("rexml").version.to_s, "Loaded REXML differs from the bundled version; check RUBYLIB")

games = read_yaml(source.join("_data/games.yml"))
actions = source.glob("_data/actions/*.yml").to_h do |file|
  [file.basename(".yml").to_s, read_yaml(file)]
end
opcodes = source.glob("_opcodes/*").filter_map do |file|
  next unless file.file?

  front_matter = file.read[/\A---\s*\n(.*?)\n---/m, 1]
  YAML.safe_load(front_matter, permitted_classes: [Date, Time], aliases: true) if front_matter
end
opcode_pages = {
  "bg1" => "bg1tots", "bg2" => "bg2tob", "bgee" => "bgee",
  "iwd1" => "iwd1totl", "iwd2" => "iwd2", "pst" => "pst", "pstee" => "pstee"
}

games.each do |game|
  name = game.fetch("name")
  html = read_page(destination, game.fetch("actions"))
  expected = actions.select { |_, action| action[name] == 1 }.keys.sort
  actual = html.scan(/<a id="([^"]+)" class="action_name">/).flatten.sort
  check(actual == expected, "#{name}: generated action anchors differ from source data")
  check(html.include?("<pre") && html.include?("<code"), "#{name}: missing rendered code examples")

  html = read_page(destination, "opcodes/#{opcode_pages.fetch(name)}.htm")
  expected = opcodes.select { |opcode| opcode[name] == 1 }.map { |opcode| opcode.fetch("n").to_s }.sort
  actual = html.scan(/<div id="op(\d+)" class="opcode">/).flatten.sort
  check(actual == expected, "#{name}: generated opcode anchors differ from source data")
  expected.each do |number|
    check(html.include?("##{number} (#{format('0x%X', number.to_i)})"), "#{name}: missing opcode hexadecimal number #{number}")
  end
  puts "PASS: #{name} action and opcode listings"
end

sizes = { "byte" => 1, "char" => 1, "word" => 2, "dword" => 4, "resref" => 8, "strref" => 4 }
%w[eff_v1 eff_v2 itm_v1 spl_v1 sto_v1].each do |format_name|
  relative = "file_formats/ie_formats/#{format_name}.htm"
  template = source.join(relative).read
  html = read_page(destination, relative)
  tables = html.scan(/<table\b[^>]*class="offset_table"[^>]*>(.*?)<\/table>/m).flatten
  assignments = template.enum_for(:scan, /assign offsets = site\.data\.file_formats\.(\w+)\.(\w+)/).map do
    [Regexp.last_match[1], Regexp.last_match[2]]
  end
  check(tables.size == assignments.size, "#{format_name}: missing generated offset tables")
  assignments.each_with_index do |(data_format, section), index|
    rows = read_yaml(source.join("_data/file_formats/#{data_format}/#{section}.yml"))
    offset = rows.first.fetch("offset", 0)
    expected = rows.map do |row|
      check(!row.key?("offset") || row["offset"] == offset, "#{format_name}/#{section}: inconsistent source offset")
      rendered_offset = format("0x%04x", offset)
      offset += (row["length"] || sizes.fetch(row.fetch("type"))) * row.fetch("mult", 1)
      rendered_offset
    end
    actual = tables[index].scan(/<td>(0x[0-9a-f]+)<\/td>/).flatten
    check(actual == expected, "#{format_name}/#{section}: incorrect generated offsets or missing rows")
  end
  puts "PASS: #{format_name} offset tables"
end

actions_html = read_page(destination, "scripting/actions/bgeeactions.htm")
check(actions_html.include?('href="../../files/ids/bgee/animate.htm"'), "Nested Liquid link in action descriptions did not render")
check(actions_html.include?("highlighter-rouge"), "Markdown syntax highlighting did not render")

playground = read_page(destination, "test.htm")
check(playground.include?("Stat: AC vs. Damage Type Modifier"), "Playground did not render the explicit opcode display name")
check(!playground.match?(/class="opnamedata">op\d+[^<]*\.html/), "Jekyll document filenames leaked into opcode display names")

%w[index.htm main.htm files/2da/index.htm files/ids/index.htm scripting/triggers/index.htm appendices/index.htm site_info/index.htm].each do |path|
  html = read_page(destination, path)
  check(html.include?('id="content"') && html.include?('id="footer"'), "#{path}: missing page layout")
end
css = read_page(destination, "css/main.css")
check(css.include?("#F6F7EB") || css.include?("#f6f7eb"), "Missing compiled background style")
check(css.include?(".go-up") && !css.include?("$background-color"), "Sass did not compile")

feed = REXML::Document.new(read_page(destination, "feed.xml"))
check(feed.root.name == "rss", "Existing RSS feed format changed")
sitemap = REXML::Document.new(read_page(destination, "sitemap.xml"))
check(sitemap.root.name == "urlset", "Invalid sitemap")

%w[Gemfile Gemfile.lock README.md CONTRIBUTING.md DEVELOPMENT.md deploy.sh cleaner .ruby-version .github _tools vendor js/html5shiv.js js/respond.js].each do |path|
  check(!destination.join(path).exist?, "Build or unused dependency file leaked into the site: #{path}")
end
html_pages = destination.glob("**/*.{htm,html}")
html_pages.each do |file|
  path = file.relative_path_from(destination).to_s
  html = read_page(destination, path)
  check(html.match?(/<meta\b[^>]*\bcharset\s*=\s*["']?utf-8\b/i), "#{path}: missing UTF-8 declaration for offline use")
  check(!html.match?(/Liquid (?:Exception|error|syntax error):|Offset mismatch\. Expected/), "Rendering error in #{path}")
end
puts "PASS: UTF-8 bytes and declarations in #{html_pages.size} HTML pages"
puts "PASS: layouts, nested rendering, styles, RSS, sitemap, and output hygiene"
