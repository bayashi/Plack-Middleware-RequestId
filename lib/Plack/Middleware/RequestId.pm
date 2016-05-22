package Plack::Middleware::RequestId;
use strict;
use warnings;
use 5.010000;

use Data::UUID;
use parent 'Plack::Middleware';
use Plack::Util;
use Plack::Util::Accessor qw/
    psgi_env_key
    http_header
    req_http_header
    id_generator
    force_generate_id
/;

our $VERSION = '0.04';

our $request_id;

sub prepare_app {
    my ($self) = @_;

    unless ($self->psgi_env_key) {
        $self->psgi_env_key('psgix.request_id');
    }

    unless ($self->http_header) {
        $self->http_header('X-Request-Id');
    }

    my $req_http_header = 'HTTP_'. uc $self->http_header;
    $req_http_header =~ s/-/_/g;
    $self->req_http_header($req_http_header);

    unless ($self->id_generator) {
        $self->id_generator(sub {
            state $ug = Data::UUID->new;
            substr $ug->create_hex, 2, 32;
        });
    }
}

sub call {
    my($self, $env) = @_;

    $request_id
        = $env->{$self->psgi_env_key}
            = (!$self->force_generate_id && $env->{$self->req_http_header})
            ? $env->{$self->req_http_header}
            : $self->id_generator->($env);

    my $res = $self->app->($env);

    $self->response_cb($res, sub {
        my $res = shift;
        if ($res) {
            Plack::Util::header_push(
                $res->[1],
                $self->http_header,
                $env->{$self->psgi_env_key},
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

See C<MIDDLEWARE OPTIONS> for other options.

=head1 DESCRIPTION

Plack::Middleware::RequestId generates the request id and sets it into HTTP header.


=head1 MIDDLEWARE OPTIONS

=head2 psgi_env_key

The key string for storing an ID in PSGI environment variables. default: C<psgix.request_id>

=head2 http_header

The key string for an ID in HTTP Headers. default: C<X-Request-Id>

=head2 id_generator

The code ref for generating an ID. By default, using L<Data::UUID>.

=head2 force_generate_id

If you set true value to this oprion, then the ID always generates every request no matter what there is C<X-Request-Id> header.


=head1 Getting ID TIPS

Normally, you get the request ID from PSGI env. However, the ID has been stored C<$Plack::Middleware::RequestId::request_id> also. So you can get it anywhere.


=head1 METHODS

=over

=item prepare_app

=item call

=back


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Plack-Middleware-RequestId"><img src="https://secure.travis-ci.org/bayashi/Plack-Middleware-RequestId.png?_t=1463920279"/></a> <a href="https://coveralls.io/r/bayashi/Plack-Middleware-RequestId"><img src="https://coveralls.io/repos/bayashi/Plack-Middleware-RequestId/badge.png?_t=1463920279&branch=master"/></a>

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
