# Team Transfer Mod Options

## Security
**Transfer To Enemies** - Checkbox (hidden)
- Default: false
- Implementation: Core validator, tie cheat mode/dev overrides explicitly

## Units
**Unit Sharing** - Dropdown
- Enabled (Default)
- T2 Constructor Sharing Only
- Disabled
- Implementation: Done

## Resources
**Resource Sharing Tax** - Numeric Input (0-100)
- Default: 0
- Note: overflow is fixed, when we can, as a function of tax. All taxable stuff works this way
- Implementation: Mostly done, except overflow.

**Player Metal Send Threshold** - Numeric Input (positive number)
- Default: 0
- Note: modifies tax
- Implementation: Done

## Unit Market
**Unit Market** - Checkbox
- Default: false
- Implementation: Mostly done but needs work for performance (filter what's for sale so dragon's teeth don't cause cthulhu) and UX improvements. Could be really cool feature.

## Allied Construction
**Allied Construction Assist** - Dropdown
- Enabled (Default)
- Economic Only
- Disabled
- Implementation: Parts of it are done @Chronopolize? Command validator for GUARD/BUILD commands

## T2 Mex Upgrades
**T2 Mex Upgrades** - Dropdown
- Keep (Default) - Owner keeps ownership
- Gift - Upgrader gets the mex
- Sell - Upgrader automatically provides market-style transaction with cost
- Implementation: Parts of it are done @Chronopolize? unit_mex_upgrade_reclaimer.lua logic