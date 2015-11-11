#! /usr/bin/env perl

use strict;

local $/;

$_ = <>;
while (m<
    \A
    (.*?)
    (\n|\s*?)
    ([A-Za-z_][A-Za-z0-9_]*?)	# func name
    (\n|\s*?)
    \(([^\)]*?)\)		# arg names
    \n
    ((?:\s*[^\n]+?;[^\n]*?$)+)?	# arg types
    \s*?
    ^
    (\{.*?\n*)
    \Z
>mosx) {
	my ($a, $spc_before, $func_name, $spc_after, $arg_names, $arg_types, $b) = ($1, $2, $3, $4, $5, $6, $7);

	#print STDERR 'func_name: ', $func_name, "\n";
	#print STDERR 'arg_names: ', $arg_names, "\n";
	#print STDERR 'arg_types: ', $arg_types, "\n";

	if ($arg_names && $arg_types) {
		$arg_names = &parse_arg_names($arg_names);
		#foreach my $n (@$arg_names) { print STDERR 'arg_names: ', $n, "\n"; }
		$arg_types = &parse_arg_types($arg_types);
		#foreach my $t (keys %$arg_types) { print STDERR 'arg_typess: ', $t, ' => ', $arg_types->{$t}, "\n"; }

		print
		    $a,
		    $spc_before,
		    $func_name,
		    $spc_after,
		    '(',
		    join(', ',
			map {
			    sprintf($arg_types->{$_}, $_);
			} @$arg_names
		    ),
		    ')',
		    "\n";
	
		$_ = $b;
	} elsif (!$arg_names && !$arg_types) {
		print
		    $a,
		    $spc_after,
		    $func_name,
		    $spc_before,
		    '(void)',
		    "\n";
	
		$_ = $b;
	} else {
		print
		    $a,
		    $spc_after,
		    $func_name,
		    $spc_before,
		    '(',
		    $arg_names,
		    ')',
		    "\n";
	
		$_ = $b;
	}
}
print $_;

sub parse_arg_names {
	my ($arg_names) = @_;
	my @res = split(/[,\s]+/, $_[0]);
	return \@res;
}

sub parse_arg_types {
	my ($arg_types) = @_;
	my @lines = split(/\n/, $arg_types);
	my $res = {};
	foreach my $line (@lines) {
		$line =~ m<
		    \A
		    \s*
		    (.+?)
		    \s+?
		    ([*]*?)?
		    \s*
		    ([A-Za-z_][A-Za-z0-9_]*?)
		    (\[\d*?\])?
		    (,.+?)?
		    ;
		    (?:.*?)?	# comment, etc.
		    \Z
		>mosx;

#print STDERR 'XXX ', $line, " => name: ", $3, "\n";
#print STDERR 'XXX ', $line, " => type: ", $1, $2 ? (" " . "$2") : "", "\n";
#print STDERR 'XXX ', $1, $2, $3, $4, "\n";

		my $type = $1;

		$res->{$3} = "$type $2\%s$4";

		$line = $5;
		while ($line =~ m<
		    \A
		    ,
		    \s*
		    ([*]*?)?
		    \s*
		    ([A-Za-z_][A-Za-z0-9_]*?)
		    (\[\d*?\])?
		    (,.+?)?
		    \Z
		>mosx) {
			$res->{$2} = "$type $1\%s$3";
			$line = $4;
		}
		
	}
	return $res;
}
