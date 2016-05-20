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

our $VERSION = '0.02';

our $request_id;

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

    $request_id = $env->{'psgix.request_id'}
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

options

    enable 'RequestId',
        http_header => 'X-Request-Id';

use another id generator if you want

    enable 'RequestId',
        id_generator => sub {
            Digest::MD5::md5_hex($$, time(), $env->{PATH_INFO})
        };

=head1 DESCRIPTION

Plack::Middleware::RequestId generates the request id and sets it into HTTP header.


=head1 MIDDLEWARE OPTIONS

=head2 http_header

The key string for an ID in HTTP Headers. default: C<X-Request-Id>

=head2 id_generator

The code ref for generating an ID. By default, using L<Data::UUID>.


=head1 METHODS

=over

=item prepare_app

=item call

=back


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Plack-Middleware-RequestId"><img src="https://secure.travis-ci.org/bayashi/Plack-Middleware-RequestId.png?_t=1443672845"/></a> <a href="https://coveralls.io/r/bayashi/Plack-Middleware-RequestId"><img src="https://coveralls.io/repos/bayashi/Plack-Middleware-RequestId/badge.png?_t=1443672845&branch=master"/></a>

=end html

Plack::Middleware::RequestId is hosted on github: L<http://github.com/bayashi/Plack-Middleware-RequestId>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

Rack::RequestId L<https://github.com/anveo/rack-request-id>

L<Data::UUID>

L<Plack::Middleware>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
