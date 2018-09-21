# 1&amp;1 DNSSEC signature checker

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Usage](#usage)

## Description

The 1&amp;1 DNSSEC signature checker checks one or more dnssec signed zones for keys expiring soon.

## Requirements

* Bash interpreter
* [bashlib](https://github.com/jwalzer/bashlib])

## Usage
Call parameters can be shown using parameter `-?`:
```
dnssec-check.bash [OPTS] <ZONES>
Options:
    -d           enable Debugging
    -m           enable machine-parsable output
    -w           warn-mode - only show warnings and only show seconds
    -c <file>    specify additional configfile to read
    -s <server>  select Server for DNS-Requests
    -g <days>    specify the number of grace days to warn
                 before expiration

    -t {types}   specify that recordtypes are following
    -z {zones}   specify that a list of zones are following

    -T <file>    read the list of types from file
    -Z <file>    read the list of zones from file
    if -T or -Z is suffixed by a "+" sign, the contents of the
    file will be added to the existing lists.
```