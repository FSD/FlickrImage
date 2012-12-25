FlickrImage
===========

MovableType5.2 Plugin (Flickr API)

--------------------------------------------------------------------
FlickrImage MTプラグイン                                     F.S.D.
--------------------------------------------------------------------
プラグインのバージョンは0.1です。あまりテストがなされていません。
危害を与えることは無いと思いますが、まだバグが沢山残されている可能性
があります。

1.インストール
--------------------------------------------------------------------

通常のMTプラグインと同様plugins配下にこのディレクトリ
を配置します。

利用しているPerlのモジュールですが、

use LWP::UserAgent;
use XML::Simple;
use JSON;

です。必要であれば個別にインストールして下さい。


2.設定
--------------------------------------------------------------------

MT管理画面の「システム」「ツール」「プラグイン」から
プラグイン一覧画面を開いて、FlickrImageの行を選択します。
「設定」アイコンをクリックすると３つの入力欄が表示されます。

username...Flickrの公開されている画像を保持しているユーザ名
api_key ...Flickrから取得したAPIキー
secret  ...Flickrから取得したキーワード

この３つを入力して「変更を保存」ボタンを押下して下さい。

3.利用
--------------------------------------------------------------------
Blockタグ   ：<MTFlickrImages>
------------------------------

 FlickrAPIで取得した画像の情報でループするタグです．
 モディファイアとして以下の物が利用出来ます．

 lastn      : 画像の取得件数を指定します
 sort_by    : Flickrより取得した画像を指定された項目でソートします。
              項目名はFlickrAPIにて取得した項目名となります。
 sort_order : sort_byで指定した項目に対する昇順・降順を規定します
 match_col  : Flickrより取得したフィールド名を指定します。
              datetaken,dateupload,tags,url_s,url_m,url_l,url_t,url_sq,title等
              以下に説明するmatch_valとあわせて利用します
 match_val  : match_colで指定されたフィールドの値を指定します。
              指定には正規表現を利用することが可能です．
              なお、"entry_"で始まる値を指定するとEntryの値で
              データを取得することが可能です．
 format     : match_valが日付型のデータで指定された時にフォーマット
              を指定する物です．

Functionタグ：<MTFlickrImage>
------------------------------

 FlickrAPIで取得した画像の情報を表示するタグです．
 モディファイアとして以下の物が利用出来ます．

 key         : 情報の種別を指定します。値は以下の物が指定可能です。
               datetaken,dateupload,tags,url_s,url_m,url_l,url_t,url_sq,title等

(例1)
------------------------------
<MTFlickrImages lastn=10 sort_by="dateupload" match_col="title" match_val="image001">
  <div  style="float:left;">
    <img src='<MTFlickrImage key="url_sq">' title='<MTFlickrImage key="title">'><br />
    <MTFlickrImage key="dateupload" format="%Y/%m/%d">
  </div>
</MTFlickrImages>

上記の例は、Flickr側のtitleがimage001にマッチする画像をdateuploadの昇順に10件表示します。

 (例2)
------------------------------
<MTFlickrImages lastn=10 sort_by="dateupload" sort_order="descend" match_col="dateupload" format="%Y%m%d" match_val="entry_modified_on,0,8">
  <div  style="float:left;">
    <img src='<MTFlickrImage key="url_sq">' title='<MTFlickrImage key="title">'><br />
    <MTFlickrImage key="dateupload" format="%Y/%m/%d">
  </div>
</MTFlickrImages>

上記の例は、Flickr側のdateuploadがEntryのmodified_onのYYYYMMDDにマッチする画像をdateuploadの降順に10件表示します。

