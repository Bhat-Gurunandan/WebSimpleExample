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

    my $config = {
        git             => '/usr/bin/git',
        secret          => '********',
        git_work_tree   => '/home/nandan/repos/AlmostIsland',
        committer_email => 'gbhat@pobox.com',
        committer_name  => 'Gurunandan Bhat',
        site_builder    => '/home/nandan/repos/AICode/bin/aiweb.pl test',
        email_list      => [
            'gbhat@pobox.com',
            'rhymebawd@gmail.com',
        ],
    };

    sub dispatch_request {

        'POST + /sync' => sub {

            my ($self, $env) = @_;
            my $repo    = $self->repo($env);

            return [
                200,
                ['Content-type' => 'text/plain'],
                [ $repo->build ],
            ];
        }
    }

    sub repo {

        my ($self, $env) = @_;
        my $req = Plack::Request->new($env);

        $payload = decode_json( $req->raw_body );
        my $digest  = $req->headers->header('X-Hub-Signature');
        my $check   = 'sha1=' . hmac_sha1_hex($payload, 'StriverConniver');

        return Git::Repository->new(
            work_tree => '/home/nandan/repos/AlmostIsland', {
                git => '/usr/local/bin/git',
                env => {
                    GIT_COMMITTER_EMAIL => 'gbhat@pobox.com',
                    GIT_COMMITTER_NAME  => 'Gurunandan Bhat',
                },
            }
        );
    }

    sub build {

        my $self = shift;

        my $head_commit = $self->repo->run('rev-parse' => 'HEAD');

        my @log;
        if ( $head_commit ne $payload->{head_commit}{id} ) {

            @log = $self->run(reset => '--hard', 'mycopy/master');
            push @log, ($self->run(pull => 'mycopy',  'master'));

            my @action = `/home/nandan/repos/AICode/bin/aiweb.pl test`;
            push @log, @action;

            push @log, ($self->run(add => '.'));
            push @log, ($self->run(commit => '-m', sprintf('Automated Build %s', scalar localtime)));
            push @log, ($self->run(push => 'mycopy', 'master'));
            push @log, ($self->run(push => 'origin', 'master'));
        }

        return Dumper(\@log);
    }

    sub send_email {

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
