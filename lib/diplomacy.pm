package diplomacy;
use v5.10.1;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::Auth::RBAC 'auth';
use Dancer::Plugin::Auth::RBAC::Credentials::PostgreSQL;
use Template;
use Math::Random::Secure qw(irand);
use Dancer::Session;
no strict 'refs';

our $VERSION = '0.1';

get '/' => sub {
        template 'index';
};

get '/nation/:nation' => sub {
    my $nation = params->{'nation'};
    
    
    if (defined(database->quick_lookup('users', { name => params->{'nation'} }, 'id' ))) {
        if (defined(database->quick_lookup('users_cache', {
          name => params->{'nation'} }, 'economy' )) && 
          ((time()) - (database->quick_lookup('users_cache', { name => params->{'nation'} }, 'last_cache' )) > 43200 )) { #check if cache is more than 1/2 day old
	      my $nation = params->{'nation'};
              cache_nation($nation);
        }
        elsif (not defined(database->quick_lookup('users_cache', {
          name => params->{'nation'} }, 'economy' ))) {
	      my $nation = params->{'nation'};
              cache_nation($nation);
        }
        
        my $un_data = database->quick_lookup('users_cache', { name => $nation }, 'un_category');
        my @un_category = split('\|', $un_data);
        my $population = database->quick_lookup('users_cache', { name => $nation }, 'population');
        
        template 'nation' => {
            title => $nation,
            name => $nation,
            classification => database->quick_lookup('users_cache', { name => $nation }, 'classification'),
            flag => database->quick_lookup('users_cache', { name => $nation }, 'flag'),
            motto => database->quick_lookup('users_cache', { name => $nation }, 'motto'),
            category => $un_category[0],
            civil_rights => database->quick_lookup('users_cache', { name => $nation }, 'civil_rights'),
            political_freedoms => database->quick_lookup('users_cache', { name => $nation }, 'political_freedoms'),
            economy => database->quick_lookup('users_cache', { name => $nation }, 'economy'),
            paragraph_prefix => $un_category[1],
            paragraph_suffix => $un_category[2],
            trees_rate => database->quick_lookup('users_cache', { name => $nation }, 'trees_rate'),
            population => $population,
            crime => database->quick_lookup('users_cache', { name => $nation }, 'cop_rate'),
            animal => database->quick_lookup('users_cache', { name => $nation }, 'animal'),
            currency => database->quick_lookup('users_cache', { name => $nation }, 'currency'),
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
    my $nation = params->{nation};
    my $econ_score = database->quick_lookup('users', { name => $nation }, 'economy');
    given ($econ_score) {
        when ($_ < 5) { return 'Non-existent'; }
        when (10 >= $_ && $_ >= 5) { return 'Jump Starting'; }
        when (20 >= $_ && $_ > 10) { return 'Fledgling'; }
        when (30 >= $_ && $_ > 20) { return 'Developing'; }
        when (40 >= $_ && $_ > 30) { return 'Emerging'; }
        when (50 >= $_ && $_ > 40) { return 'Fair'; }
        when (60 >= $_ && $_ > 50) { return 'Good'; }
        when (70 >= $_ && $_ > 60) { return 'Strong'; }
        when (80 >= $_ && $_ > 70) { return 'Thriving'; }
        when (90 >= $_ && $_ > 80) { return 'Powerhouse'; }
        when (95 >= $_ && $_ > 90) { return 'Superpower'; }
        when ($_ > 95) { return 'Unmatched'; }
    }
}

sub _eval_political_freedoms {
    my $nation = params->{nation};
    my $pol_score = database->quick_lookup('users', { name => $nation }, 'political_freedoms');
    
    given ($pol_score) {
        when ($_ < 5) { return 'Outlawed'; }
        when (10 >= $_ && $_ >= 5) { return 'Rumored'; }
        when (20 >= $_ && $_ > 10) { return 'Rare'; }
        when (30 >= $_ && $_ > 20) { return 'Few'; }
        when (40 >= $_ && $_ > 30) { return 'Some'; }
        when (50 >= $_ && $_ > 40) { return 'Reasonable'; }
        when (60 >= $_ && $_ > 50) { return 'Average'; }
        when (70 >= $_ && $_ > 60) { return 'Above Average'; }
        when (80 >= $_ && $_ > 70) { return 'Good'; }
        when (90 >= $_ && $_ > 80) { return 'Very Good'; }
        when (95 >= $_ && $_ > 90) { return 'Great'; }
        when ($_ > 95) { return 'Universal'; }
    }
}

sub _eval_civil_rights {
    my $nation = params->{nation};
    my $civil_score = database->quick_lookup('users', { name => $nation }, 'civil_rights');
    
    given ($civil_score) {
        when ($_ < 5) { return 'Outlawed'; }
        when (10 >= $_ && $_ >= 5) { return 'Embarrassing'; }
        when (20 >= $_ && $_ > 10) { return 'Tyrannic'; }
        when (30 >= $_ && $_ > 20) { return 'Few'; }
        when (40 >= $_ && $_ > 30) { return 'Some'; }
        when (50 >= $_ && $_ > 40) { return 'Polarizing'; }
        when (60 >= $_ && $_ > 50) { return 'Average'; }
        when (70 >= $_ && $_ > 60) { return 'Above Average'; }
        when (80 >= $_ && $_ > 70) { return 'Excellent'; }
        when (90 >= $_ && $_ > 80) { return 'Excessive'; }
        when (95 >= $_ && $_ > 90) { return 'Easily Abused'; }
        when ($_ > 95) { return 'Unmatched'; }
    }
}

sub _eval_economic_scale {
    my $nation = params->{nation};
    my $econ_scale = database->quick_lookup('users', { name => $nation }, 'economic_scale');
    
    given ($econ_scale) {
        when ($_ <= 20) { return 'Marxist'; }
        when (20 < $_ && $_ <= 40) { return 'liberal'; }
        when (40 < $_ && $_ <= 60) { return 'centrist'; }
        when (60 < $_ && $_ <= 80) { return 'laissez-faire'; }
        when (80 < $_) { return 'corporate'; }
    }
}

sub _eval_un_category {
package un_category;
use Dancer::Plugin::Database;

    our $nation = ::params->{nation};
    my %category = (
                civil_libertarian => {
                    economic_authoritarian => { #[UN Category, "Its yada yada pop. of ", "are ruled with an iron fist yada yada"]
                        political_libertarian => ["Marxist Utopia","Its compassionate, intelligent population of "," are free to vote for whoever they wish in frequent elections, and have the right to do anything they want to themselves, as long as nobody else is affected; the left-wing government bestows the right to run, but not own, a business to seemingly random citizens; others are barred."],
                        political_centrist => ["Democratic Communists","Its hard-working population of "," are fiercely patriotic, and they appear to view less equal, more capitalist nations with contempt. All of the citizens are workers, and they are free to do what they would like with themselves, and have some say in the government."],
                        political_authoritarian => ["Dictatorship of the Proletariat","Its loyal, hard-working population of "," are ruled with an iron fist by the communist government, which allows its citizens to do whatever they would like, except own property and participate in their government."],
                    },
                    economic_centrist => {
                        political_libertarian => ["Civil Rights Lovefest","Its friendly population of "," view any regression of their civil and political rights as sacrilege; economic policy is of little regard."],
                        political_centrist => ["Radical Centrists","Its confident, socially-minded population of "," hold dear their civil rights above all, with political freedoms taking a backseat to ensuring such rights. Businesses are encouraged, but regulated, with most citizens viewing both left and right-wing politics as intolerable."],
                        political_authoritarian => ["Third Way Autocracy","Its loyal population of "," are ruled by a benevolent autocrat, who keeps tabs on his citizens' every move. People are free to do what they want, as long as they report their actions to the appropriate government agency. Businesses are regulated to keep them from becoming as powerful as the government."],
                    },
                    economic_libertarian => {
                        political_libertarian => ["Anarcho-capitalist","Its confused, scared population of "," are left to fend for themselves, with governance being all but non-existent. As a result, people are free to do what they want, unless the mob disapproves."],
                        political_centrist => ["Capitalizt","Its business-minded population of "," have a standard of living that exceeds most of the world, provided one is a member of the upper class. The lower classes work at the command of their employer for whatever wage they are thankful to receive."],
                        political_authoritarian => ["ABC Military Dictatorship","Its unquestioning population of "," enjoy the freedom to do whatever they like, so long as it doesn't involve challenging the well established government, which rules by keeping its citizens satisfied through a well-funded program to build a larger navy than all of its neighbors."],
                    }
                },
                civil_centrist => { #Anyone who says this violates DRY is a communist.
                    economic_authoritarian => {
                        political_libertarian => ["Welfare State","Its socially-minded, generous population of "," have tremendous say in the government; they say to give the people more services. Citizens pay for their services through high taxes and many government work programs. Personal freedoms are encouraged, to a point, but not when it interferes with elections or political freedoms."],
                        political_centrist => ["Democratic Socialists","Its inspired, optimistic population of "," have the power to vote in bureaucrats to their government and little more. The citizens view their nation as socially equal, and the epitome of a just government; they see capitalist nations as immoral. The all-encompassing government respects its citizens' civil rights, to a point, and allows for some direct representation, though not too often."],
                        political_authoritarian => ["Confused Trotskyist Oligarchy","Its hard-nosed, hard-working population of "," are ruled with an iron fist by the Party, who ensures complete income equality among those not in the priveleged ruling class. Citizens enjoy a number of rights and civil protections, probably because the Party has not found a way to exploit them."],
                    },
                    economic_centrist => {
                        political_libertarian => ["Frank Sinatra Democracy","Its educated, easily-swayed population of "," have immense political freedom, which is often taken advantage of by the media and the rich. The right to vote is extended to all, although some have trouble assuring similar protections in other rights."],
                        political_centrist => ["Bipolar Republic","Its diverse, optimistic population of "," enjoy good civil rights, if they are not of the wrong class, and have some economic freedom, as long as they do not exploit people of lesser wealth. Elections are held occasionally, with the vote going to one of two major parties; whichever wins is anyone's guess, as nobody really has any idea of what's going on."],
                        political_authoritarian => ["Father Knows Best State","Its submissive population of "," have no political rights, and do whatever their leader encourages them to do; most of the time, this provides them with average civil and economic rights, with harsh penalties for those the government has determined to be guilty."],
                    },
                    economic_libertarian => {
                        political_libertarian => ["Corporatocracy","Its glassy-eyed population of "," are ruled by corporations that they vote for. Elections are frighteningly unregulated, and those with little money have little say in the government. Civil rights are average, with those protecting free enterprise being valued the most. "],
                        political_centrist => ["Libertarian Democracy","Its self-reliant, proud population of "," live in a capitalist paradise, where the rights of people to run a business are completely uninhibited. There is limited restrictions on corporate involvement in elections, but there's no telling how much or how. Civil rights are secondary to economic freedom, but not non-existent."],
                        political_authoritarian => ["Conspicuous Consumption State","Its big-spending population of "," buy whatever they can afford, partly because of government &quot;encouragement&quot; and partly because of an intense culture of displaying one's possessions publically. Most civil rights are protected, but not in the same way as the right to purchase."],
                    }
                },
                civil_authoritarian => {
                    economic_authoritarian => {
                        political_libertarian => ["Tyranny of the Majority","Its intelligent population of "," participate in frequent elections, where a slim but stable majority expand their own rights at the expense of minorities, who have no rights by comparison."],
                        political_centrist => ["Oligarchical Collectivists","Its reserved, careless population of "," have few freedoms, although they do have the ability to vote in elections, which occur infrequently and irregularly, often in obscure locations."],
                        political_authoritarian => ["Sweatshop Dictatorship","Its hopeless, cynical population of "," are ruled by a fearless dictator, who uses his power to outlaw all civil, political, and economic rights, except for the right to work harder.  "],
                    },
                    economic_centrist => {
                        political_libertarian => ["Theodemocracy","Its god-fearing, reverent population of "," enjoy great political freedoms and voting rights, which they use to elect retired religious officials and enact religious policy. Personal life is heavily controlled, but people have the freedom of free enterprise, to a point."],
                        political_centrist => ["Theocracy","Its respectful, god-fearing population of "," enjoy some say in their government, which they use to ban almost all personal liberties that are not encouraged by their religion. Those that live their life quietly and piously are praised, while others tend to disappear."],
                        political_authoritarian => ["Human Resources Department State","Its fiercely patriotic population of "," have no individual rights, but are allowed to work hard to produce goods and services for the corrupt and oppressive government. "],
                    },
                    economic_libertarian => {
                        political_libertarian => ["Corrupt Conservative Republic","Its hard-working, hard-nosed population of "," enjoy the freedom to work hard for long hours, and have no personal freedom to speak of. Instead, they enjoy frequent elections that are bought by multinational corporations."],
                        political_centrist => ["Right-wing Utopia","Its cynical, conservative population of "," have the freedom to vote in elections, though not too often; the government doesn't place too many economic restrictions on its citizens anyway. Instead, personal freedom is unheard of and people are left to fend for themselves, leaving the rich to get richer and the poor to fight it out in the dumpster."],
                        political_authoritarian => ["Iron Fist Corporatists","Its obedient population of "," are ruled with an iron fist by the coporate government, which oppresses all personal freedoms except those useful in supporting corporations. The populace has extensive rights to free enterprise, which have never been used for as long as anyone can remember."],
                    }
                }
    );
    
    sub __eval_economic_rights {
        my $nation = ::params->{nation};
        my $economic_rights = database->quick_lookup('users', { name => $nation }, 'economic_scale');
        given ($economic_rights) {
            when ($_ <= 33) { return "economic_authoritarian"; }
            when (33 < $_ && $_ <= 67) { return "economic_centrist"; }
            when (67 < $_) { return "economic_libertarian"; }
        }
    }
    
    sub __eval_political_rights {
        my $nation = ::params->{nation};
        my $political_rights = database->quick_lookup('users', { name => $nation }, 'political_freedoms');
        given ($political_rights) {
            when ($_ <= 33) { return "political_authoritarian"; }
            when (33 < $_ && $_ <= 67) { return "political_centrist"; }
            when (67 < $_) { return "political_libertarian"; }
        }
    }
    
    sub __eval_civil_rights {     
        my $nation = ::params->{nation};
        my $civil_rights = database->quick_lookup('users', { name => $nation }, 'civil_rights');
        given ($civil_rights) {
            when ($_ <= 33) { return "civil_authoritarian"; }
            when (33 < $_ && $_ <= 67) { return "civil_centrist"; }
            when (67 < $_) { return "civil_libertarian"; }
        }
    }
    my $real_category = $category{__eval_civil_rights($nation)}{__eval_economic_rights($nation)}{__eval_political_rights($nation)}[0];
    my $real_category_prefix = $category{__eval_civil_rights($nation)}{__eval_economic_rights($nation)}{__eval_political_rights($nation)}[1];
    my $real_category_suffix = $category{__eval_civil_rights($nation)}{__eval_economic_rights($nation)}{__eval_political_rights($nation)}[2];
    my $store = join('|', $real_category,$real_category_prefix,$real_category_suffix);
    return $store;
}

sub _eval_cop_rate {
    my $nation = params->{nation};
    my $cop_rate = database->quick_lookup('users', { name => $nation }, 'cop_rate');
    
    given ($cop_rate) {
        when ($_ <= 20) { return 'almost non-existent'; }
        when (20 < $_ && $_ <= 40) { return 'small'; }
        when (40 < $_ && $_ <= 60) { return 'reasonable'; }
        when (60 < $_ && $_ <= 80) { return 'pervasive'; }
        when (80 < $_) { return 'corrupt'; }
    }
}

sub _eval_trees_rate {
    my $nation = params->{nation};
    my $trees_rate = database->quick_lookup('users', { name => $nation }, 'trees_rate');
    
    given ($trees_rate) {
        when ($_ <= 20) { return 'renowned for its complete lack of trees'; }
        when (20 < $_ && $_ <= 40) { return 'with some environmental awareness, but not too much.'; }
        when (40 < $_ && $_ <= 60) { return 'with no distinguishing natural features'; }
        when (60 < $_ && $_ <= 80) { return 'renowned for its stunning landscapes'; }
        when (80 < $_) { return 'renowned for its complete lack of industrialization'; }
    }
}

sub _eval_crime_rate {
    my $nation = ::params->{nation};
    my $crime_rate = database->quick_lookup('users', { name => $nation }, 'economic_scale');
    
    given ($crime_rate) {
        when ($_ <= 20) { return 'safe'; }
        when (20 < $_ && $_ <= 40) { return 'somewhat safe'; }
        when (40 < $_ && $_ <= 60) { return 'normal'; }
        when (60 < $_ && $_ <= 80) { return 'hectic'; }
        when (80 < $_) { return 'dangerous'; }
    }
}

sub _eval_classification {
    my $nation = params->{nation};
    my $classification_id = database->quick_lookup('users', { name => $nation }, 'classification');
    my $classification = database->quick_lookup('users_classification', { id => $classification_id }, 'value');
    return $classification;
}

sub cache_nation {
        my $nation = params->{nation};
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
        my $classification = _eval_classification($nation);
        my $currency = database->quick_lookup('users', { name => $nation }, 'currency');
        my $animal = database->quick_lookup('users', { name => $nation }, 'animal');
        my $cop_rate = _eval_cop_rate($nation);
        my $trees_rate = _eval_trees_rate($nation);
        my $crime_rate = _eval_crime_rate($nation);
        my $last_cache = time();
            
        database->quick_insert('users_cache', { id => $id, name => $nation, motto => $motto, flag => $flag, economy => $economy, political_freedoms => $political_freedoms, civil_rights => $civil_rights, economic_scale => $economic_scale, region => $region, population => $population, tax_rate => $tax_rate, un_category => $un_category, un_delegate => $un_delegate, classification => $classification, currency => $currency, animal => $animal, cop_rate => $cop_rate, trees_rate => $trees_rate, crime_rate => $crime_rate, last_cache => $last_cache});
}  
    
true;
