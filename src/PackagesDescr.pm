#! /usr/bin/perl -w
# File:		modules/PackagesDescr.pm
# Package:	Add-On creator
# Summary:	Module for parsing package descriptions
# Author:	Jiri Suchomel <jsuchome@suse.cz>

package PackagesDescr;

use strict;
use YaST::YCP qw(:LOGGING);

our %TYPEINFO;

YaST::YCP::Import ("FileUtils");
YaST::YCP::Import ("SCR");

#---------------------------------------------------------------------
#--------------------------------------------------------- definitions


my %description		= ();
my $version		= "";
my $err_no		= 0;

# which keys have multiline values
my %multiple		= (
    "Des"	=> 1,
    "Ins"	=> 1,
    "Del"	=> 1,
    "Eul"	=> 1
);

# parse the input file (given as argument) and fill the %description hash
sub parse_file {

    my $file	= shift;

    if (! FileUtils->Exists ($file)) {
	y2warning ("$file is not available!");
	return 0;
    }
    my $in	= SCR->Read (".target.string", $file);

    if (! defined $in) {
	y2warning ("$file cannot be opened for reading!");
	$err_no		= 1;
	return 0;
    }
    my $pkg_name	= "___global___"; # global values, before first Pkg
    my $multiline_key	= "";
    my $multiline_val	= "";
    %description	= ();
    $version		= "";

    foreach my $line (split (/\n/,$in)) {
	chomp $line;
	if ($line =~ /^=([\w]+):[ \t]*(.*)/) {
	    my $key	= $1;
	    my $val	= $2;
	    if ($key eq "Pkg") {
		$pkg_name	= $val;
#		($pkg_name)	= ($val =~ /([^ \t]*).*/);
		$description{$pkg_name}	= {
		    "Pkg"	=> $val
		};
	    }
	    else {
		if ($key eq "Ver") {
		    $version	= $val;
		}
		else {
		    $description{$pkg_name}{$key}	= $val;
		}
	    }
	}
	elsif ($line =~ /^\+([\w]+):.*/) {
	    $multiline_key	= $1;
	    $multiline_val	= "";
	}
	elsif ($line =~ /^\-([\w]+):.*/) {
	    if ($multiline_key eq $1) {
		$description{$pkg_name}{$multiline_key}	= $multiline_val;
	    }
	    else {
		y2error ("ending key is $1, while starting was $multiline_key");
	    }
	}
	elsif ($multiline_key) {
	    $multiline_val	= $multiline_val."\n" if ($multiline_val);
	    $multiline_val      = $multiline_val.$line;
	}
    }
    return 1;
}

sub write_file {

}

# --------------------------------------- main -----------------------------

BEGIN { $TYPEINFO{Read} = ["function",
    ["map", "string", "any"],
    "string"]
}
sub Read {

    my $self	= shift;
    my $file	= shift;
    my $ret	= {};
    
    if (parse_file ($file)) {
	$ret	= \%description;
    }
    return \%description;
}

# write the file with description; 1st argument is path, 2nd data hash
BEGIN { $TYPEINFO{Write} = ["function",
    "boolean",
    "string", ["map", "string", "any"]]
}
sub Write {

    my $self	= shift;
    my $file	= shift;
    my $descr	= shift;

    if (ref ($descr) ne "HASH" || !%{$descr}) {
	y2error ("data not hash or empty");
	$err_no	= 10;
	return 0;
    }
    my $cont	= "";
    $cont	= "=Ver: $version\n" if $version;
    # sort order: system items go before local ones
    foreach my $pkg_name (sort keys %{$descr}) {
	my $data	= $descr->{$pkg_name};
	next if (ref $data ne "HASH");
	if ($pkg_name ne "___global___") {
	    $cont	= $cont."##----------------------------------------\n";
	    # let the Pkg key is first
	    if (defined $data->{"Pkg"}) {
		my $val	= $data->{"Pkg"};
		$cont	= $cont."=Pkg: $val\n";
		delete $data->{"Pkg"};
	    }
	}
	while (my ($key, $val) = each %{$data}) {
	    next if (!$val);
	    if (defined $multiple{$key}) {
		$cont	= $cont."+$key:\n$val\n-$key:\n";
	    }
	    else {
		$cont	= $cont."=$key: $val\n";
	    }
	}
    }
    return SCR->Write (".target.string", $file, $cont);
}
42
# end
