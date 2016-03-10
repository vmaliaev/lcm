
#class test ( 
# $oauth_consumer_key = cache_data('foreman_cache_data', 'oauth_consumer_key', random_password(32))
#){

# notice("$oauth_consumer_key")
#}

#class { 'test':
# oauth_consumer_key => 'abc',
# notice("$oauth_consumer_key")
#}

#class { '::foreman':
#  db_type => mysql,

class param (
 $a = 1,
 $b = 2,
 $c = 'Hello') {

}

class nonparam {
 $as = 25
 $bs = 111
 $cs = 'Hello from nonparam'
}


class inhparam { #inherits param {
 include param
 $ais = $param::a
 $bis = 55111
 $cis = 'Hello from inherirts'
}

class { 'inhparam' : 

}
#class { 'nonparam' : }
#class { 'param': }

notify {"$inhparam::ais": } 
notify {"$param::c": }

#notify {"$param::c $nonparam::cs": }


