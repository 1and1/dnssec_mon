# 1&amp;1 DNSSEC signature expiry checker

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Usage](#usage)
1. [Configuration](#configuration)

## Description

The 1&amp;1 DNSSEC signature expiry checker checks one or more zones/records dnssec signatures for expiring in the near future.

## Requirements

* Bash interpreter
* [bashlib](https://github.com/jwalzer/bashlib)

## Usage
Call the tool with `dnssec-check.bash [OPTS] <ZONES>`
All parameters can also be specified as Bash-variables in a config-file or system environment:

| Parameter   | Variable                 | Meaning                                                    |
|-------------|--------------------------|------------------------------------------------------------|
| -?          | ---                      | Show cli usage description                                 |
| -c <file>   | CONFIG_TRY_LOAD <file>   | specify additional configfile to read                      |
| -s <server> | DNSSEC_RECURSOR=<server> | select Server for DNS-Requests                             |
| -g <days>   | RRSIG_GRACE_DAYS=<days>  | specify the number of grace days to warn before expiration |
| -d          | BASHLIB_DEBUG=True       | enable Debugging output                                    |
| -h          | ACTION="check"           | Generate human-readable output (default)                   |
| -m          | ACTION="parse"           | enable machine-parsable output                             |
| -w          | ACTION="warn"            | warn-mode - only show warnings and only show seconds       |
|-------------|--------------------------|------------------------------------------------------------|
| -t {types}  | TEST_TYPES=<types>               | specify that recordtypes are following             |
| -z {zones}  | TEST_ZONES=<zones>               | specify that a list of zones are following         |
| -T <file>   | TEST_TYPES="$(cat "<filename>")" | read the list of types from file                   |
| -Z <file>   | TEST_ZONES="$(cat "<filename>")" | read the list of zones from file                   |

if -T or -Z is suffixed by a "+" sign, the contents of the file will be added to the existing lists.
Any other params which don't match these option will be interpreted as zone or record type, depending on whether `-t` or `-z` was seen last, and added to the corresponding list.

## Configuration
By default, dnssec_mon will (in this order) try to load configuration from:
* \<scriptdir\>/../dnssec_mon.conf
* /etc/dnssec_mon.conf
* ~/.dnssec_mon.conf


All files are sourced by bash and therfore they need to be valid bash code. Later statements will override earlier statements. The 3 default files will always be tried and loaded if available, for disabling them you need to make them inaccessible by renaming or removing read permission, or override the values in a later config or with commandline parameters.

Commandline-parameters generally override values from config-files. But note that Zone- or Type-List can be overridden completely in a config file only, so cli-parameters -t/-z are append-only. 
