package File::ShareDir::Override;

use strict;
use warnings;

# ABSTRACT: Override directories returned by File::ShareDir

# VERSION

use File::ShareDir;

my %dist_dirs;
my %module_dirs;

sub import {
    my ($package, $dir) = @_;

    return if !defined $dir;
    
    if ($dir =~ /:/) {
        map {
            my @opt = split /(?<!:):(?!:)/, $_;

            if ($opt[0] =~ /::/) {
                # module_dir ("Foo::Bar:/some/path")
                $module_dirs{$opt[0]} = $opt[2] || $opt[1];
            }
            elsif (defined $opt[2]) {
                if ($opt[1] eq 'dist') {
                    # dist_dir ("Foo:dist:/some/path")
                    $dist_dirs{$opt[0]} = $opt[2];
                }
                elsif ($opt[1] eq 'module') {
                    # module_dir ("Foo:module:/some/path")
                    $module_dirs{$opt[0]} = $opt[2];
                }
            }
            else {
                # Assume dist_dir ("Foo-Bar:/some/path" or "Foo:/some/path")
                $dist_dirs{$opt[0]} = $opt[1];
            }
        } split ',', $dir;
    }
    else {
        # TODO: Guess the distribution and the share directory?
    }
}

{
    my $_File_ShareDir_dist_dir = \&File::ShareDir::dist_dir;
    my $_File_ShareDir_dist_file = \&File::ShareDir::dist_file;
    my $_File_ShareDir_module_dir = \&File::ShareDir::module_dir;
    my $_File_ShareDir_module_file = \&File::ShareDir::module_file;

    no strict 'refs';
    no warnings 'redefine';

    *{"File::ShareDir::dist_dir"} = sub {
        my $dist = File::ShareDir::_DIST(shift);

        return $dist_dirs{$dist} || &$_File_ShareDir_dist_dir($dist);
    };

    *{"File::ShareDir::dist_file"} = sub {
        my $dist = File::ShareDir::_DIST(shift);
        my $file = File::ShareDir::_FILE(shift);

        if ($dist_dirs{$dist}) {
            return File::Spec->catfile($dist_dirs{$dist}, $file);
        }
        else {
            return &$_File_ShareDir_dist_file($dist, $file);
        }
    };

    *{"File::ShareDir::module_dir"} = sub {
        my $module = File::ShareDir::_MODULE(shift);

        return $module_dirs{$module} || &$_File_ShareDir_module_dir($module);
    };
    
    *{"File::ShareDir::module_file"} = sub {
        my $module = File::ShareDir::_MODULE(shift);
        my $file = File::ShareDir::_FILE(shift);

        if ($module_dirs{$module}) {
            return File::Spec->catfile($module_dirs{$module}, $file);
        }
        else {
            return &$_File_ShareDir_module_file($module, $file);
        }
    };
}

1;

__END__

=head1 SYNOPSIS

Run C<program.pl> and make Foo::Bar think its distribution's shared directory is
C<./share>:
    
    perl -MFile::ShareDir::Override=Foo-Bar:./share program.pl

Pretend Foo::Bar's module shared directory is C<./lib>:

    perl -MFile::ShareDir::Override=Foo::Bar:./lib program.pl

=head1 DESCRIPTION

(TBA)

Top-level modules/distributions (e.g., Dancer or Plack) don't have any dashes or
double colons in the name and can't be recognized, so they need an explicit
C<:dist> or C<:module> between the name and path. Example:

    perl -MFile::ShareDir::Override=Foo:module:./lib program.pl
