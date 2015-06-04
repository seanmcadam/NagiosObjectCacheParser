#!/usr/bin/perl

use NagiosObjectCacheParser;
use Data::Dumper;
use strict;


#
# Test with some sample files in the home directory
#
my $n = new NagiosObjectCacheParser( { 
	$NAGIOS_STAT_FILE => '../../nagios.status.dat', 
	$NAGIOS_OBJ_FILE => '../../nagios.objects.cache', 
	});

# Turn on JSON sorting
$n->sort_json(1);

print $n->get_pretty_json;

# print $n->get_command_value( 'check_ftp', $COMMAND_LINE ) . "\n";
#

# my @hosts = $n->get_hosts;
# foreach my $h (@hosts) {
# 	print $h . ":" . $n->get_host_value($h, $ALIAS) . "\n";
# }
