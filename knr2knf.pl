#! /usr/bin/env perl

use strict;

main();

sub main {
	local $/;
	my $content = <>;
	while ($content =~ m<
	    \A
	    (.*?)			# AAA
	    (				# ALL
	    (\n|\s*?)			# spc_before
	    ([A-Za-z_][A-Za-z0-9_]*?)	# func_name
	    (\n|\s*?)			# spc_after
	    \s*?
	    \(
	    \s*
	    ([^\)]*?)			# arg_names_str
	    \s*
	    \)
	    \s*?
	    ([A-Za-z_][^{/*]*?;[^{/*A-Za-z_]*?)	# arg_types_str
	    )				# (ALL)
	    ((?:\n*?\s*?)?\{.*)		# ZZZ
	    \Z
	>mosx) {
		my $x = {
			'AAA' => $1,
			'ALL' => $2,
			'spc_before' => $3,
			'func_name' => $4,
			'spc_after' => $5,
			'arg_names_str' => $6,
			'arg_types_str' => $7,
			'ZZZ' => $8,
		};
		proc($x);
		$content = $x->{ZZZ};
	}
	print $content;
}

sub proc {
	my ($x) = @_;
	if ($x->{func_name} =~ m<(?:if|for|while)>) {
		print_stmt($x);
	} else {
		print_func($x);
	}
}

sub print_stmt {
	my ($x) = @_;
	print $x->{AAA}, $x->{ALL};
}

sub print_func {
	my ($x) = @_;
	dump1($x);
	my $arg_names;
	if ($x->{arg_names_str} && $x->{arg_types_str}) {
		parse_args($x);
		$arg_names = print_func_arg_names($x);
	} elsif (!$x->{arg_names_str} && !$x->{arg_types_str}) {
		$arg_names = 'void';
	} else {
		$arg_names = $x->{arg_names};
	}
	print
	    $x->{AAA},
	    $x->{spc_before},
	    $x->{func_name},
	    $x->{spc_after},
	    '(',
	    $arg_names,
	    ')';
}

sub dump1 {
	my ($x) = @_;
	if (0) { return; }
	print STDERR 'func_name: ', $x->{func_name}, "\n";
	print STDERR 'arg_names: ', $x->{arg_names_str}, "\n";
	print STDERR 'arg_types: ', $x->{arg_types_str}, "\n";
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
	foreach my $t (keys %{$x->{arg_fmts}}) {
		print STDERR
		    'arg_types: ',
		    $t,
		    ' => ',
		    $x->{arg_fmts}->{$t},
		    "\n";
	}
}

sub parse_args {
	my ($x) = @_;
	$x->{arg_names} = &parse_arg_names($x->{arg_names_str});
	$x->{arg_fmts} = &parse_arg_types($x->{arg_types_str});
	dump2($x);
}

sub parse_arg_names {
	my ($arg_names_str) = @_;
	return [split(/[,\s]+/, $arg_names_str)];
}

# XXX split by ';', then ','
# XXX de-duplicate match pattern
sub parse_arg_types {
	my ($arg_types) = @_;
	my @lines = split(/\n/, $arg_types);
	my $fmts = {};
	foreach my $line (@lines) {
		$line =~ m<
		    \A
		    \s*
		    (.+?)			# type
		    \s+?
		    ([*]*?)?			# ptr
		    \s*
		    ([A-Za-z_][A-Za-z0-9_]*?)	# name
		    (\[\d*?\])?			# array
		    (,.+?)?			# line
		    ;
		    (?:.*?)?			# comment, etc.
		    \Z
		>mosx;
		my $type = $1;
		my $x = {
			'type' => $1,
			'ptr' => $2,
			'name' => $3,
			'array' => $4,
			'line' => $5,
			'comment' => $6,
		};
		parse_arg_types_iter($fmts, $x);
		$line = $x->{line};
		while ($line =~ m<
		    \A
		    ,
		    \s*
		    ([*]*?)?			# ptr
		    \s*
		    ([A-Za-z_][A-Za-z0-9_]*?)	# name
		    (\[\d*?\])?			# array
		    (,.+?)?			# line
		    \Z
		>mosx) {
			my $x = {
				'type' => $type,
				'ptr' => $1,
				'name' => $2,
				'array' => $3,
				'line' => $4,
			};
			parse_arg_types_iter($fmts, $x);
			$line = $x->{line};
		}
	}
	return $fmts;
}

# XXX ugly
sub parse_arg_types_iter {
	my ($fmts, $x) = @_;
	dump3($x);
	$fmts->{$x->{name}} = "$x->{type} $x->{ptr}\%s$x->{array}";
}

sub print_func_arg_names {
	my ($x) = @_;
	# XXX Perl not being functional yet!
	return join(', ',
		map {
			print_func_arg($x, $_);
		} @{$x->{arg_names}}
	);
}

sub print_func_arg {
	my ($x, $name) = @_;
	sprintf($x->{arg_fmts}->{$name}, $name);
}

sub dump3 {
	my ($x) = @_;
	if (1) { return; }
	print STDERR 'arg_types: ', $x->{type}, $x->{ptr}, $x->{name}, $x->{array}, "\n";
}
