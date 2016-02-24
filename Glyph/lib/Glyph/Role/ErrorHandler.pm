package Glyph::Role::ErrorHandler;

use Moo::Role;
requires qw(trace);


use Method::Signatures;


##
## Attributes
##

has errors => (
    is        => 'lazy',
    isa       => sub { die unless ref($_[0]) eq 'ARRAY' },
    predicate => 1,
    clearer   => 1,
);


##
## Methods
##

method _build_errors {
    return [ ];
}


##
# Adds an error to the stack
method add_error ($args = 'error') {
    # Support one argument call form: add_error('name')
    unless (ref($args) eq 'HASH') {
        $args = { name => $args }
    }

    my $error = {
        name    => $args->{name}    || 'error',
        message => $args->{message} || 'unspecified error',
        details => $args->{details} || [ ],
    };

    $args->{details} = [ $args->{details} ] unless ref($args->{details}) eq 'ARRAY';

    push(@{$self->errors}, $error);

    $self->_log_error($error, $args->{level});

    return $error;
}


##
# Logs an error that was just added. The level is controllable for use cases
# where errors are expected and the caller doesn't want to spam the logs.
method _log_error ($error!, $level?) {
    # Default + sanity check the log level. We don't want to execute arbitrary
    # strings as methods.
    if ( ! defined($level) || $level !~ /^(?:note|error|warn|info|debug|trace)$/ ) {
        $level = 'error';
    }

    $self->$level({ 
        message => $error->message,
        name    => $error->name,
        #dump    => $self->dumpit($error->details), # TODO
    });
}


##
# Add stack of errors to the list, useful for promoting errors into another object
method push_errors ($errors = [ ]) {
    push(@{$self->errors}, @{$errors});
}


##
# Returns the most recently recorded error
method last_error {
    return $self->has_errors ? $self->errors->[-1] : undef;
}


##
# Look for a specific error name in the stack
method has_error_name($name!) {
    # Obviously, we need some errors if we're looking for a specific code
    return undef unless $self->has_errors;

    # Is it anywhere in the list?
    foreach my $error ( @{ $self->errors } ) {
        if ( $error->{name} eq $name ) {
            return $error;
        }
    }

    # Didn't find it
    return undef;
}


1;


=head1 NAME

Glyph::Role::ErrorHandling

=head1 SYNOPSIS

Role for handling errors in Glyph's

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
