package FlickrImage::Plugin;

use strict;
use MT::Cache::Session;
use MT::Serialize;
use MT::Util;
use JSON;
use utf8;
use FlickrImageLib; #どうやらlibの下はincludeディレクトリになっている模様
use constant CACHE_NAME => 'FlickrImage::Plugin';

#-------------------------------------------
# blockタグ用関数
# Flickrから指定された条件でリストを取得する
#-------------------------------------------
sub getFlickrImages {

  my ($ctx,$args,$cond) = @_;

  my $plugin = MT->component('FlickrImage');
  my $entry = $ctx->stash('entry') or return $ctx->error("Tag Called without an entry in context");

  #Cacheから値を取得
  my $session = MT::Cache::Session->new();
  my $jsonphotoshash = JSON::decode_json($session->get(CACHE_NAME));
  my $jsonphotos = $jsonphotoshash->{jsondata};
  my @photos = @$jsonphotos;

  #オプション処理
  #match
  my $matchval;
  if(defined($args->{'match_col'}) && $args->{'match_col'} ne ""){
    #match_valに"entry_"の文字がある場合はEntryの情報を利用する（substr機能もあり）
    if($args->{'match_val'} =~ /^entry_(.*)/){
      #$matchval = $entry->$1;
      $matchval = entrySubstr($entry,$1);
    }
    else {
      $matchval = $args->{'match_val'};
    }

    #フォーマットタグがある場合は日付形式を変換して抽出
    if(!defined($args->{'format'}) && $args->{'format'} eq ""){
      @photos = grep ($_->{$args->{'match_col'}} =~ /$matchval/,@photos);
    }
    else {
      @photos = grep (flickrImageFormatDate($ctx,$_->{$args->{'match_col'}},$args->{'format'}) =~ /$matchval/,@photos);
    }
    
  }

  #sort_by,sort_order
  if(defined($args->{'sort_by'})){
    if(defined($args->{'sort_order'}) && $args->{'sort_order'} eq 'descend'){
      @photos = sort {$b->{$args->{'sort_by'}} cmp $a->{$args->{'sort_by'}}} @photos;
    }
    else {
      @photos = sort {$a->{$args->{'sort_by'}} cmp $b->{$args->{'sort_by'}}} @photos;
    }
  }
  #lastn
  if(defined($args->{'lastn'})){
    splice(@photos,$args->{'lastn'});
  }

  #ブロックループ
  my $out = "";
  my $title;
  my $film;
  foreach my $photo (@photos){
    foreach my $key (keys(%$photo)){
      $ctx->stash($key,$photo->{$key});
    }
    defined(my $txt = $ctx->slurp($args,$cond)) or return;
    $out .= $txt;
  }

  return $out;

}

#----------------------------------------------
# functionタグ用関数
# 以下、取得した画像情報をテンプレートに返す
#----------------------------------------------
sub getValue {
  my ($ctx,$args) = @_;
  my $key = $args->{'key'};
  my $value = $ctx->stash($key);

  #UTC -> format
  if(defined($args->{'format'}) && $value =~ /^\d{10}$/){
    $value = flickrImageFormatDate($ctx,$value,$args->{'format'});
  }

  return $value;
}

#----------------------------------------------
# Callback関数
#   pre_build: prepareFlickrImages()
#----------------------------------------------
sub prepareFlickrImages {

  my ( $cb, $app, $mtml, $args, $params ) = @_;
  my $ctx = $args->{ctx};

  #Plugin設定から値を取得
  my $plugin = MT->component('FlickrImage');
  my $flick_key = $plugin->get_config_value('api_key');
  my $flick_sec = $plugin->get_config_value('secret');
  my $flick_usr = $plugin->get_config_value('username');
 
  #APIから値を取得
  my $flickr = new FlickrImageLib({key=>$flick_key,secret=>$flick_sec});
  my $userid = $flickr->findByUsername({username=>$flick_usr});
  if($flickr->{is_error}){
    doLog("ERROR Plugin::FlickrImage 001: ".$flickr->{errormsg});
    exit;
  }
  my @photos = $flickr->getPhotosByUserid({user_id=>$userid});

  if($flickr->{is_error}){
    doLog("ERROR Plugin::FlickrImage 002: ".$flickr->{errormsg});
    exit;
  }

  my $jsondata = {"jsondata"=>\@photos};
  #シリアライズ
  my $json = JSON::encode_json($jsondata);

  #Cacheに保存
  my $session = MT::Cache::Session->new();
  $session->set(CACHE_NAME,$json);

}

#----------------------------------------------
# Tool
#----------------------------------------------
sub flickrImageFormatDate {

  my ($ctx,$date,$format) = @_;

  if(!defined($format) || $format eq "")     { return undef; }
  if(!defined($date)   || $date !~ /\d{10}/) { return $date; }

  my($sec,$min,$hour,$mday,$month,$year) = localtime($date);
  my $strTime = sprintf("%04d%02d%02d%02d%02d%02d",$year+1900,$month+1,$mday,$hour,$min,$sec);
  return MT::Template::Context::_hdlr_date( $ctx, {'ts'=>$strTime , 'format'=>$format } );

}
sub entrySubstr {

  my ($entry , $word) = @_;

  if(!defined($entry)) { return; }
  if($word eq "") { return; }

  #my $data="entry_created_on,3,5";

  my @tmp = split(",",$word);

  my $name = $tmp[0];

  my ($start,$end);
  if($tmp[1] eq ""){
    $start = 0;
  }
  else {
    $start = $tmp[1];
  }
  $end = 0;
  $end = $tmp[2];

  my $returnWord = "";
  if($end == 0){
    $returnWord = substr($entry->$name,$start);
  }
  else {
    $returnWord = substr($entry->$name,$start,$end);
  }

  return $returnWord;

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
