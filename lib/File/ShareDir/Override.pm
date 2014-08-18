package File::ShareDir::Override;

use strict;
use warnings;

# ABSTRACT: Override directories returned by File::ShareDir

# VERSION

use File::ShareDir;

my %dist_dirs = ();

sub import {
    my ($package, $dir) = @_;

    return if !defined $dir;
    
    if ($dir =~ /:/) {
        map {
            my ($dist, $dir) = split ':', $_;
            $dist_dirs{$dist} = $dir;
        } split ',', $dir;
    }
    else {
        # TODO: Guess the distribution and the share directory?
    }
}

{
    my $_File_ShareDir_dist_dir = \&File::ShareDir::dist_dir;

    no strict 'refs';
    no warnings 'redefine';
    *{"File::ShareDir::dist_dir"} = sub {
        my ($dist) = File::ShareDir::_DIST(shift);

        return $dist_dirs{$dist} || &$_File_ShareDir_dist_dir($dist);
    };
}

1;

__END__

=head1 SYNOPSIS

Run C<program.pl> and make Foo::Bar think its share directory is C<./share>:
    
    perl -MFile::ShareDir::Override=Foo-Bar:./share program.pl
