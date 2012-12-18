package diplomacy;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::Auth::RBAC::Credentials::PostgreSQL;
use Template;
use Math::Random::Secure qw(irand);

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

any ['get', 'post'] => '/create_nation' => sub {
    template 'create_nation';
    
};

post '/create_nation/submit' => sub {
#    print "Creating Nation...";
    database->quick_insert('users', { name => params->{'name'}, motto => params->{'slogan'}, flag => params->{'flag'}, time_founded => time(), region_arrival => time(), classification => params->{'type'}, currency => params->{'currency'}, animal => params->{'animal'}, email => params->{'email'}, password => params->{'password'}, salt => irand(10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000), login => params->{'name'} });
    return redirect '/login', 303;
};

get '/login' => sub {
    template 'login';
};

post '/login/submit' => sub {
    #login
    return redirect '/', 303;
};

hook before_template => sub {
       my $tokens = shift;
       $tokens->{'logged_in_nav'} = '<ul class="menu"><li><a href="/">YOUR NATION</a></li><ul class="menu"><li><a href="/issues">ISSUES</a></li><li><a href="/messages">MESSAGES</a></li><li><a href="/settings">SETTINGS</a></li></ul><li><a href="#">THE WORLD</a></li><li><a href="#">UNITED NATIONS</a></li><li><a href="#">ABOUT</a></li></ul>';
       $tokens->{'logged_out_nav'} = '<ul class="menu"><li><a href="#">HOME</a></li><li><a href="#">THE WORLD</a></li><li><a href="#">UNITED NATIONS</a></li><li><a href="#">ABOUT</a></li></ul>';
       
       
};


true;
