package Koha::Plugin::Com::BibLibre::LLMSearch::Controller;

use Modern::Perl;
use C4::Context;
use C4::Auth qw( get_session );
use Koha::Plugin::Com::BibLibre::LLMSearch;
use Mojo::Base 'Mojolicious::Controller';
use URI::Escape;
use Encode;
use JSON qw( encode_json decode_json );
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use Data::Dumper;

sub chat {
    my $c = shift;
    my $cookies = $c->req->cookies;
    warn Dumper($cookies);
    my $session;
    foreach my $cookie (@$cookies) {
	if ($cookie->{name} eq 'CGISESSID') {
	    $session = get_session( $cookie->{value} );
	    last;
	}
    }

    $c = $c->openapi->valid_input or return;
    return $c->render(
	status => 500,
	openapi => { error => "missing authorization from UI"}
	) if $session->is_new();

    my $plugin   = Koha::Plugin::Com::BibLibre::LLMSearch->new();
    my $api_key  = $plugin->retrieve_data('api_key');
    my $base_url = $plugin->retrieve_data('base_url');
    my $model    =  $plugin->retrieve_data('model');
    my $prompt   = $plugin->mbf_read('system_prompt.txt');

    return $c->render(
        status => 500,
        openapi => { error => "missing configuration" }
        ) unless $api_key and $base_url and $model;

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

    my $url = $base_url . "chat/completions";
    my $header = ['Content-Type' => 'application/json',
                  'Accept' => 'application/json',
                  'Authorization' => 'Bearer ' . $api_key];

    my $req = HTTP::Request->new('POST', $url, $header, encode_json($chat));
    my $response = $user_agent->request($req);

    if ( $response->is_success ) {
        return $c->render(
            status => 200,
            openapi => decode_json($response->decoded_content)
            );
    }

    return $c->render(
        status => 500,
        openapi => { error => $response->decoded_content }
        );
}
1;
