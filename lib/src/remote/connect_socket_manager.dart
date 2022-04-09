// import 'dart:convert';
// import 'dart:convert' as convert;
// import 'dart:io';
// import 'dart:math';
//
// import 'package:event_bus/event_bus.dart' as events;
// import 'package:flutter/cupertino.dart';
// import 'package:mqtt_client/customer/customer_mqtt_client.dart';
// import 'package:mqtt_client/mqtt_client.dart';
//
// String topic='/board/16881900';
//
// events.EventBus? socketEventBus = events.EventBus();
// class ConnectionManager with ChangeNotifier {
//   static const LOG = 'SocketManager:';
//   static ConnectionManager? _singleton;
//   CustomerMqttClient? client;
//   String? baseUrl;
//
//   bool? connectStatus;
//   RawDatagramSocket? udpSocket;
//   Utf8Codec? utf8codec = const convert.Utf8Codec();
//   static String? serverHost;
//   static int? serverPort = 1883;
//   static String? clientId;
//
//   factory ConnectionManager() {
//     return _singleton!;
//   }
//
//   // ignore: sort_constructors_first
//   ConnectionManager._internal();
//
//  void _initUdp() {
//     var addressesIListenFrom = InternetAddress.anyIPv4;
//     RawDatagramSocket.bind(addressesIListenFrom, 0)
//         .then((RawDatagramSocket udpSocket) {
//       this.udpSocket = udpSocket;
//       udpSocket.forEach((RawSocketEvent event) {
//         if (event == RawSocketEvent.read) {
//           Datagram? dg = udpSocket.receive();
//           _onUdpMessage(dg!.data.toList());
//         }
//       });
//     });
//   }
//
//  void  configure(String url) async {
//     serverHost = url;
//     login(url, "testuser", "passwd");
//   }
//
// void   _connectStatusChange(bool value) {
//     connectStatus = value;
//     if (!connectStatus!) {
//       _singleton = null;
//     }
//     notifyListeners();
//   }
//
//   void _initMqttClient(String socketUrl, String username) {
//     var ff = Random(1000000).nextInt(1000000);
//     client = CustomerMqttClient(socketUrl, username + ff.toString());
//
//     /// Set logging on if needed, defaults to off
//     client!.logging(on: false);
//
//     /// If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
//     client!.keepAlivePeriod = 5;
//
//     /// Add the unsolicited disconnection callback
//     client!.onDisconnected = onDisconnected;
//
//     /// Add the successful connection callback
//     client!.onConnected = onConnected;
//
//     /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
//     /// You can add these before connection or change them dynamically after connection if
//     /// you wish. There is also an onSubscribeFail callback for failed subscriptions, these
//     /// can fail either because you have tried to subscribe to an invalid topic or the broker
//     /// rejects the subscribe request.
//     client!.onSubscribed = onSubscribed;
//
//     /// Set a ping received callback if needed, called whenever a ping response(pong) is received
//     /// from the broker.
//     client!.pongCallback = pong;
//
//     client!.port = serverPort;
//
//     /// Create a connection message to use or use the default one. The default one sets the
//     /// client identifier, any supplied username/password and clean session,
//     /// an example of a specific one below.
//     final connMess = MqttConnectMessage()
//         .withClientIdentifier(username)
//         .withProtocolVersion(2)
//         .withWillTopic(
//             'willtopic') // If you set this you must set a will message
//         .withWillMessage('My Will message')
//         .startClean() // Non persistent session for testing
//         .withWillQos(MqttQos.atLeastOnce);
//     print('EXAMPLE::Mosquitto client connecting....');
//     client!.connectionMessage = connMess;
//   }
//
//   /// The subscribed callback
//   void onSubscribed(String topic) {
//     print('EXAMPLE::Subscription confirmed for topic $topic');
//   }
//
//   /// The unsolicited disconnect callback
//   void onDisconnected() {
//     _connectStatusChange(false);
//     print('EXAMPLE::OnDisconnected client callback - Client disconnection');
//     if (client!.connectionStatus!.disconnectionOrigin ==
//         MqttDisconnectionOrigin.solicited) {
//       print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
//     }
//   }
//
//   /// The successful connect callback
//   void onConnected() {
//     _connectStatusChange(true);
//     _bindUdpSession();
//     print(
//         'EXAMPLE::OnConnected client callback - Client connection was sucessful');
//   }
//
//   /// Pong callback
//   void pong() {
//     _bindUdpSession();
//     print('EXAMPLE::Ping response client callback invoked');
//   }
//
//   Future<bool> login(String socketUrl, String username, String password) async {
//     try {
//       int rand = new Random().nextInt(1000000);
//       clientId = username + rand.toRadixString(2);
//       _initMqttClient(socketUrl, clientId!);
//       await client!.connect(username, password);
//       client!.customer!.listen((MqttCustomerMessage messages) {
//         _onMessage(messages);
//       });
//
//       client!.subscribe("/test", MqttQos.atLeastOnce);
//       client!.subscribe(topic, MqttQos.atLeastOnce);
//       client!.published!.listen((MqttPublishMessage mqttPublishMessage) {
//         _onPublishMessage(mqttPublishMessage);
//       });
//     } on NoConnectionException catch (e) {
//       // Raised by the client when connection fails.
//       print('EXAMPLE::client exception - $e');
//       // client.disconnect();
//     } on SocketException catch (e) {
//       // Raised by the socket layer
//       print('EXAMPLE::socket exception - $e');
//       // client.disconnect();
//     }
//     _connectStatusChange(
//         client!.connectionStatus!.state == MqttConnectionState.connected);
//
//     /// Check we are connected
//     return client!.connectionStatus!.state == MqttConnectionState.connected;
//   }
//
//   void _bindUdpSession() {
//     List<int> dataToSend = [];
//     dataToSend.add(1);
//     dataToSend.addAll(utf8codec!.encode(clientId!));
//     udpSocket!.send(dataToSend, new InternetAddress(serverHost!), serverPort!);
//   }
//
//     void  _onMessage(MqttCustomerMessage message) {
//     print(utf8.decoder.convert(message.payload.message!.toList()));
//     String? messageString =
//         utf8.decoder.convert(message.payload.message!.toList());
//     // receiverMessage = ChatMessage.fromJson(messageString);
//     // receiverMessage!.direction = 0;
//     //TODO userJoinMessage 用户加入通知
//     // Map? map =;
//     socketEventBus!.streamController.add( convert.jsonDecode(messageString));
//     // notifyListeners();
//   }
//
//   void _onPublishMessage(MqttPublishMessage mqttPublishMessage) {
//     socketEventBus!.streamController.add(mqttPublishMessage);
//   }
//
//   void _onUdpMessage(List<int> message) {
//     try{
//       int messageType = message[0];
//       message.removeAt(0);
//        String? msgString = utf8.decoder.convert(message);
//       // print(msgString);
//       socketEventBus!.streamController.add(json.decode(msgString));
//     }catch (e){
//       print(e);
//     }
//   }
//
//   Future<int?> sendMessage(Map data) async {
//     final builder = MqttClientPayloadBuilder();
//     builder.addUTF8String(convert.jsonEncode(data));
//     var message = MqttCustomerMessage(10, builder.payload);
//     // var header =  MqttHeader().asType(MqttMessageType.reserved1);
//     // header.qos = MqttQos.exactlyOnce;
//     // message.header =  header;
//     return client!.sendCustomerMessage(message);
//   }
//
//   void sendUdpMessage(Map message) {
//     List<int> dataToSend = [];
//     dataToSend.add(2);
//     dataToSend.addAll(utf8codec!.encode(convert.jsonEncode(message)));
//     udpSocket!.send(dataToSend, new InternetAddress(serverHost!), serverPort!);
//   }
//
//   void publish(String topic, Map dataMap) {
//     final builder = MqttClientPayloadBuilder();
//     builder.addUTF8String(convert.jsonEncode(dataMap));
//     client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!,
//         retain: false);
//   }
//
//   static ConnectionManager getInstance() {
//     if (null == _singleton) {
//       _singleton = ConnectionManager._internal();
//
//       // 120.77.220.166
//       _singleton!.configure("120.77.220.166");
//
//       _singleton!._initUdp();
//     }
//     return _singleton!;
//   }
// }
