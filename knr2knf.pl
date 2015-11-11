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
		print_statements($x);
	} elsif ($x->{arg_names} && $x->{arg_types}) {
		print_func_names_types($x);
	} elsif (!$x->{arg_names} && !$x->{arg_types}) {
		print_func_void($x);
	} else {
		print_func_misc($x);
	}
}

sub print_statements {
	my ($x) = @_;

	print $x->{all};
}

sub print_func_names_types {
	my ($x) = @_;

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
}

sub print_func_void {
	my ($x) = @_;

	dump1($x);
	print
	    $x->{aaa},
	    $x->{spc_before},
	    $x->{func_name},
	    $x->{spc_after},
	    '(void)',
	    "\n";
}

sub print_func_misc {
	my ($x) = @_;

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
		    (.+?)			# type
		    \s+?
		    ([*]*?)?			# a
		    \s*
		    ([A-Za-z_][A-Za-z0-9_]*?)	# name
		    (\[\d*?\])?			# b
		    (,.+?)?			# line
		    ;
		    (?:.*?)?			# comment, etc.
		    \Z
		>mosx;

		my $x = {
			'type' => $1,
			'a' => $2,
			'name' => $3,
			'b' => $4,
			'line' => $5,
			'comment' => $6,
		};

#print STDERR 'XXX ', $line, " => name: ", $x->{name}, "\n";
#print STDERR 'XXX ', $line, " => type: ", $x->{type}, $x->{a} ? (" " . "$x->{a}") : "", "\n";
#print STDERR 'XXX ', $x->{type}, $x->{a}, $x->{name}, $x->{b}, "\n";

		my $type = $x->{type};

		$res->{$x->{name}} = "$x->{type} $x->{a}\%s$x->{b}";

		$line = $x->{line};
		while ($line =~ m<
		    \A
		    ,
		    \s*
		    ([*]*?)?			# a
		    \s*
		    ([A-Za-z_][A-Za-z0-9_]*?)	# name
		    (\[\d*?\])?			# b
		    (,.+?)?			# line
		    \Z
		>mosx) {
			my $x = {
				'a' => $1,
				'name' => $2,
				'b' => $3,
				'line' => $4,
			};

			$res->{$x->{name}} = "$type $x->{a}\%s$x->{b}";
			$line = $x->{line};
		}

	}
	return $res;
}
