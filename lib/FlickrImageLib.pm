package FlickrImageLib;

use strict;
use Data::Dumper;
use LWP::UserAgent;
use XML::Simple;
use Encode;
use utf8;

use constant PER_PAGE => 100;
use constant PHOTO_MAX_COUNT => 10000;
use constant API_URL_DOMAIN => 'http://api.flickr.com/services/rest/?';
use constant DEBUG => 0;

$XML::Simple::PREFERRED_PARSER = 'XML::Parser'; 

#-----------------------------
# コンストラクタ
#-----------------------------
sub new {

  my $class = shift;
  my $options = shift;

  my $errormsg = "";
  my $is_error = 0;

  die "You must supply an API key and secret"
  unless $options->{key} and $options->{secret};

  my $self = {
    api_key => $options->{key},
    api_secret => $options->{key},
    errormsg => $errormsg,
    is_error => $is_error,
  };

  bless $self,$class;
  return $self;

}



sub _api_url_access {

  my ($self,$_param) = @_;
  
  # make API URL
  my @paramlist;
  $_param->{api_key} = $self->{api_key};
  foreach my $key (keys(%$_param)){
    push(@paramlist,sprintf("%s=%s",$key,$_param->{$key}));
  }
  my $url = API_URL_DOMAIN.join("&",@paramlist);

  doLog( $url) if DEBUG;

  # API access
  my $con = LWP::UserAgent->new();
  $con->agent("MT::Plugin::FlickrImageLib");
  $con->timeout(15);
  $con->env_proxy();
  my $result = $con->get($url);
  if(!$result->is_success) {
    $self->{errormsg} = $result->status_line;
    $self->is_error = 1;
    return;
  }

  return $result->content;

}

sub getPhotosByUserid{

  my($self,$_param) = @_;
  $self->{errormsg} = "";
  $self->{is_error} = 0;

  my $api_param;
  $api_param->{method}   = "flickr.people.getPublicPhotos";
  $api_param->{user_id} = $_param->{user_id};
  $api_param->{extras} = "date_upload,date_taken,tags,url_sq, url_t, url_s,url_m,url_l";
  if(defined($_param->{extras}) && $_param->{extras} ne ""){
    $api_param->{extras} .= ",".$_param->{extras};
  }
  $api_param->{per_page} = PER_PAGE;
  $api_param->{page} = 1;

  my $firstFlag = 0;
  my $count = 1;
  my @photos;
  while($count>0){

    # exec api
    my $xml = $self->_api_url_access($api_param);
    if($self->{errormsg} != ""){
      $self->{is_error} = 1;
      return 0;
    }
    # xml parse
    my $insXML = XML::Simple->new();
    my $data = $insXML->XMLin($xml);
    if(defined($data->{err})){
      $self->{errormsg} = $data->{err}->{msg};
      $self->{is_error} = 1;
      return;
    }

    my $photoDataPlane = $data->{photos}->{photo};
    foreach my $key (keys(%$photoDataPlane)){
      doLog( Dumper($photoDataPlane->{$key})) if DEBUG;
      push(@photos,$photoDataPlane->{$key});
    }
    # page setting
    if($firstFlag == 0){ # get total count at first api access 
      $count = int($data->{photos}->{total} / PER_PAGE) + 1;
      $firstFlag++;
    }
    # max count check
    if($count > PHOTO_MAX_COUNT){
      $self->{errormsg} = "over max photo count...";
      $self->{is_error} = 1;
      return;
    }

    doLog( "count ...[".$count."]") if DEBUG;
    $api_param->{page}++;
    $count--;

  }
  
  return @photos;

}
sub getPhotoCountByUserid{

  my($self,$_param) = @_;
  $self->{errormsg} = "";
  $self->{is_error} = "";

  # make param
  my $api_param;
  $api_param->{method}   = "flickr.people.getInfo";
  $api_param->{user_id} = $_param->{user_id};

  # exec api
  my $xml = $self->_api_url_access($api_param);
  if($self->{errormsg} != ""){
    $self->{is_error} = 1;
    return 0;
  }

  # xml parse
  my $insXML = XML::Simple->new();
  my $data = $insXML->XMLin($xml);

  doLog( Dumper($data) ) if DEBUG;
  if(defined($data->{err})){
    $self->{errormsg} = $data->{err}->{msg};
    $self->{is_error} = 1;
    return;
  }

  return $data->{person}->{photos}->{count};

}



sub findByUsername {

  my($self,$_param) = @_;
  $self->{errormsg} = "";
  $self->{is_error} = 0;

  # make param
  my $api_param;
  $api_param->{method}   = "flickr.people.findByUsername";
  $api_param->{username} = $_param->{username};
  
  # exec api
  my $xml = $self->_api_url_access($api_param);
  if($self->{errormsg} != ""){
    $self->{is_error} = 1;
    return 0;
  }

  # xml parse
  my $insXML = XML::Simple->new();
  my $data = $insXML->XMLin($xml);

  doLog( Dumper($data)) if DEBUG;
  if(defined($data->{err})){
    $self->{errormsg} = $data->{err}->{msg};
    $self->{is_error} = 1;
    return;
  }

  return $data->{user}->{id};

}

sub doLog {

  my($msg) = @_;
  return unless defined($msg);

  use MT::Log;
  my $log = MT::Log->new;
  $log->message($msg);
  $log->save or die $log->errstr;

}

1;
