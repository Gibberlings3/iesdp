# Data format

Certain file format and action data is externalized into [Jekyll data files](https://jekyllrb.com/docs/datafiles/), with eventual goal being making most of IESDP data machine readable and available for consumption by external tools.

## Actions

Example: `Polymorph(I:AnimationType*Animate)`

```yaml
bg1: 1   # at least one game must be 1
bg2: 1
iwd1: 0  # 0's are optional, can be omitted, so this line and next 2 are not necessary
# iwd2: 0
# pst: 0

n: 146    # required - action number

name: Polymorph  # required, case sensitive, no parentheses

params:  # optional
  - name: AnimationType  # required, case sensitive
    type: i              # required 
    ids:  Animate        # optional, adds "*Animate" to the argument

not_tested: true  # optional, "untested" label
no_result: true   # optional, "does not work" label
unknown: true     # optional, "unknown" label
unreliable: true  # optional, "unreliable" label
alias: true       # optional, sets desc to "See N". By default N=n, but they aren't equal, alias can take a numerical value instead:
# alias: 147      # this sets desc to "See #147"

desc: |-          # optional
  This action causes the active creature to change animation to the specified animation (values from [animate.ids](/files/ids/bg2/animate.htm))
  ```
    IF
      !InPartyAllowDead("Aerie")
      !Dead("Aerie")
      !GlobalGT("AerieTransform","GLOBAL",0)
      Global("Aerie","AR0607",0)
      Global("KalahI","AR0607",0)
    THEN
      RESPONSE #100
        MoveGlobal("Ar0607","Aerie",[318.378])
        ChangeEnemyAlly("Aerie",NEUTRAL)
        SetGlobal("Aerie","AR0607",1)
        ActionOverride("Aerie",Polymorph(MAGE_FEMALE_ELF))
        ActionOverride("Aerie",SetBeenInPartyFlags())
        SetGlobal("AerieTransform","GLOBAL",2)
    END
  ```

`desc` field takes Markdown, HTML, Liquid. The preferred syntax is **Markdown**. HTML and Liquid should be used sparingly, only when there's no Markdown equivalent.


## File formats

File naming example: `_data/file_formats/itm_v1/extended_header.yml`.

Data is a yaml list of offsets. Example:

- desc: |            # required - markdown
    Attack type
    - 0 = None
    - 1 = Melee
  type: char         # required.
  length: 1          # optional, generally should be omitted, in which case, size inferred from type. Known types: char, byte, word, dword, resref, strref
  offset: 0x1        # optional, if specified, current offset is checked against this value, if not equal, an error is raised
                     # Generally, should only be specified for the first and last items in the list
  mult: 3            # optional, allows to do stuff like "2*3 (word)"
  unknown: 1         # optional, applies "unknown" style span
  unused: 1          # optional, appends " (unused)" to description and applies "unknown" style span
