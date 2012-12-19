package diplomacy;
use v5.10.1;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::Auth::RBAC 'auth';
use Dancer::Plugin::Auth::RBAC::Credentials::PostgreSQL;
use Template;
use Math::Random::Secure qw(irand);
use Dancer::Session;

our $VERSION = '0.1';

get '/' => sub {
    if ( not session('user_id')) {
        template 'index';
    }
    else {
        template 'nation';
    }
};

get '/:nation' => sub {
    my $nation = params->{'nation'};
    
    
    if (defined(database->quick_lookup('users', { name => params->{'nation'} }, 'id' ))) {
        if (defined(database->quick_lookup('users_cache', {
          name => params->{'nation'} }, 'economy' )) && 
          ((time()) - (database->quick_lookup('users_cache', { name => params->{'nation'} }, 
          'last_cache' )) > 43200 )) { #check if cache is more than 1/2 day old
              cache_nation($nation);
        }
        elsif (not defined(database->quick_lookup('users_cache', {
          name => params->{'nation'} }, 'economy' )) {
              cache_nation($nation);
        }
        
        template 'nation' => {
                    title => $nation,
                    name => $nation,     
        };
        
    }
    else {
        forward '/';
    }
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
    my $nation = params->{'nation'};
    my $password = params->{'password'};
    
    my $user = auth($nation, $password);
    if (! $user->errors) {
        my $user_id = database->quick_lookup('users', { name => $nation }, 'id');
        
        session nation => $nation;
        session user_id => $user_id;
    }
    return redirect '/', 303;
};

get '/issues' => sub {
    if (not session('user_id')) {
        template 'login';
    }
    else {
        template 'issues';
    }
};

get '/logout' => sub {
    session->destroy;
    return redirect '/', 303;
};

hook before_template => sub {
       my $tokens = shift;
       $tokens->{'logged_in_nav'} = '<ul class="menu"><li><a href="/">YOUR NATION</a></li><ul class="menu"><li><a href="/issues">ISSUES</a></li><li><a href="/messages">MESSAGES</a></li><li><a href="/settings">SETTINGS</a></li></ul><li><a href="#">THE WORLD</a></li><li><a href="#">UNITED NATIONS</a></li><li><a href="#">ABOUT</a></li></ul>';
       $tokens->{'logged_out_nav'} = '<ul class="menu"><li><a href="#">HOME</a></li><li><a href="#">THE WORLD</a></li><li><a href="#">UNITED NATIONS</a></li><li><a href="#">ABOUT</a></li></ul>';
       
};

sub _eval_economy {
    my $nation = $ARGV[0];
    my $econ_score = database->quick_lookup('users', { name => $nation }, 'economy');
    given ($econ_score) {
        when ($_ < 5) { return 'Non-existent'; }
        when (10 <= $_ && $_ >= 5) { return 'Jump Starting'; }
        when (20 <= $_ && $_ > 10) { return 'Fledgling'; }
        when (30 <= $_ && $_ > 20) { return 'Developing'; }
        when (40 <= $_ && $_ > 30) { return 'Emerging'; }
        when (50 <= $_ && $_ > 40) { return 'Fair'; }
        when (60 <= $_ && $_ > 50) { return 'Good'; }
        when (70 <= $_ && $_ > 60) { return 'Strong'; }
        when (80 <= $_ && $_ > 70) { return 'Thriving'; }
        when (90 <= $_ && $_ > 80) { return 'Powerhouse'; }
        when (95 <= $_ && $_ > 90) { return 'Superpower'; }
        when ($_ > 95) { return 'Unmatched'; }
    }
}

sub cache_nation {
        my $nation = $ARGV[0];
        my $motto = database->quick_lookup('users', { name => $nation }, 'motto');
        my $id = database->quick_lookup('users', { name => $nation }, 'id');
        my $flag = database->quick_lookup('users', { name => $nation }, 'flag');
        my $economy = _eval_economy($nation);
        my $political_freedoms = _eval_political_freedoms($nation);
        my $civil_rights = _eval_civil_rights($nation);
        my $economic_scale = _eval_economic_scale($nation);
        my $region = database->quick_lookup('users', { name => $nation }, 'region');
        my $population = database->quick_lookup('users', { name => $nation }, 'population');
        my $tax_rate = database->quick_lookup('users', { name => $nation }, 'tax_rate');
        my $un_category = _eval_un_category($nation);
        my $un_delegate = database->quick_lookup('users', { name => $nation }, 'un_delegate');
        my $classification = database->quick_lookup('users', { name => $nation }, 'classification');
        my $currency = database->quick_lookup('users', { name => $nation }, 'currency');
        my $animal = database->quick_lookup('users', { name => $nation }, 'animal');
        my $cop_rate = _eval_cop_rate($nation);
        my $trees_rate = _eval_trees_rate($nation);
        my $crime_rate = _eval_crime_rate($nation);
        my $last_cache = time();
        
        database->quick_insert('users_cache', { id => $id, name => $nation, motto => $motto, flag => $flag, economy => $economy, political_freedoms => $political_freedoms, civil_rights => $civil_rights, economic_scale => $economic_scale, region => $region, population => $population, tax_rate => $tax_rate, un_category => $un_category, un_delegate => $un_delegate, currency => $currency, animal => $animal, cop_rate => $cop_rate, trees_rate => $trees_rate, crime_rate => $crime_rate, last_cache => $last_cache});
}        
true;
