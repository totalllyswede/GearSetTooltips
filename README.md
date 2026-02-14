# ItemSetTooltip

A simple addon for World of Warcraft (Vanilla 1.12) that displays which ItemRack and/or Outfitter sets an item belongs to when you hover over items in your bags.

## Features

- Shows set membership on bag item tooltips
- Supports both ItemRack and Outfitter addons
- Automatically updates when you modify your sets
- Displays up to 5 sets per item (with count if more)
- Blue text for easy visibility

## Installation

1. Extract the `ItemSetTooltip` folder to your `World of Warcraft\Interface\AddOns\` directory
2. Restart WoW or reload UI (`/reload`)
3. The addon will automatically detect ItemRack and/or Outfitter

## Requirements

- World of Warcraft 1.12.1 (Vanilla)
- At least one of the following addons:
  - ItemRack
  - Outfitter

## Usage

Simply hover over any item in your bags. If the item is part of any gear sets, you'll see a blue line at the bottom of the tooltip showing which sets it belongs to.

Example:
```
Sets: PvP, Healing, Tank
```

## Commands

- `/ist` or `/itemsettooltip` - Show available commands
- `/ist update` - Manually refresh the set items cache

## Notes

- Only shows tooltips for items in bags (not equipped items or other locations)
- Automatically updates when you create, modify, or delete sets
- Ignores ItemRack internal sets (those starting with "ItemRack-" or "Rack-")

## Version

1.0

## Author

Olzon
