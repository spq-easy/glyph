package Glyph::Role::ObjectFactory;

use Moo::Role;
requires qw(trace add_error);

use Method::Signatures;


##
## Attributes
##

has mofsable => (
    is => 'lazy'
);


##
## Methods
##

method _build_mofsable {
    return [ qw(mofsable) ];
}


method mofs ($class!, $params = { }) {
    my $defaults = $self->mofsable_attributes;

    # Overwrite with anything passed in explicitly
    my $args = {%{$defaults}, %{$params}};

    $self->trace("Creating $class object from $self as source");

    eval "use $class";
    if ($@) {
        $self->add_error({
            name    => 'class_not_found',
            details => ["Error loading $class: $@"],
        });
        return;
    }

    my $obj = undef;

    eval {
        $obj = $class->new($args);
    };
    if ($@) {
        $self->add_error({
            name    => 'error',
            details => ["Error instantiating $class: $@"],
        });
        return;
    }

    unless (ref($obj)) {
        $self->add_error({
            name    => 'error',
            details => ["Error instantiating $class: No object returned by new"],
        });
        return $obj;
    }


    return $obj;
}


method mofsable_attributes {
    my $mofs_data = { };

    # Add required params
    foreach my $item ( @{$self->mofsable} ) {
        # First, check if item has predicate, and if so only pass through if set
        my $has = $item =~ /^_/
            ? "_has$item" # _private_attrib
            : "has_$item";
        
        if ( $self->can($has) ) {
            $mofs_data->{$item} = $self->$item if $self->$has;
        }
        else {
            $mofs_data->{$item} = $self->$item;
        }
    }

    return $mofs_data;
}


1;

=head1 NAME

Glyph::Role::ObjectFactory

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
