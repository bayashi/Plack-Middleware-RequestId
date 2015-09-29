package Plack::Middleware::RequestId;
use strict;
use warnings;
use 5.010000;

use Data::UUID;
use parent 'Plack::Middleware';
use Plack::Util;
use Plack::Util::Accessor qw/
    http_header
    id_generator
/;

our $VERSION = '0.01';

sub prepare_app {
    my ($self) = @_;

    unless ($self->http_header) {
        $self->http_header('X-Request-Id');
    }

    unless ($self->id_generator) {
        $self->id_generator(sub {
            state $ug = Data::UUID->new;
            substr $ug->create_hex, 2, 32;
        });
    }
}

sub call {
    my($self, $env) = @_;

    $env->{'psgix.request_id'}
        = $env->{$self->http_header} || $self->id_generator->($env);

    my $res = $self->app->($env);

    $self->response_cb($res, sub {
        my $res = shift;
        if ($res) {
            Plack::Util::header_push(
                $res->[1],
                $self->http_header,
                $env->{'psgix.request_id'},
            );
        }
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Plack::Middleware::RequestId - generate the request id


=head1 SYNOPSIS

    enable 'RequestId';


=head1 DESCRIPTION

Plack::Middleware::RequestId generates the request id and sets it into HTTP header.


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Plack-Middleware-RequestId"><img src="https://secure.travis-ci.org/bayashi/Plack-Middleware-RequestId.png"/></a> <a href="https://coveralls.io/r/bayashi/Plack-Middleware-RequestId"><img src="https://coveralls.io/repos/bayashi/Plack-Middleware-RequestId/badge.png?branch=master"/></a>

=end html

Plack::Middleware::RequestId is hosted on github: L<http://github.com/bayashi/Plack-Middleware-RequestId>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Plack::Middleware>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
