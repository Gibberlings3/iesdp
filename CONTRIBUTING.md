# Reporting Bugs

Content related bugs should be reported on the forum, so they can be discussed and so that people
notice the changes. It's a means of broad peer review and documentation.

# Pull Request

See above, the same applies to pull requests that aren't structural or fixing simple typos.

# Contributing Code

It's all here, developed in the master branch and then automatically generated into gh-pages
via Travis (since we use a custom plugin and want a downloadable zip of the result).

For anything that could need wider consensus, present the idea on the forum first.

Try not to introduce spelling and grammar bugs.

If possible, when changing opcode/action docs, check any other versions of the opcode.
Perhaps the change applies there too.

# Data format

Certain file format and action data is externalized into [Jekyll data files](https://jekyllrb.com/docs/datafiles/), with eventual goal being making most of IESDP data machine readable and available for consumption by external tools. See `_data` directory.

- [Actions](#actions)
- [File formats](#file-formats)

Description `desc` field in both Actions and File formats takes Markdown, HTML, Liquid. The preferred syntax is **Markdown**. HTML and Liquid should be used sparingly, only when there's no Markdown equivalent.

URLs should be canonical (start from website root, don't use `../`s), with `relurl` filter. This is to ensure that links in both online and offline versions of IESDP work properly.  
One exception to this rule is linking anchors on the same page, they don't need `relurl`.

- **Right**:
  - Preferred version: markdown with `relurl`
    ```markdown
    [Class]({{ "/file_formats/ie_formats/cre_v1.htm#CREV1_0_Header_0x273" | prepend: relurl }})
    ```
  - Alternative version: HTML with `relurl`
    ```html
    <a href="{{ '/file_formats/ie_formats/cre_v1.htm#CREV1_0_Header_0x273' | prepend: relurl }}">Class</a>
    ```
    Used in:
    - Opcodes descriptions (`_opcodes`), since they are in html format.
    - When markdown syntax is not enough. For example, if we want to add anchor `class` to the link, but markdown doesn't support that attribute.
      ```html
      <a name="class" href="{{ '/file_formats/ie_formats/cre_v1.htm#CREV1_0_Header_0x273' | prepend: relurl }}">Class</a>
      ```
  - Same page anchors:
    `[opcode #337](#op337)` if in `_data` or `<a href="#op337">opcode #337</a>` if in `_opcodes`.
- **Wrong**:
  - Missing `relurl`
    ```markdown
    [Class](../file_formats/ie_formats/cre_v1.htm#CREV1_0_Header_0x273)
    ```
  - HTML instead of Markdown
    ```html
    <a href="../file_formats/ie_formats/cre_v1.htm#CREV1_0_Header_0x273">Class</a>
    ```
  - Absolute URL instead of relative
    ```html
    <a href="https://gibberlings3.github.io/iesdp/file_formats/ie_formats/cre_v1.htm#CREV1_0_Header_0x273">Class</a>
    ```

## Actions

Example: `Polymorph(I:AnimationType*Animate)`

```yaml
bg1: 1                   # at least one game must be 1
bg2: 1
iwd1: 0                  # 0's are optional, can be omitted, so this line and next 2 are not necessary
# iwd2: 0
# pst:  0

n: 146                   # required - action number
name: Polymorph          # required, case sensitive, no parentheses
params:                  # optional
  - name: AnimationType  # required, case sensitive
    type: i              # required, automatically uppercased
    ids:  Animate        # optional, automatically capitalized

not_tested: true         # optional, "untested" label
no_result: true          # optional, "does not work" label
unknown: true            # optional, "unknown" label
unreliable: true         # optional, "unreliable" label
alias: true              # optional, sets desc to "See N". By default N=n, but they aren't equal, alias can take a numerical value instead:
# alias: 147             # this sets desc to "See #147"

desc: |-                 # optional
  This action causes the active creature to change animation to the specified animation (values from [animate.ids](/files/ids/bg2/animate.htm))
  ...
```

## File formats

File naming example: `_data/file_formats/itm_v1/extended_header.yml`.

Data is a yaml list of offsets. Example:
```yaml
- desc: |            # required - markdown
    Attack type
    - 0 = None
    - 1 = Melee
  type: char         # required. Known types: char, byte, word, dword, resref, strref.
                     # You can use a custom type, but in that case you must specify the following "length" field.

  length: 1          # optional, generally should be omitted, in which case, size inferred from type.
  offset: 0x1        # optional, if specified, current offset is checked against this value, if not equal, an error is raised
                     # Generally, should only be specified for the first and last items in the list

  mult: 3            # optional, allows to do stuff like "2*3 (word)"
  unknown: 1         # optional, applies "unknown" style span
  unused: 1          # optional, appends " (unused)" to description and applies "unknown" style span
```
