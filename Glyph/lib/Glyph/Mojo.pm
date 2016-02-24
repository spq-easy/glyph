package Glyph::Mojo;

use Moo;
extends 'Mojolicious';
use namespace::clean;

use Method::Signatures;
use YAML::Syck();
use Template;

# The swagger spec could have other attributes at the same level as the hhtp
# method(s); only process a specific supported list
my @HTTP_METHODS = qw(get post put delete patch);

# Subclasses will set the builder
has service => (
    is => 'lazy',
);


# This method will run once at server start
method startup ($file) {
    my $config = $self->plugin('Config');
    $self->app->config($config);

    # Read in the swagger specification for the service
    my $spec = $self->read_swagger($file);

    # Create the routes for each endpoint defined in the spec, using controllerId
    # as the Endpoint package name
    $self->build_routes($spec);
}


method read_swagger ($lib_file) {
    $lib_file =~ s/(\w+)\.pm$/$1.yaml/;
    warn "=== Trying to read $lib_file\n";
    open(my $file, '<', $lib_file);

    local $/ = undef; # slurpy
    my $yaml = <$file>;

    die "Unable to read swagger spec" unless $yaml;

    my $spec = YAML::Syck::Load($yaml);

    return $spec;
}


method build_routes ($spec) {
    my $router = $self->routes;
    
    # Template object for processing route template
    my $tt = Template->new(
        {
            INTERPOLATE  => 0,
            ABSOLUTE     => 1,
        }
    ) || die $Template::ERROR . ".\n";

    my $template;
    {
        $/ = undef; # slurpy
        $template = <DATA>;
    }

    # Read through the parsed swagger spec and create a route handler for each
    # endpoint spcified in the spec.
    foreach my $path (keys %{$spec->{paths}}) {
        my @methods = keys %{$spec->{paths}{$path}};
        
        # Change swagger path syntax to Mojolicious route syntax
        my @parts = split('/', $path);
        shift(@parts); # leading slash causes undef in first index
        foreach my $part (@parts) {
            $part =~ s/\{(\w+)\}/*$1/;
        }

        my $mojo_path = '/' . join('/', @parts);
        warn "=== Adding handlers for $mojo_path\n";

        # For each http method for the same path
        foreach my $method (@methods) {
            next unless grep { $method eq $_ } @HTTP_METHODS;
            # The op_id is both the auto-generated route handler as well as the
            # final part of the services Endpoint class name to instantiate to
            # actually handle the details of the request processing
            my $op_id = $spec->{paths}{$path}{$method}{operationId};
            
            # TO DO: Generate the code from a template?
            my $route;
            my $code;
            $tt->process(\$template, {
                op_id => $op_id,
            }, \$code);

            # Nominal exception to the usual 'string eval is evil!'; alternate
            # suggestions welcome.
            eval "$code";

            my $name = ref($self) . "::Controller::$op_id";
            {
                no strict 'refs'; # Hoist the handler into the symbol table
                *$name = $route;
            }

            warn "===  $name added for controller#$op_id\n";
            $router->$method($mojo_path)->to("controller#$op_id",
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

__DATA__
$route = sub {
    my $c = shift;

    my $auth = $c->authenticate;

    my $class    = $c->base_classname . '::[% op_id %]';
    my $endpoint = $c->mofs($class, { controller => $c });

    my $result = $endpoint->execute_api;
}


