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
		print_stmt($x);
	} else {
		print_func($x);
	}
}

sub print_stmt {
	my ($x) = @_;
	print $x->{all};
}

sub print_func {
	my ($x) = @_;
	dump1($x);
	if ($x->{arg_names} && $x->{arg_types}) {
		parse_args($x);
		$x->{arg_names} = join(', ',
		    map {
			sprintf($x->{arg_types}->{$_}, $_);
		    } @{$x->{arg_names}}
		);
	} elsif (!$x->{arg_names} && !$x->{arg_types}) {
		$x->{arg_names} = 'void';
	} else {
	}
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

# XXX split by ','
# XXX de-duplicate match pattern
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
		parse_arg_types_iter(\$line, $res, $x);
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
			parse_arg_types_iter(\$line, $res, $x);
		}
	}
	return $res;
}

# XXX
sub parse_arg_types_iter {
	my ($lineref, $res, $x) = @_;
	dump3($x);
	$res->{$x->{name}} = "$x->{type} $x->{ptr}\%s$x->{array}";
	${$lineref} = $x->{line};
}

sub dump3 {
	my ($x) = @_;
	if (1) { return; }
	print STDERR 'arg_types: ', $x->{type}, $x->{ptr}, $x->{name}, $x->{array}, "\n";
}
