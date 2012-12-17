package diplomacy;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::Auth::RBAC::Credentials::PostgreSQL;
use Template;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

any ['get', 'post'] => '/create_nation' => sub {
    template 'create_nation';
    
};

hook before_template => sub {
       my $tokens = shift;
       $tokens->{'logged_in_nav'} = '<ul class="menu"><li><a href="/">YOUR NATION</a></li><ul class="menu"><li><a href="/issues">ISSUES</a></li><li><a href="/messages">MESSAGES</a></li><li><a href="/settings">SETTINGS</a></li></ul><li><a href="#">THE WORLD</a></li><li><a href="#">UNITED NATIONS</a></li><li><a href="#">ABOUT</a></li></ul>';
       $tokens->{'logged_out_nav'} = '<ul class="menu"><li><a href="#">HOME</a></li><li><a href="#">THE WORLD</a></li><li><a href="#">UNITED NATIONS</a></li><li><a href="#">ABOUT</a></li></ul>';
       
       
};


true;
