#!/usr/bin/perl

use NagiosCacheParser;
use Data::Dumper;
use strict;


#
# Test with some sample files in the home directory
#
my $n = new NagiosCacheParser( { 
	$NAGIOS_STAT_FILE => '~/nagios.status.dat', 
	$NAGIOS_OBJ_FILE => '~/nagios.objects.cache', 
	});

# Turn on JSON sorting
$n->sort_json(1);

print $n->get_pretty_json;

# print Dumper $n->get_hosts;
# print $n->get_command_value( 'check_ftp', $COMMAND_LINE ) . "\n";
#
