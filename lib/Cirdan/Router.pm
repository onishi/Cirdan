package Cirdan::Router;
use strict;
use Any::Moose;
use Cirdan::Router::Entry;
use Cirdan::Context;

has 'routes', (
    is  => 'rw',
    isa => 'ArrayRef[Cirdan::Router::Entry]',
    default => sub { +[] },
);

sub add {
    my ($self, $path, $method, $code) = @_;

    push @{$self->routes}, my $entry = Cirdan::Router::Entry->new(
        path => $path, method => $method, code => $code,
    );

    $entry;
}

sub dispatch {
    my ($self, $req) = @_;

    my $path = $req->uri->path;
    foreach my $entry (@{$self->routes}) {
        next unless $entry->handles_method($req->method);
        my (undef, @params) = $entry->handles_uri($req->uri) or next;
        Cirdan::Context->route($entry);
        return $entry->dispatch($req, @params);
    }
}

sub path_for {
    my ($self, $name, @args) = @_;

    foreach my $entry (@{$self->routes}) {
        if ($entry->name && $entry->name eq $name) {
            return $entry->make_path(@args);
        }
    }
}

sub make_routing_function {
    my ($self, $method) = @_;
    return sub {
        my $code = pop;
        my @path = @_;
        $self->add(@path > 1 ? \@path : $path[0], $method, $code);
    };
}

1;
