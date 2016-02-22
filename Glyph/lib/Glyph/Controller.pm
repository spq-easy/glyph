package Glyph::Controller;

# All the common code for service routers

use Moo;
extends qw(Mojolicious::Controller);
with qw(
    Glyph::Role::ErrorHandler
    Glyph::Role::LogHandler
);
use namespace::clean;

use Method::Signatures;


# This will be the base classname to instantiate for handling the request
has base_classname => (
    is => 'lazy',
);


1;


=head1 NAME

Glyph::Controller

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
