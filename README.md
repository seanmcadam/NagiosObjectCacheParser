#
#
#

#
# NagiosObjectCacheParser
Perl Library to parse Nagios Object Cache

#
# NagiosObjectCacheParserCGI
mod_perl library to access NagiosObjectCacheParser via a web interface


#
# Shared Memory
Added $NAGIOS_SHARED_MEMORY variable setting to enable sharing the parsed data 
across multiple instances, such as for a cgi-bin program running under apache

#
#
#
# -- TODO --
Create install (better) packaging

Split the read and write aspects of the shared memory, so the parser can run separatly from the readers


