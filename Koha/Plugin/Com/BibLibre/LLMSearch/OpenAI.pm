package Koha::Plugin::Com::BibLibre::LLMSearch::Controller;

use Modern::Perl;
use C4::Context;
use Koha::Plugin::Com::BibLibre::LLMSearch;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

my $base_url = ''; # Replace with actual Mistral API endpoint
my $api_key = ''; # Replace with your API key
my $model = '';
my $user_agent = LWP::UserAgent->new;
$user_agent->agent("KohaLLMSearch");

sub init_var {
    my ($self, $params) = @_;
    my $plugin = Koha::Plugin::Com::BibLibre::LLMSearch->new();
    $api_key  = $plugin->retrieve_data('api_key');
    $base_url = $plugin->retrieve_data('base_url');
    $model =  $plugin->retrieve_data('model');
}

sub chat {
    my $c = shift->openapi->valid_input or return;
    init_var();

    my $request = encode_json $c->validation->param('request');

    my $url = $base_url . "chat/completions";
    my $request = HTTP::Request->new(POST => $url);
    $request->header('Content-Type: application/json');
    $request->header('Accept: application/json');
    $request->header('Authorization', "Bearer $api_key");
    $request->content($json);

    my $response = $user_agent->request($request);

    if ($response->is_success) {
        return $c->render(
	    status => 200,
	    text => decode_json($response->decoded_content)
	    );
    }
    else {
        return $c->render(
	    status => 500,
	    openapi => { error => "unhandled exception"}
	    );
    }
}
1;
