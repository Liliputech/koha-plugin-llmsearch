package Koha::Plugin::Com::BibLibre::LLMSearch::Controller;

use Modern::Perl;
use C4::Context;
use C4::Auth qw( get_session );
use Koha::Plugin::Com::BibLibre::LLMSearch;
use Koha::Patron;
use Koha::DateUtils qw( dt_from_string );
use Mojo::Base 'Mojolicious::Controller';
use URI::Escape;
use Encode;
use JSON qw( encode_json decode_json );
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

our $plugin = Koha::Plugin::Com::BibLibre::LLMSearch->new();

sub welcome {
    my $c = shift->openapi->valid_input or return;
    return $c->render(
	status => 200,
	openapi => $plugin->retrieve_data('welcome'),
        );
}

sub chat {
    my $c = shift;
    my $cookies = $c->req->cookies;

    my $session;
    my $opac_lang;
    foreach my $cookie (@$cookies) {
        if ($cookie->{name} eq 'CGISESSID') {
            $session = get_session( $cookie->{value} );
        }
        if ($cookie->{name} eq 'KohaOpacLanguage') {
            $opac_lang = $cookie->{value};
        }
    }

    return $c->render(
        status => 500,
        openapi => { error => "missing authorization from UI"}
        ) if $session->is_new();

    $c = $c->openapi->valid_input or return;

    my $api_key  = $plugin->retrieve_data('api_key');
    my $base_url = $plugin->retrieve_data('base_url');
    my $model    = $plugin->retrieve_data('model');
    my $prompt   = $plugin->retrieve_data('system_prompt');

    return $c->render(
        status => 500,
        openapi => { error => "missing configuration" }
        ) unless $base_url and $model;

    my $user_agent = LWP::UserAgent->new;
    $user_agent->agent("KohaLLMSearch");

    my $json = $c->validation->param('json');
    $json = uri_unescape($json);
    my $previous_chat;
    if ($json =~ /json=(.*)/) {
        $previous_chat = decode_json($1);
    }

    my @messages = ({ "role" => "system", "content" => $prompt });

    foreach my $message (@$previous_chat) {
        $message->{content} =~ s/\+/ /g;
        push @messages, $message;
    }

    my $chat = { model => $model, messages => [@messages] };

    my $header = ['Content-Type' => 'application/json',
                  'Accept' => 'application/json',
                  'Authorization' => 'Bearer ' . $api_key];

    my $req = HTTP::Request->new('POST', $base_url, $header, encode_json($chat));
    my $response = $user_agent->request($req);

    if ( $response->is_success ) {
        my $response_data = decode_json($response->decoded_content);

        log_request({ lang => $opac_lang, data => $response_data});
        return $c->render(
            status => 200,
            openapi => $response_data
        );
    }

    return $c->render(
        status => 500,
        openapi => { error => $response->decoded_content }
        );
}

sub log_request {
    my $args      = shift;
    my $opac_lang = $args->{'lang'};
    my $response  = $args->{'data'};

    return 1 unless ( $plugin->retrieve_data('enable_stats') );

    my $userenv = C4::Context->userenv;
    my $patron = Koha::Patrons->find($userenv->{'number'})->unblessed();

    my $dbh = C4::Context->dbh;
    my $table = $plugin->get_qualified_table_name('stats');

    my $query = "INSERT INTO $table (
                     opac_lang,
                     tokens_sent,
                     tokens_received
                 ) VALUES (
                     '$opac_lang',
                     '$response->{usage}{prompt_tokens}',
                     '$response->{usage}{completion_tokens}'
                 )";

    return $dbh->do($query) unless $patron;

    my $enrolledyear = dt_from_string($patron->{dateenrolled}, undef, undef)->year;
    my $birthyear = dt_from_string($patron->{dateofbirth}, undef, undef)->year;
    $query = "
        INSERT INTO $table (
            categorycode,
            branchcode,
            enrolled_year,
            birth_year,
            sort1,
            sort2,
            opac_lang,
            tokens_sent,
            tokens_received
        ) VALUES (
            '$patron->{categorycode}',
            '$patron->{branchcode}',
            '$enrolledyear',
            '$birthyear',
            '$patron->{sort1}',
            '$patron->{sort2}',
            '$opac_lang',
            '$response->{usage}{prompt_tokens}',
            '$response->{usage}{completion_tokens}'
        )";

    return $dbh->do($query);
}
1;
