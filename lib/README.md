# Gilded Rose rewritten

## Data Structures
The following data structures have been added:
- GildedRose.Category
- GildedRose.Date

1. GildedRose.Category has key pair category for storing category for each item. Categorizing items helps in managing their rules in updating quality.

2. GildedRose.Date holds the value of quality updated date. When compare with last update date, it helps managing the system.

3. GildedRose.item remains unchanged due to requirement.


## Seeding

### GildedRose Module
Seeding method is provided before start a new agent
Three .csv files is written by `GildedRose.seed()` to store the data (simulate a database) with the reference from seed.csv(Initial data provided)

### Seed Module
Seed module provides functions to write category and date data in data/category.csv and data/date.csv respectively.



## new()
Agent created with `GildedRose.new()` is linked with a map instead of a list. Three keys are :item, :cate, :date.


## update_quality()
Function in original module. The parameter is agent (pid). It will update sell_in date for every items (except Sulfuras Hand of Ragnaros) and update their quality by their own rules. Then set the date as today.