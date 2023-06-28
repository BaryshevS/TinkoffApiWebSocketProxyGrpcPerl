#!/usr/bin/perl
use strict;
# use warnings;
use utf8;
use Getopt::Long qw(:config no_ignore_case bundling);
# use DDP;
use JSON::XS;
use FindBin qw($Bin);
BEGIN {
  push( @INC, $Bin );
}
chdir($Bin) or die "$!";
use AnyEvent::WebSocket::Client;

$| = 1;

GetOptions(
  'verbose|v+'    => \(my $Verbose),
  'token|t=s'      => \(my $Token),
);

$Token//=$ENV{ 'TINKOFF_TOKEN' };

die "use --token *** " unless $Token;

my $client = AnyEvent::WebSocket::Client->new(
  http_headers  => {
    'Authorization'       => 'Bearer ' . $Token,
    'Web-Socket-Protocol' => 'json',
    'Accept'              => 'application/json',
  },
  # max_payload_size  => 131072*10,
  # max_fragments=>10,
  #  timeout      => 100, #иначе отрубится
);
# $client->{ssl_no_verify} = 1;


my $reconnecttimeout;
my $RpsNow;
my %UniqUid;
my $Data=<DATA>;
my $TotalUid = scalar split('instrumentId',  $Data);

sub TryConnect {

  $client->connect( "wss://invest-public-api.tinkoff.ru/ws/tinkoff.public.invest.api.contract.v1.MarketDataStreamService/MarketDataStream" )->cb( sub {
    our $connection = eval { shift->recv };
    # print DDP::np($connection);
    if ( $@ ) {
      # handle error...
      warn $@;
      return;
    }

    print "\n" x 5 . "Socket connected\n";

    # recieve message from the websocket...
    $connection->on( each_message => sub {
      my ( $conn, $message ) = @_;
      $RpsNow++;
      my $json = JSON::XS->new->utf8->decode( $message->{body} );

      if (exists $json->{'orderbook'}) {
        $UniqUid{ $json->{'orderbook'}->{'instrumentUid'} }++;
      }
      if ($Verbose) {
        my $d = JSON::XS->new->canonical( 1 )->utf8->encode( $json );
        print "$d\n";
      }
    } );

    # handle a closed connection...
    $connection->on( finish => sub {
      # $connection is the same connection object
      my ( $conn ) = @_;
      warn "Finished (" . join( ' ', "code: ". ($conn->{'close_code'}||''), "reason: ".($conn->{'close_reason'}||'')) . ")";
      # print DDP::np($connection);
      # eval {
      #   $connection->close;
      # };
      $connection=undef;
      %UniqUid=();
      $reconnecttimeout = AnyEvent->timer( after => 5, cb => \&TryConnect);
    } );

    # send a message through the websocket...
    my $res;
    unless ( $connection->_is_write_open ) {
      warn "connection not ready";
    }
    # $res = $connection->send(
    #   JSON::XS->new->utf8->encode(
    #     JSON::XS->new->utf8->decode(
    #       qq~
    #         {"subscribeOrderBookRequest":
    #           {
    #             "subscriptionAction":"SUBSCRIPTION_ACTION_SUBSCRIBE",
    #             "instruments":[
    #               {"figi": "BBG004730RP0", "depth":20}
    #             ]
    #           }
    #       }~ ))
    # );
    # $res = $connection->send( qq~
    # {
    #   "subscribeCandlesRequest": {
    #     "subscriptionAction": "SUBSCRIPTION_ACTION_SUBSCRIBE",
    #     "instruments": [
    #       {
    #         "figi": "BBG001J4BCN4",
    #         "interval": "SUBSCRIPTION_INTERVAL_ONE_MINUTE"
    #       },
    #       {
    #         "figi": "BBG0013HG026",
    #         "interval": "SUBSCRIPTION_INTERVAL_ONE_MINUTE"
    #       },
    #       {
    #         "figi": "BBG004730RP0",
    #         "interval": "SUBSCRIPTION_INTERVAL_ONE_MINUTE",
    #         "instrumentId": "c7c26356-7352-4c37-8316-b1d93b18e16e"
    #       }
    #     ],
    #     "waitingClose": false
    #   }
    # }~ );

    $res = $connection->send(
      JSON::XS->new->utf8->encode(
        JSON::XS->new->utf8->decode(
          $Data
        )
      )
    );
    print "Socket data sent\n";

  } );
}

my $StateTimer={};
$StateTimer->{tmrlog} = AnyEvent->timer( interval => 5, cb => sub {
  my $elapsed=int(time - $StateTimer->{t});
  $elapsed||=1;
  print sprintf("rps: %5d \r", $RpsNow/$elapsed);
});
$StateTimer->{tmr} = AnyEvent->timer( after => 10, interval => 60, cb => sub {
  $StateTimer->{t}||=time();
  my $elapsed=int(time - $StateTimer->{t});
  $elapsed||=1;

  print sprintf("\nrps: %5d  uid  %d / %d\n", $RpsNow/$elapsed, scalar keys %UniqUid, $TotalUid);
  $StateTimer->{t}=time();
  $RpsNow=0;
});

$reconnecttimeout = AnyEvent->timer( after => 0, cb => \&TryConnect);

AnyEvent->condvar->recv;

__DATA__
{"subscribeOrderBookRequest":{"subscriptionAction":"SUBSCRIPTION_ACTION_SUBSCRIBE","instruments":[{"instrumentId":"8766b484-6582-4a11-99e6-8692784cc5ff","depth":20},{"depth":20,"instrumentId":"57b07d3e-41c5-46bb-a41c-c140a2a2d4a0"},{"instrumentId":"458e56ee-b350-4a0b-892d-35c62014c41b","depth":20},{"instrumentId":"b7461019-d0b2-47f2-9197-b050b619a764","depth":20},{"instrumentId":"da70790e-c26b-4d94-abd6-0b045da9a82f","depth":20},{"instrumentId":"f8cd6be9-9268-450d-a61c-496fb3b35a47","depth":20},{"depth":20,"instrumentId":"1c6fadc4-f238-4dcb-813b-ff665ed84884"},{"instrumentId":"034cfe3a-9b0e-4bc4-8aea-71863e03d427","depth":20},{"instrumentId":"9413f12b-3db1-47db-b756-d0c2537cfce6","depth":20},{"depth":20,"instrumentId":"24b9a6a6-326e-492e-9786-e1b152c7e5da"},{"instrumentId":"97935528-1e9e-434b-b40a-656a328500ae","depth":20},{"depth":20,"instrumentId":"95f3dbeb-ca70-4a39-844b-35d4d3afdce6"},{"depth":20,"instrumentId":"45c61b12-b947-49a5-9bed-34118666f34f"},{"instrumentId":"8f094392-8db6-4a0c-9d36-d4bbee81bc44","depth":20},{"instrumentId":"1f5ed4d9-7b91-42de-a332-63617124753a","depth":20},{"depth":20,"instrumentId":"12aecfc7-71cd-4527-978b-b727bb24d2a7"},{"instrumentId":"c8e63252-b5ce-408e-be14-168b0f09e63e","depth":20},{"depth":20,"instrumentId":"4350f6af-ffab-47ee-af1b-4984aafe5d6d"},{"depth":20,"instrumentId":"5f676f6e-3e52-4448-9ae8-d628337c8fad"},{"depth":20,"instrumentId":"d39b1cc9-0af8-41a7-a511-4d6d032bf599"},{"depth":20,"instrumentId":"e72fd15b-e2ae-4f99-a94b-9e6fbfca7287"},{"depth":20,"instrumentId":"1d9d6e81-a0d7-4830-9403-d8d331433529"},{"depth":20,"instrumentId":"e0e607a3-d6df-44b5-b139-65f8668668d9"},{"instrumentId":"5a099360-9d00-4fc2-a0b2-d66c9412b72f","depth":20},{"instrumentId":"c17c5885-e15f-4a78-b27d-326be887dc29","depth":20},{"instrumentId":"2f43fc8c-967b-4841-8ae3-25f950bd022c","depth":20},{"depth":20,"instrumentId":"c2a68941-589b-45e3-b2ad-321dea3d47a6"},{"instrumentId":"68fd5ee0-a05b-42a7-b05b-b0bfafef4c57","depth":20},{"instrumentId":"16c9ae8c-3882-406f-a23b-87da58475c4c","depth":20},{"instrumentId":"443ec410-ed8b-4bfe-981b-d72a615325cb","depth":20},{"depth":20,"instrumentId":"60adda90-990a-4783-a6dd-c40416bbcf25"},{"depth":20,"instrumentId":"0542095e-0dca-48a6-ae49-a7d892c38acb"},{"instrumentId":"2cc17414-637c-485a-a187-0371d7d9c06a","depth":20},{"depth":20,"instrumentId":"e4bc87a5-da64-4923-ac0a-b6cd2ebe1910"},{"instrumentId":"258cfef4-eee6-4d43-a57a-025030cd8ab0","depth":20},{"instrumentId":"d14e30bf-16ea-419c-9d8d-5edd505d6841","depth":20},{"instrumentId":"992f7309-0921-48b0-9791-190c9725f498","depth":20},{"instrumentId":"b23c3ede-0780-4a3e-8ced-7a4cee8ab37d","depth":20},{"instrumentId":"d2f10e11-3527-43e8-b865-8d1b7c9de186","depth":20},{"depth":20,"instrumentId":"0595ccee-d670-4a59-a9ef-d5eeba9e4353"},{"instrumentId":"f9aa2523-40c8-4021-b39c-42b5c1380416","depth":20},{"depth":20,"instrumentId":"fa0649b1-d8c6-4d88-a633-39a48e51c542"},{"instrumentId":"4e7f76f8-572b-4581-b029-56d4d450f5f5","depth":20},{"instrumentId":"1222ff0b-ea25-4012-8a81-a7f8ab0dfeaa","depth":20},{"depth":20,"instrumentId":"fb9583dc-9690-4507-9521-6b0286fc0429"},{"depth":20,"instrumentId":"8bf669aa-0a82-412a-a91b-df2a257338c1"},{"depth":20,"instrumentId":"8b4adee4-83d9-4f0c-9fcf-d4a059f892ac"},{"instrumentId":"d738a3b0-6440-4558-9380-c4dc40003f4a","depth":20},{"instrumentId":"e2c487ea-b83d-4493-a684-954fc05e01c6","depth":20},{"instrumentId":"e9cbdbcf-5350-40f1-af08-ddbd1656fd46","depth":20},{"instrumentId":"48483c5f-885a-4fa9-94ca-da9960bb19d3","depth":20},{"depth":20,"instrumentId":"f150526d-3ba1-49bf-b3c9-f8f5d53f5b3b"},{"depth":20,"instrumentId":"0a256a49-cfcc-49f9-94f1-fcb691366a47"},{"instrumentId":"5034bb88-f025-4df6-9135-de014012780f","depth":20},{"depth":20,"instrumentId":"699c3d5a-9ce1-4257-8ed4-b3a8b0c304b1"},{"depth":20,"instrumentId":"5658e347-a72b-4056-a512-a285a9048d7a"},{"instrumentId":"cd44b94d-d9c1-48bf-bf9b-6197feac8f85","depth":20},{"depth":20,"instrumentId":"231db013-1c0c-4fd5-b65a-a57b206cf6f3"},{"instrumentId":"02f05ef8-eff1-4a44-94fb-0c5ba88a63c5","depth":20},{"instrumentId":"d1363005-4a16-4008-ace8-8e48c5d33bc1","depth":20},{"depth":20,"instrumentId":"34501480-fdd6-4fc7-b3d5-712f77f5896e"},{"instrumentId":"ba9fb419-8ce4-4fec-9f2b-dd1644cb0b2c","depth":20},{"instrumentId":"437b0004-b377-4dce-a287-4470e0b3ea6d","depth":20},{"instrumentId":"e714a221-e642-4529-90b5-3cfb5c711197","depth":20},{"depth":20,"instrumentId":"83baaf4b-823c-4c6c-a598-87c96cd76e03"},{"depth":20,"instrumentId":"1fa1abf1-5ec4-4652-af20-3779b3cc60ee"},{"instrumentId":"082e492e-7423-470e-ad2f-8731e4b3dad1","depth":20},{"depth":20,"instrumentId":"89fba5cc-e420-4f57-9897-8b48f8ecdf19"},{"instrumentId":"95d9f627-6b0c-4a73-b85a-5b3828b1a63e","depth":20},{"depth":20,"instrumentId":"a441ce97-6ab4-4052-8c0f-3561b0ab82ed"},{"depth":20,"instrumentId":"cd3affd4-3b50-43fd-b008-518f54108d59"},{"instrumentId":"9f34b8cd-bb41-46f7-9616-8e303a8b4d8b","depth":20},{"instrumentId":"4911328a-9dbf-4bd4-b8e8-5f1270b8e9c6","depth":20},{"depth":20,"instrumentId":"d3274062-d2bf-4718-bfd4-75c4234d9d4e"},{"instrumentId":"53d92ca1-178b-4e33-af60-32bb8b0c9214","depth":20},{"instrumentId":"f29603be-4a35-4024-b4f3-8786a945a045","depth":20},{"instrumentId":"89b82b03-3008-4616-b8fc-8b87095afd20","depth":20},{"instrumentId":"eafc97e5-0d5a-417a-8392-53b846cab875","depth":20},{"depth":20,"instrumentId":"00392999-772d-4b6b-a54a-d4c3b79d82be"},{"instrumentId":"8ec970c7-14cc-49fe-bf42-6ed99a9f8237","depth":20},{"instrumentId":"515a99dd-dcd4-43d6-9d4c-d789d01c2ed6","depth":20},{"depth":20,"instrumentId":"fa6c3a73-b221-411b-a980-fecc8657a9b4"},{"depth":20,"instrumentId":"f974fc53-941d-4c55-97c2-24b69c0be081"},{"instrumentId":"1a94c121-c2f8-44b1-80da-8df120a1cc0a","depth":20},{"depth":20,"instrumentId":"9688967a-e502-4ad0-b932-885cc051a1f6"},{"instrumentId":"edeab7d2-9a46-47c4-abec-585867359e66","depth":20},{"depth":20,"instrumentId":"cced78ca-9e34-4ab8-bd41-e0ac171511cb"},{"instrumentId":"29c7a7b4-1ced-4a91-a8e5-eefdb2d03f30","depth":20},{"instrumentId":"00486cd8-5915-4c0b-8017-b81b9d1805d4","depth":20},{"depth":20,"instrumentId":"15d7d259-a913-4414-9173-b9b7ac8b436d"},{"depth":20,"instrumentId":"907e83fd-ff34-4b06-8b59-33d6e611dbfd"},{"depth":20,"instrumentId":"07dcfe5b-16a6-489e-930a-4a8ddb7b4d59"},{"instrumentId":"f14b2a66-900f-4afd-a30a-7a23acc3b048","depth":20},{"depth":20,"instrumentId":"cd0c3350-905a-4a99-948d-51543a618152"},{"instrumentId":"3c0748ce-9b49-43e9-b788-048a6cb65174","depth":20},{"instrumentId":"4d27b7c4-0619-4b14-898d-1a29bddf9b01","depth":20},{"depth":20,"instrumentId":"3bcf0813-d6dd-4632-95c7-67010c9a9dd9"},{"depth":20,"instrumentId":"231e5e27-9956-47e7-ad50-6e802e4a92ed"},{"depth":20,"instrumentId":"238bd62f-0da5-41ad-bdc9-1e4f6b595342"},{"depth":20,"instrumentId":"f60cad71-6365-4264-9cd5-ef9ee6966ff1"},{"depth":20,"instrumentId":"974077c4-d893-4058-9314-8f1b64a444b8"},{"depth":20,"instrumentId":"00898f36-0667-4fd8-99e2-0a6f498ff85b"},{"instrumentId":"4bb06c70-ebe1-4062-abec-4a12ea27b84d","depth":20},{"depth":20,"instrumentId":"37c3dd3c-fa2e-4127-9c60-3a0ce412ae4b"},{"instrumentId":"bf341bb3-db3d-43fe-b844-b934a24828ef","depth":20},{"instrumentId":"232df9af-3701-4bfb-aa14-ba6e6f54f2b8","depth":20},{"depth":20,"instrumentId":"7aeda392-2910-48d8-b10e-c41cebb137c2"},{"depth":20,"instrumentId":"dc296419-e3b4-47e8-a360-d66b3660f79f"},{"depth":20,"instrumentId":"cee93f1c-8845-4481-bf5b-f46bf241a0db"},{"depth":20,"instrumentId":"7aba1d34-9fed-48f1-85b8-088b46824e30"},{"depth":20,"instrumentId":"b24a3a21-ad05-43b3-8ddc-495301a118c6"},{"instrumentId":"262aadef-33ee-494b-983e-6d16b7944c30","depth":20},{"instrumentId":"ed136b6b-5629-41fd-8bcf-5c2d9e448760","depth":20},{"depth":20,"instrumentId":"92a81f1d-95a3-40f2-a1da-8f51c1f0ccdb"},{"instrumentId":"c0d6d30a-581b-4c2e-ba39-3f615049854d","depth":20},{"depth":20,"instrumentId":"e3a105f1-7f14-4e4a-bd57-4e04fcfdce4d"},{"depth":20,"instrumentId":"0fc463b0-a04f-4b94-97e8-c0b8e131ff4c"},{"depth":20,"instrumentId":"f3ef0cc8-5a4c-46b0-8307-be665b270d30"},{"instrumentId":"27fa975b-ed85-4fa4-aee3-f8ffad027879","depth":20},{"depth":20,"instrumentId":"1c250e76-9c13-4ccd-8d05-a9707c2f1602"},{"instrumentId":"5fc4a0ea-317a-440f-a830-36201bfbedcf","depth":20},{"depth":20,"instrumentId":"048faa9e-fc48-49ee-af75-8380a626bc7d"},{"instrumentId":"b5c4342c-1272-4f6b-8508-337262b38659","depth":20},{"depth":20,"instrumentId":"9075043a-9de1-421a-8225-381a485d0ea2"},{"instrumentId":"78dfc542-ffaf-40a4-a6e3-bd8eb7dca2c8","depth":20},{"depth":20,"instrumentId":"83c4f721-2e5b-415e-8169-96f0fb6a3326"},{"instrumentId":"715522d1-868f-4156-9087-f0b1d6e23b69","depth":20},{"instrumentId":"974f363d-6b86-4575-a6d9-e1329f073fe1","depth":20},{"depth":20,"instrumentId":"b7052470-67cd-49fa-b275-a8dbe25e3531"},{"depth":20,"instrumentId":"5250b247-12d7-4b19-b262-620e1c4f69d3"},{"depth":20,"instrumentId":"e94b7749-060f-473e-b93d-55ea2345b3bb"},{"depth":20,"instrumentId":"d05bf3c1-e6f3-410f-b44a-85be325dd5a9"},{"depth":20,"instrumentId":"fe2983a0-d6ac-48d5-a375-66068b23893e"},{"depth":20,"instrumentId":"3022c752-91f0-4e66-94ad-c536473e14c9"},{"depth":20,"instrumentId":"2a097387-790f-4a34-9dc8-5f25b14d766b"},{"depth":20,"instrumentId":"2f44118c-72d6-4a4d-9c1f-63a77c3e0331"},{"depth":20,"instrumentId":"42eba190-0282-4f84-8e6b-38aa924b9b3b"},{"depth":20,"instrumentId":"435107a9-a262-4a31-8a9b-2ee6f81c1184"},{"instrumentId":"4b7e4dda-6c97-4a91-a6ad-197a86af723e","depth":20},{"depth":20,"instrumentId":"9bb2c004-f207-43f5-93a3-f5063472d48c"},{"depth":20,"instrumentId":"f505b84b-6179-4e79-b1d3-ad6877d3c379"},{"depth":20,"instrumentId":"82d30845-9207-43ad-9b43-16b7e960b29d"},{"depth":20,"instrumentId":"dfbb0ff1-67cc-410e-bfe8-6a62d845b50c"},{"depth":20,"instrumentId":"83140036-4e5c-4097-8ef3-fa65d036655b"},{"instrumentId":"ab972ae2-6421-4112-b1d4-487b057b64bd","depth":20},{"instrumentId":"5aa66920-1632-46db-b34f-7d9e725428e2","depth":20},{"depth":20,"instrumentId":"ac67756d-7e3a-4180-81e4-84f411301003"},{"instrumentId":"3905690d-70e5-4b74-b45c-f09e8cf8c824","depth":20},{"instrumentId":"87cdb903-00c5-4d4a-94af-73c2158a1e1b","depth":20},{"instrumentId":"ab205e93-0b74-4e85-872d-7f3670a56cce","depth":20},{"instrumentId":"22263a4b-8fde-4325-95ea-6137a940e3c3","depth":20},{"depth":20,"instrumentId":"bbb9331b-64de-4152-9d90-aabf1043b408"},{"instrumentId":"1fa3275c-9b13-4c22-89f0-51e2db3f11a4","depth":20},{"instrumentId":"0e2412d4-2b57-46e7-a8b8-408c9fec6bc9","depth":20},{"depth":20,"instrumentId":"b713f8a3-7ef8-4c93-bd6c-4f8ea4d6cbcf"},{"instrumentId":"e09b9823-5cbd-4c0e-8ae6-07ca94780140","depth":20},{"depth":20,"instrumentId":"6d81e2f8-a541-45f7-8dbf-949cbe8bb535"},{"depth":20,"instrumentId":"18fb3421-7637-48f1-b5b5-20a454e1af5b"},{"depth":20,"instrumentId":"29f68c60-14e7-44cc-bcb3-1c9b448b88eb"},{"instrumentId":"b8c52b10-60cf-4a1a-a461-c7153e0a0d25","depth":20},{"depth":20,"instrumentId":"d7697cc4-d107-473c-8cb1-e75aab73f6b0"},{"instrumentId":"5b57d10b-b93c-4629-9701-c08a863528df","depth":20},{"instrumentId":"165167f1-8063-458a-a495-b17555edd809","depth":20},{"depth":20,"instrumentId":"c36fc508-99b4-4063-b7e1-4a885c3b2fa3"},{"instrumentId":"3c072a03-3924-45c4-9d6b-8c92a0f0a2d8","depth":20},{"depth":20,"instrumentId":"3908e0cd-b394-4765-9b00-23ec465e58d3"},{"depth":20,"instrumentId":"2ce560fc-5317-47ae-867a-22810bfec724"},{"depth":20,"instrumentId":"c799669f-231c-477b-b3b1-85eb90832018"},{"depth":20,"instrumentId":"3911e312-4359-4a9d-98f5-422990cc44d0"},{"instrumentId":"976debde-4e2c-4796-b588-2339b70cb33a","depth":20},{"instrumentId":"538ba928-5de6-4f55-a3da-84fbce8a79f6","depth":20},{"depth":20,"instrumentId":"b993e814-9986-4434-ae88-b086066714a0"},{"instrumentId":"136739fb-dfcc-4312-af06-d6f657bac08f","depth":20},{"instrumentId":"9075b467-b306-4992-b127-6324826c6628","depth":20},{"instrumentId":"1e55eb61-6a28-4cee-a9f6-945deb6d1b4e","depth":20},{"instrumentId":"7cc2ea90-f3c8-46df-9cf4-0235a3626fa2","depth":20},{"depth":20,"instrumentId":"2ac30470-65e4-4ddb-8239-bcb5059a5d3a"},{"instrumentId":"e6787da1-8d96-4c06-8288-b57c3449ba58","depth":20},{"depth":20,"instrumentId":"414385e9-26a7-4a52-b7c0-80a684e3df22"},{"depth":20,"instrumentId":"1829a1df-8848-426e-865e-4968e98c21ab"},{"instrumentId":"a4e61935-2842-4dfb-a945-387608c140a7","depth":20},{"depth":20,"instrumentId":"abfde89d-fd82-49cd-9860-60bf1282156a"},{"instrumentId":"5cf6d141-80bd-4759-9ff5-0ba4d3ac6183","depth":20},{"instrumentId":"b5e26096-d013-48e4-b2a9-2f38b6090feb","depth":20},{"depth":20,"instrumentId":"0bea598e-e69c-4dd9-acfa-519592d785ee"},{"depth":20,"instrumentId":"42cc3328-5764-40b5-97bf-2e5566a6e306"},{"depth":20,"instrumentId":"3f96f2b9-6b3f-40fd-a5ec-8752f231f542"},{"instrumentId":"9b55690e-e15d-4df1-8336-fa47624ab4bf","depth":20},{"depth":20,"instrumentId":"0f40dd57-5235-4b8a-9453-f8fe728c4b30"},{"depth":20,"instrumentId":"d043c57c-26eb-40a7-941e-b6e7a0485d7d"},{"depth":20,"instrumentId":"e6b2463d-744e-489c-b07a-f22220f75ca9"},{"instrumentId":"598d9b07-3dff-4952-b0ea-9dfc8a21ddce","depth":20},{"instrumentId":"c11cc2c1-80a0-4fcd-bdfc-c4ca7d441d6b","depth":20},{"instrumentId":"e797d92b-d398-47a6-aca9-856e3106d78d","depth":20},{"instrumentId":"8c76c021-ee4f-4911-8c9f-63996b8277fc","depth":20},{"depth":20,"instrumentId":"6c97b684-ae84-435c-96fd-e20dc9197999"},{"instrumentId":"d27c7474-e84a-4372-9afa-9541cf3fae8f","depth":20},{"instrumentId":"ca3df003-d43b-4c61-850d-674e34f569a0","depth":20},{"instrumentId":"c4df9f9b-5436-409f-abb7-9f548c26ace1","depth":20},{"instrumentId":"56294564-5166-4656-8a9a-6827e339b584","depth":20},{"depth":20,"instrumentId":"481b0b21-0c38-4afa-9447-6d353a95f877"},{"instrumentId":"f8d89d4b-ccfd-4b19-be43-f2aaf58a9192","depth":20},{"instrumentId":"5369f34b-6e1f-4b23-80ee-1f28aa082a4e","depth":20},{"depth":20,"instrumentId":"17a1eacc-b4a5-4707-a7f7-197abe9e1453"},{"instrumentId":"3db3eee2-c63d-4b76-aa43-f52f0b39f795","depth":20},{"instrumentId":"ae75a6f5-af2c-4e6a-ae6f-cbde32b32995","depth":20},{"depth":20,"instrumentId":"a31eef09-e57b-42a0-9b45-22dd7f9b9671"},{"depth":20,"instrumentId":"2b3d91c8-99cc-4bf4-9f46-b53374a1badf"},{"depth":20,"instrumentId":"3ce5ff17-2f20-4732-88a9-d91ee31ddf98"}]}}