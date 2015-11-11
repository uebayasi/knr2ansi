#! /usr/bin/env perl

use strict;

main();

sub main {
	local $/;

	$_ = <>;

	while (m<
	    \A
	    (				# all
	    (.*?)			# aaa
	    (\n|\s*?)			# spc_before
	    ([A-Za-z_][A-Za-z0-9_]*?)	# func name
	    (\n|\s*?)			# spc_after
	    \s*?
	    \(
	    \s*
	    ([^\)]*?)			# arg names
	    \s*
	    \)
	    \s*?
	    \n
	    \s*?
	    ((?:[^\n]+?;[^\n]*?$)+)?	# arg types
	    \s*?
	    )
	    ^
	    (\s+?\{.*?\n*)		# zzz
	    \Z
	>mosx) {
		my $x = {
			'all' => $1,
			'aaa' => $2,
			'spc_before' => $3,
			'func_name' => $4,
			'spc_after' => $5,
			'arg_names' => $6,
			'arg_types' => $7,
			'zzz' => $8,
		};

		proc($x);

		$_ = $x->{zzz};
	}
	print $_;
}

sub proc {
	my ($x) = @_;

	if ($x->{func_name} =~ m<(?:if|for|while)>) {
		print $x->{all};
	} elsif ($x->{arg_names} && $x->{arg_types}) {
		dump1($x);
		parse_args($x);
		print
		    $x->{aaa},
		    $x->{spc_before},
		    $x->{func_name},
		    $x->{spc_after},
		    '(',
		    join(', ',
			map {
			    sprintf($x->{arg_types}->{$_}, $_);
			} @{$x->{arg_names}}
		    ),
		    ')',
		    "\n";
	} elsif (!$x->{arg_names} && !$x->{arg_types}) {
		dump1($x);
		print
		    $x->{aaa},
		    $x->{spc_before},
		    $x->{func_name},
		    $x->{spc_after},
		    '(void)',
		    "\n";
	} else {
		dump1($x);
		print
		    $x->{aaa},
		    $x->{spc_before},
		    $x->{func_name},
		    $x->{spc_after},
		    '(',
		    $x->{arg_names},
		    ')',
		    "\n";
	}
}

sub dump1 {
	my ($x) = @_;

	if (0) { return; }
	print STDERR 'func_name: ', $x->{func_name}, "\n";
	print STDERR 'arg_names: ', $x->{arg_names}, "\n";
	print STDERR 'arg_types: ', $x->{arg_types}, "\n";
}

sub dump2 {
	my ($x) = @_;

	if (0) { return; }
	foreach my $n (@{$x->{arg_names}}) {
		print STDERR
		    'arg_names: ',
		    $n,
		    "\n";
	}
	foreach my $t (keys %{$x->{arg_types}}) {
		print STDERR
		    'arg_typess: ',
		    $t,
		    ' => ',
		    $x->{arg_types}->{$t},
		    "\n";
	}
}

sub parse_args {
	my ($x) = @_;

	$x->{arg_names} = &parse_arg_names($x->{arg_names});
	$x->{arg_types} = &parse_arg_types($x->{arg_types});
	dump2($x);
}

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
