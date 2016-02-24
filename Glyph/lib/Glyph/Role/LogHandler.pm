package Glyph::Role::LogHandler;

use Moo::Role;
requires qw(service);

use Method::Signatures;
use Data::Dumper;
use JSON ();
use Digest::MD5 qw(md5_hex);

use Carp qw(confess cluck carp croak);
our @CARP_NOT = qw(Glyph::Role::LogHandler
                   Glyph::Role::ErrorHandler);


# TO DO: Encapsulate actual logging into a log object which could be replaced by
# a log4perl or similar object with the same log level methods

##
## Attributes
##

has log_level => (
    is        => 'rw',
    builder   => 1,
    lazy      => 1,
    predicate => 1,
);

has log_category => (
    is => 'lazy',
);

# A longish string to be using as a key in logs, so multiple log entries for a
# single flow can be easily queried.
has tracking_id => (
    is        => 'rw',
    lazy      => 1,
    predicate => 1,
    clearer   => 1,
    # Adding '.G' to the end of ids we generate so we can tell at a glance if one in the
    # log was auto-generated here
    default   => sub { return md5_hex(__PACKAGE__ . rand(10000) . localtime) . '.G' },
);

has logfile => (
    is      => 'lazy',
);

has log_dir => (
    is      => 'lazy',
);

has params_to_mask => (
    is => 'lazy',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = ref $_[0] ? $_[0] : {@_};

    # XXX: Is there a better name for an environment variable than LOG_LEVEL?
    # Should it be $orig =~ /(\w+)$/; $ENV{$1 . '_LOG_LEVEL'} ?
    if (! exists $args->{log_level} && exists $ENV{LOG_LEVEL}) {
        $args->{log_level}  = $ENV{LOG_LEVEL};
    }

    # if log level provided as a string - would be a good spot for given/when
    if (exists $args->{log_level} && $args->{log_level} =~ /\D/) {
        my $level = $args->{log_level};
        if    (lc($level) eq 'trace') { $level = 3 }
        elsif (lc($level) eq 'debug') { $level = 2 }
        elsif (lc($level) eq 'info')  { $level = 1 }
        else                          { $level = 0 }

        $args->{log_level} = $level;
    }

    return $class->$orig($args);
};

method _build_log_category {
    return ref(shift);
}

method _build_log_dir {
    my $log_dir = '/var/log';

    unless (-w $log_dir) {
        $log_dir = '/tmp';
    }

    return $log_dir;
}

method _build_logfile {
    my $pkg = ref($self);

    (my $api_version) = $self->app->config('version') =~ /^(\d+)\.\d+$/;
    $api_version //= '0';

    my $ver = $self->app->config('mode')
        ? substr($self->app->config('mode'),0,1) . $api_version
        : 'd0';

    return $self->service . "-$ver.log";
}

method _build_params_to_mask {
    my @params = qw(password access_token refresh_token fb_exchange_token api_key client_secret);
    return \@params;
}


my %Level_Value = (
    trace => 3,
    debug => 2,
    info  => 1,
    note  => 0, # note should always just write_log
    gripe => 0,
    warn  => 0,
    error => 0,
    fatal => 0,
    log   => 0,
);


method write_log ($obj, $level = 'note') {

    if ($level ne 'note') {
        # Setting log_level to -1 effectively silences logging on levels
        return unless $self->log_level >= $Level_Value{$level};
    }

    unless (ref($obj) eq 'HASH') {
        $obj = { message => $obj };
    }


    my $filename = join('/', $self->log_dir, $self->logfile);

    open(my $log, '>>', $filename);
    unless ($log) {
        # We failed to open the logfile, but we don't want to loose the output
        # or kill the program if we can avoid it. Try to use STDERR instead.
        my $orig_error = $!;
        open($log, '>&', \*STDERR)
            or die "Unable to write to log ($filename): $orig_error. " .
            "Additionally failed to open to STDERR as backup: $!";

        print $log "Failed to open $filename for logging because '$orig_error': "
            . 'using STDERR instead.';
    }


    # Try to find the first caller in stack _not_ in our CARP_NOT list.
    my $clevel = 1;
    my @call = caller($clevel);
    $call[0] ||= '';
    while (grep { $call[0] eq $_ } @CARP_NOT) {
        @call = caller(++$clevel);
    }


    $obj->{message} =~ s/\n/ /g;

    $obj->{timestamp}    ||= localtime;
    $obj->{log_category} ||= $self->log_category;
    $obj->{tracking_id}  ||= $self->tracking_id;
    $obj->{level}        ||= $level;
    $obj->{caller}       ||= [@call[0..2]];


    # A failure to convert to JSON and log should never be fatal to the application
    eval {
        print $log JSON::to_json($obj), "\n";
    };
    if ($@) {
        # But warn about it (usually caught by mojo service log), just in case
        warn "ERROR: Unable to write out log message: $@";
    }
}


# Could this delegate with currying and get 'trace' etc to the last arg?
method trace ($obj) {
    $self->write_log($obj, 'trace');
}


method debug ($obj) {
    $self->write_log($obj, 'debug');
}


method info ($obj) {
    $self->write_log($obj, 'info');
}


method note ($obj) {
    $self->write_log($obj, 'note');
}


method warn ($obj) {
    unless (ref($obj) eq 'HASH') {
        $obj = { message => $obj };
    }

    carp($obj->{message}); # split logging
    $self->write_log($obj, 'warn');
}


method error ($obj) {
    unless (ref($obj) eq 'HASH') {
        $obj = { message => $obj };
    }

    # split logging
    if ($self->log_level >= $Level_Value{debug}) {
        # STDERR the stack trace when we throw an error in debug or trace modes
        cluck($obj->{message});
    }
    else { carp($obj->{message}) }

    $self->write_log($obj, 'error');
}


method fatal ($obj) {
    unless (ref($obj) eq 'HASH') {
        $obj = { message => $obj };
    }

    $self->write_log($obj, 'fatal');

    if ($self->log_level >= $Level_Value{debug}) {
        # Die with a stack trace when we fatal in debug or trace modes
        confess($obj->{message});
    }
    else { croak($obj->{message}) }
}

# Note: this function is providing a little redundancy and should only be used if the
# contents of what is being logged involve some processing and we don't want to take
# the hit for interpolation. The common case is when including a 'dump' entry 
# (Data::Dumper etc) in the log entry.
method is_log_level ($level) {
    # Are we logging at this level? Defaults to checking against 0, which will always
    # return true if you pass in something meaningless.
    return ($self->log_level >= ($Level_Value{$level} || 0));
}



1;


=head1 NAME

Glyph::Role::LogHandler

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 METHODS

=over

=item B<foo($required!, $optional?)>

=back

=head1 SEE ALSO

=head1 AUTHOR

Sean P Quinlan

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Sean P Quinlan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
