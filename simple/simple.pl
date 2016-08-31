#!/usr/bin/env perl

use Web::Simple qw/MyApplication/;

{
    package MyApplication;

    use Data::Printer;
    use Plack::Builder;
    use Log::Minimal;
    use Git::Repository;
    use Digest::HMAC_SHA1 qw/hmac_sha1_hex/;
    use JSON;

    sub dispatch_request {

        'GET + /' => sub {
            my ($self, $env) = @_;
            debugf($self);
            infof($env);
            return [
                200,
                ['Content-type' => 'text/plain'],
                [ np($self) . "\n" . np($env) ]
            ];
        };
    }

    around to_psgi_app => sub {

        my ($orig, $self, $env) = @_;
        my $app = $self->$orig($env);

        builder {
            enable 'Plack::Middleware::Log::Minimal',
                loglevel => 'DEBUG',
                autodump => 1;
            $app;
        };
    };
}

MyApplication->run_if_script;
