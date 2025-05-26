package Koha::Plugin::Com::BibLibre::LLMSearch::Controller;

use Modern::Perl;
use C4::Context;
use Koha::Plugin::Com::BibLibre::LLMSearch;
use Mojo::Base 'Mojolicious::Controller';
use JSON qw( encode_json decode_json );
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use Data::Dumper;

sub chat {
    my $c = shift->openapi->valid_input or return;

    my $plugin   = Koha::Plugin::Com::BibLibre::LLMSearch->new();
    my $api_key  = $plugin->retrieve_data('api_key');
    my $base_url = $plugin->retrieve_data('base_url');
    my $model    =  $plugin->retrieve_data('model');
    my $prompt   = $plugin->mbf_read('system_prompt.txt');

    my $user_agent = LWP::UserAgent->new;
    $user_agent->agent("KohaLLMSearch");

    my $user_query = $c->validation->param('query');
    my $url = $base_url . "chat/completions";
    my $header = ['Content-Type' => 'application/json',
		  'Accept' => 'application/json',
		  'Authorization' => 'Bearer ' . $api_key];
    my $chat = {
        model => $model,
	messages => [
	    { "role" => "system", "content" => $prompt },
	    { "role" => "user",   "content" => $user_query },
	    ]};
    
    my $req = HTTP::Request->new('POST', $url, $header, encode_json($chat));
    my $response = $user_agent->request($req);

    if ( $response->is_success ) {
        return $c->render(
	    status => 200,
	    openapi => decode_json($response->decoded_content)
	    );
    }
    else {
        return $c->render(
	    status => 500,
	    openapi => { error => $response->decoded_content }
	    );
    }
}
1;
