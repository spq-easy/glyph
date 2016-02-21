package Glyph::Mojo;

use Moo;
extends 'Mojolicious';
with qw(
    Glyph::Role::ErrorHandler
    Glyph::Role::LogHandler
);
use namespace::clean;

use Method::Signatures;
use YAML::Syck();


method read_swagger ($lib_file) {
    $lib_file =~ s/\w+\.pm$/swagger.yaml/;
    open(my $file, '<', $lib_file);

    local $/ = undef; # slurpy
    my $yaml = <$file>;

    my $spec = YAML::Syck::Load($yaml);

    return $spec;
}


method build_routes ($spec) {
    my $router = $self->routes;

    foreach my $path (keys %{$spec->{paths}}) {
        my @methods = keys %{$spec->{paths}{$path}};
        
        # Change swagger path syntax to Mojolicious route syntax
        my @parts = split('/', $path);
        foreach my $part (@parts) {
            $part =~ s/\{(\w+)\}/*$1/;
        }

        my $mojo_path = join('/', @parts);

        # For each http method for the same path
        foreach my $method (@methods) {
            # The op_id is both the auto-generated route handler as well as the
            # final part of the services Endpoint class name to instantiate to
            # actually handle the details of the request processing
            my $op_id = $spec->{paths}{$path}{$method}{operationId};
            
            # TO DO: Generate the code from a template?
            my $handler = sub { 
                my $c = shift;

                my $desc = $c->stash('spec')->{description};

                # Display closure and that we can read from the stash
                $c->render(text => "You have reached $op_id: $desc");

                # TODO: Create actual Endpoint object
                # TBD: Pass in the whole stash? $c? Something like compile_args?
            };

            my $name = ref($self) . "::Router::$op_id";
            {
                no strict 'refs'; # Hoist the handler into the symbol table
                *$name = $handler;
            }

            $router->$method($mojo_path)->to("router#$op_id",
                path   => \@parts,
                spec   => $spec->{paths}{$path}{$method},
                method => $method,
            );
        }
    }
    
}

1;


=head1 NAME

Glyph::Mojo

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
